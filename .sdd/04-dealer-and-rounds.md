# 04 — Dealer and Rounds

Source: `src/lib/dealer.ts`, `src/lib/community-cards.ts`

The Dealer runs **one hand**: from ante/blinds/deal to showdown payouts.

## State

- `_players: [Player?]` — the current street's roster (folded players become `nil` **in place**). Preflop this is the full hand roster; after each street it's replaced by the surviving players (`bettingRound.players()`).
- `_bettingRound: BettingRound?`, `_roundOfBetting: PREFLOP|FLOP|TURN|RIVER`, `_bettingRoundsCompleted: Bool`, `_handInProgress: Bool`.
- `_holeCards: [HoleCards?]`, `_communityCards` (shared object injected by Table), `_potManager`, `_winners`.

## Starting a hand (`startHand`, dealer.ts:175-188)

1. **Ante** (if configured): each player pays `min(ante, total)`, summed straight into pot #0 (`collectAnte`).
2. **Blinds** (`postBlinds`): with ≥3 players the small blind is the seat after the button; **heads-up the button posts the small blind**. SB pays `min(smallBlind, total)`; the seat after pays `min(bigBlind, total)`.
3. **First to act** = seat after the big blind (wrap).
4. **Hole cards**: two draws per player from the deck.
5. Open a `BettingRound` with `minRaise = big`, `biggestBet = big` (so the BB's posted bet counts) — **only if more than one player still has chips**; specifically more than one player with `stack != 0` or being the big blind seat. If the BB is all-in from the blind, everyone else may still act; if only one player remains able to act, no betting round opens and the hand skips to river.
6. `handInProgress = true`.

## Legal actions (`legalActions`, dealer.ts:126-159)

The BettingRound computes `{canRaise, chipRange}` treating things as match/raise. The Dealer refines to poker terminology:

- If `biggestBet - player.betSize == 0` (nothing to match):
  - `CHECK` is legal.
  - `canRaise` → raise if the player already has a bet on the street (they're the big blind — raising their own blind), else `BET`.
  - Edge case: a BB who is all-in after the blind can check but **not** bet/raise (canRaise is false because `totalChips > biggestBet` fails).
- Else (a bet must be matched):
  - `CALL` is legal.
  - `canRaise` → `RAISE`.
- `FOLD` is always legal.

`ActionRange.contains(action, bet)` validates an incoming action: any non-aggressive action passes; `BET`/`RAISE` must fall in the chip range.

## Actions (`actionTaken`, dealer.ts:190-208)

Maps the public flags to BettingRound actions:

| Public action | Effect |
|---------------|--------|
| `CHECK` / `CALL` | `BettingRound.MATCH` — player bets `min(biggestBet, total)` |
| `BET` / `RAISE` | `BettingRound.RAISE` with bet size |
| `FOLD` | folded bet recorded into PotManager (`betFolded(betSize)`), chips deducted from the player (`takeFromBet`), player set `nil` in roster, `BettingRound.LEAVE` |

## End of street (`endBettingRound`, dealer.ts:210-237)

1. `PotManager.collectBetsForm(players)` → all committed chips become pots (see 06).
2. **If ≤1 active player left** (everyone else folded): jump to `RIVER`, deal the remaining community cards **only if there's more than one eligible player in a single pot** (no need to deal for a hand nobody will see), mark `bettingRoundsCompleted`, hand awaits `showdown`.
3. Else advance `PREFLOP → FLOP → TURN → RIVER` (the enum value doubles as the dealt-card count: `FLOP=3, TURN=4, RIVER=5`):
   - Roster = surviving players; new `BettingRound` starting with the first occupied seat **after the button**, `minRaise = bigBlind` (raise amount resets to the big blind each street), `biggestBet = 0`.
   - Deal community cards up to the new round's count (`dealCommunityCards`, dealer.ts:356-363).

## Showdown (`showdown`, dealer.ts:245-307)

Preconditions: round == RIVER, no betting round in progress, betting rounds completed.

1. `handInProgress = false`.
2. **Single eligible player shortcut:** if there is exactly one pot with one eligible player, that player simply gets the pot (`addToStack(pot.size())`). No reveals, no evaluation. (`winners()` returns empty for this case — the caller is expected to have read `pots()`.)
3. Otherwise, per pot:
   - Build `(seat, Hand)` for every eligible player via `Hand.create(holeCards, communityCards)`.
   - Sort descending by `Hand.compare` (see 07).
   - Split: ties continue while `Hand.compare == 0` (adjacent-run search `findIndexAdjacent`); `n` winners.
   - `payout = (potSize - potSize % n) / n` paid to each winner (integer math; odd chips stay aside).
   - **Odd chips** (remainder) are given one chip at a time to winners, walking clockwise from the button (`nextOrWrap` over the winners only).
   - Record `winners` entries as `(seat, hand, holeCards)`.

## Community cards

`RoundOfBetting` doubles as count of cards that should be dealt: `PREFLOP=0, FLOP=3, TURN=4, RIVER=5`. `next(round)` = FLOP from PREFLOP, else `round + 1`. Cards are drawn from the deck in order and appended; flop is dealt as a single batch of 3.

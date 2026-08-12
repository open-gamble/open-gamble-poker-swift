# 04 — Dealer and rounds

Source: `OpenGamblePoker/Dealer.swift`

The Dealer owns a single hand: starting it (ante, blinds, deal), legal-action derivation, action mapping, street transitions, and showdown payouts. It is constructed fresh by `Table` on each `startHand`.

## State

- `_players: SeatArray` — current street roster (the live hand players; `bettingRoundPlayers()` exposes it).
- `_bettingRound: BettingRound?`, `_potManager: PotManager`, `_holeCards: [HoleCards?]`, `_communityCards: CommunityCards` (own copy), `_roundOfBetting: RoundOfBetting`, `_handInProgress`, `_bettingRoundsCompleted`, `_winners: [[(SeatIndex, Hand, HoleCards)]]`.

## Actions

`Dealer.Action` is an `OptionSet`: `fold=1<<0, check=1<<1, call=1<<2, bet=1<<3, raise=1<<4`. `Dealer.ActionRange` carries the allowed flags plus a `chipRange` (from `BettingRound.legalActions()`); `contains(_:bet:)` validates aggressive actions against the chip range.

## Hand start (`startHand`, Dealer.swift:151)

1. Preconditions: no hand in progress.
2. Reset `_bettingRoundsCompleted`, `_roundOfBetting = .preflop`, `_winners = []`.
3. `collectAnte()` — each player pays `min(ante, totalChips)`, summed into pot 0.
4. `postBlinds()` — with 3+ players the button posts the small blind and the next seat the big blind; **heads-up (2 players) the button is the SB**. Each blind is `min(blind, totalChips)`. Returns the big-blind seat.
5. `dealHoleCards()` — two cards to each seated player (draws from the end of the deck).
6. The first player to act is the seat after the big blind. If more than one player can act (`stack != 0`, plus the big blind seat), open a `BettingRound(players:, firstToAct:, minRaise: big, biggestBet: big)`; otherwise no round opens.
7. `_handInProgress = true`.

## Legal actions (`legalActions`, Dealer.swift:109)

From `BettingRound.legalActions()` and the player to act's `betSize`:

- If `biggestBet - betSize == 0`: add `check`; add `bet` (if `betSize == 0`) or `raise` when `canRaise`.
- Else: add `call`; add `raise` when `canRaise`.

## Action mapping (`actionTaken`, Dealer.swift:170)

`Dealer.actionTaken(_:bet:)` preconditions: round in progress, and the action legal per `legalActions().contains(action, bet:)`. Maps facade flags to `BettingRound.Action`:

- `check`/`call` → `.match` (player bets `min(biggestBet, totalChips)`).
- `bet`/`raise` → `.raise` with the given bet (validated).
- `fold` → hand the folded bet to `PotManager.betFolded(betSize)`, clear the player's bet (`takeFromBet`), remove the player from the roster, and notify the round with `.leave`.
- After each action, `syncPlayersFromBettingRound()` copies `_bettingRound`'s player state (bets/stacks) back into `_players` for seats still present (value-semantics compensation for `BettingRound` holding its own copy).

## Street transitions (`endBettingRound`, Dealer.swift:202)

Preconditions: rounds not completed, round not in progress.

1. `_potManager.collectBetsFrom(&_players)` — collects current bets into pots (06).
2. If `numActivePlayers <= 1` (all folded / all-in): move to river; deal remaining community cards **unless** a single eligible player will take the pot uncontested; mark rounds completed.
3. Else if the street isn't river: advance `_roundOfBetting`, rebuild `_players` from the betting round's `activePlayers`, open a new `BettingRound` (first to act = after the button), deal community cards.
4. Else (river): mark rounds completed.

## Showdown and payouts (`showdown`, Dealer.swift:233)

Preconditions: round is river, not in progress, and rounds completed.

- **Single eligible player** (one pot, one eligible player): that player wins the pot directly; `winners()` stays empty. Return.
- Otherwise, for each pot:
  - Build `(seat, Hand)` for each eligible player from hole cards + community cards (`Hand.create`).
  - Sort by `Hand.compare` (ascending = best last), split the pot among the tied best hands, distributing the odd chips (remainder) **one chip at a time clockwise from the button** among the winners.
  - Record the winners with their hole cards in `_winners`.
- `_handInProgress = false`.

`handInProgress()`, `bettingRoundsCompleted()`, `roundOfBetting()`, `numActivePlayers()`, `biggestBet()`, `bettingRoundInProgress()`, `isContested()`, `pots()`, `button()`, `holeCards()`, `winners()` are the queries (mostly precondition-guarded).

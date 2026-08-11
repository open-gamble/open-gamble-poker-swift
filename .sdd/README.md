# Poker Engine — Design Docs (`.sdd`)

Language-agnostic design documents of the poker-ts engine, written so the same logic can be rebuilt in Swift. Each doc describes **behavior, invariants, and algorithms** — not TypeScript syntax. Cross-reference `src/lib/*.ts` (file:line cited in each doc) when a detail matters.

## Reading order

| Doc | Scope |
|-----|-------|
| [01-architecture.md](01-architecture.md) | Component layers, ownership, one-hand call flow |
| [02-core-types-and-deck.md](02-core-types-and-deck.md) | Card/rank/suit, Deck (draw contract), Player (chip accounting), ChipRange |
| [03-table-lifecycle.md](03-table-lifecycle.md) | Table layer: seats, button rotation, staged players, automatic actions, stand-up rules |
| [04-dealer-and-rounds.md](04-dealer-and-rounds.md) | Dealer: hand start, legal actions, action mapping, street transitions, showdown payouts |
| [05-round-state-machine.md](05-round-state-machine.md) | Round + BettingRound: turn rotation, contest state, raise validation |
| [06-pot-construction.md](06-pot-construction.md) | Pot + PotManager: side-pot construction, folded-bet accounting |
| [07-hand-evaluation.md](07-hand-evaluation.md) | 7-card → best 5 evaluation, strength encoding, comparison |

## Porting notes (Swift)

- **Money is integer chips only** (cents). No floats anywhere in the engine.
- Enums that are **numeric or bitmasks are load-bearing**:
  - `RoundOfBetting`: `PREFLOP=0, FLOP=3, TURN=4, RIVER=5` — the values encode *how many community cards have been dealt*, so arithmetic like `round - communityCards.count` is intentional.
  - `HandRanking`: `HIGH_CARD=0 … ROYAL_FLUSH=9` — ordering is used for comparison; **royal flush is a straight flush with ace high, strength 0** (not a separate superior category).
  - Action flags are single-bit masks (`FOLD=1<<0, CHECK=1<<1, …`); `bitCount(x)==1` is the "valid single action" predicate.
- A player is a mutable chip-account object with two quantities: `total` (chips owned) and `betSize` (chips committed to the current street). `stack = total - betSize`. **Bet chips remain in `total` until collected into a pot.**
- Arrays indexed by seat are the primary data structures (`SeatArray = [Player?]`, `_activePlayers: [Bool]`).
- All public entry points assert preconditions; assertions define the call contract (e.g. "betting round must be in progress"). Reproduce them as `precondition`/throws in Swift.
- The engine never reveals or communicates — it's a pure state machine driven by `actionTaken(action, bet)` calls.
- **Verification target**: the TS test suite in `test/` encodes expected behaviors for every edge case (blind heads-up rules, side pots, kicker handling, odd-chip distribution). Port the logic, then port the tests.

## Source layout (TS)

```
src/facade/poker.ts   public API (string enums, camelCase) — wrapper only, no logic
src/lib/table.ts      Table   — table state, automatic actions, orchestration
src/lib/dealer.ts     Dealer  — one hand's lifecycle + showdown payouts
src/lib/betting-round.ts, round.ts — per-street rotation
src/lib/pot-manager.ts, pot.ts     — side pots
src/lib/hand.ts, card.ts, deck.ts, community-cards.ts, chip-range.ts, player.ts
src/util/array.ts, bit.ts          — shared helpers
```

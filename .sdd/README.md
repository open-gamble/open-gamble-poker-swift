# OpenGamblePoker — Design Docs (`.sdd`)

Design documents for the Swift implementation of the Texas Hold'em engine, **`OpenGamblePoker`**. Each doc describes **behavior, invariants, and algorithms** — not syntax. Cross-reference the Swift sources (`OpenGamblePoker/*.swift`) when a detail matters.

## Reading order

| Doc | Scope |
|-----|-------|
| [01-architecture.md](01-architecture.md) | Component layers, ownership, one-hand call flow |
| [02-core-types-and-deck.md](02-core-types-and-deck.md) | Card/rank/suit, Deck (draw contract), Player (chip accounting), ChipRange, type aliases |
| [03-table-lifecycle.md](03-table-lifecycle.md) | Table layer: seats, button rotation, staged players, automatic actions, stand-up rules |
| [04-dealer-and-rounds.md](04-dealer-and-rounds.md) | Dealer: hand start, legal actions, action mapping, street transitions, showdown payouts |
| [05-round-state-machine.md](05-round-state-machine.md) | Round + BettingRound: turn rotation, contest state, raise validation |
| [06-pot-construction.md](06-pot-construction.md) | Pot + PotManager: side-pot construction, folded-bet accounting |
| [07-hand-evaluation.md](07-hand-evaluation.md) | 7-card → best 5 evaluation, strength encoding, comparison |

## Design invariants

- **Money is integer chips only** (cents). No floats anywhere in the engine. `Chips = Int`.
- Enums that are **numeric or bitmasks are load-bearing**:
  - `RoundOfBetting`: `preflop=0, flop=3, turn=4, river=5` — the values encode *how many community cards have been dealt*, so arithmetic like `round.rawValue - communityCards.count` is intentional.
  - `HandRanking`: `highCard=0 … royalFlush=9` — ordering is used for comparison; **royal flush is a straight flush with ace high, strength 0** (not a separate superior category).
  - Action flags are `OptionSet` single-bit masks (`Dealer.Action`, `Table.AutomaticAction`, `Round.Action`); `bitCount(x) == 1` is the "valid single action" predicate.
- A player is a mutable chip-account struct with two quantities: `total` (chips owned) and `betSize` (chips committed to the current street). `stack = total - betSize`. **Bet chips remain in `total` until collected into a pot.**
- Arrays indexed by seat are the primary data structures (`SeatArray = [Player?]`, `activePlayers: [Bool]`).
- All public entry points `precondition`-guard their contracts (e.g. "betting round must be in progress"). These assertions **are** the call contract — keep them.
- The engine never reveals or communicates — it's a pure, synchronous, single-threaded state machine driven by `actionTaken(_:bet:)` calls. No actors.
- Public value types are `Sendable`. `Deck` is a `final class` (`@unchecked Sendable`) taking an injectable shuffle RNG so tests can make the deal deterministic.
- **Verification target**: the Swift test suite in `OpenGamblePokerTests/` encodes expected behaviors for every edge case (blind heads-up rules, side pots, kicker handling, odd-chip distribution, automatic-action amendment).

## Source layout

```
OpenGamblePoker/Poker.swift     public API facade (string enums, camelCase) — wrapper only, no logic
OpenGamblePoker/Table.swift     Table        — table state, automatic actions, orchestration
OpenGamblePoker/Dealer.swift    Dealer       — one hand's lifecycle + showdown payouts
OpenGamblePoker/BettingRound.swift, Round.swift — per-street rotation
OpenGamblePoker/PotManager.swift, Pot.swift     — side pots
OpenGamblePoker/Hand.swift, Card.swift, Deck.swift, CommunityCards.swift, ChipRange.swift, Player.swift
OpenGamblePoker/Types.swift     type aliases (Chips, SeatIndex, SeatArray, HoleCards, Blinds, ForcedBets)
OpenGamblePoker/ArrayUtils.swift, BitUtils.swift — shared helpers
OpenGamblePokerTests/*          swift-testing suites mirroring the behaviors above
```

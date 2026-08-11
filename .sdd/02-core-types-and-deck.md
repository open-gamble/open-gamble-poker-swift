# 02 — Core Types and Deck

Source: `src/lib/card.ts`, `src/lib/deck.ts`, `src/lib/player.ts`, `src/lib/chip-range.ts`, `src/types/*.d.ts`

## Card

- **Rank** is an enum `_2(0) _3 _4 _5 _6 _7 _8 _9 T J Q K A(12)`. Numeric rank order == poker rank order; `A` is the highest value. The `_` prefix in the TS identifier is only to make `2` a legal identifier — the Swift port can use `2…A` directly. (The facade strips the underscore when exposing cards.)
- **Suit** is an enum `CLUBS(0) DIAMONDS HEARTS SPADES`. Suit is irrelevant for poker ranking; it only matters for flush/straight-flush detection.
- Cards are **structs/plain data** — no logic. The engine identifies cards by identity (same object through the hand), not by a unique id.

## Deck

- Fixed 52 cards, one per (rank, suit) pair, created in suit-major, rank-minor order.
- **State: a top-index.** `draw()` returns the card at the top and decrements the count — i.e. **cards are drawn from the end of the array**. The array contents never change between shuffles; only the count does.
- `fillAndShuffle()` resets the count to 52 and shuffles **in place** (Fisher-Yates, crypto-random). Called once per hand by the Table.
- **Determinism hook (important for testing):** the shuffle algorithm is injected at construction (`Deck(shuffleAlgorithm)`). Tests inject a no-op and pre-arrange the array so that `draw()` in game order yields exact hands. A Swift port should keep this seam (protocol + default implementation) or port the test fixtures differently.
  - Test fixture contract: to make card `X` the n-th card drawn, write it at `array[51 - n]`. See `test/helper/card.ts` for ready-made deals.

## Player (chip accounting)

Two mutable integer quantities:

- `total` — all chips the player owns.
- `betSize` — chips committed to the current street (still owned; not yet in a pot).
- Derived: `stack = total - betSize` (chips available to act with).

Operations:

| Operation | Effect |
|-----------|--------|
| `bet(amount)` | `betSize = amount` (precondition: `amount ≤ total`, `amount ≥ previous betSize`) |
| `takeFromBet(amount)` | `total -= amount; betSize -= amount` — moves chips from the current bet into a pot (precondition: `amount ≤ betSize`) |
| `addToStack(amount)` | `total += amount` — winnings |
| `takeFromStack(amount)` | `total -= amount` — ante |
| copy constructor | duplicates `total` and `betSize` (used to clone table players into hand players) |

**Invariant: `betSize ≤ total` always.** All-in is expressed naturally: after `bet(total)`, `stack == 0`.

## ChipRange

Plain min/max pair with `contains(x) = min ≤ x ≤ max`. Used to express legal bet sizes for the player to act. A missing range (check-only context) means "no bet allowed".

## Type aliases (conceptual — Swift equivalents)

- `Chips = Int` (integer only; UI converts to decimals).
- `SeatIndex = Int` — index into any seat-indexed array.
- `SeatArray = [Player?]` — length `numSeats` (default 9, max 23), `nil` = empty seat / folded player depending on context.
- `HoleCards = (Card, Card)`.
- `ForcedBets = { ante?: Chips, blinds: { small: Chips, big: Chips } }`.

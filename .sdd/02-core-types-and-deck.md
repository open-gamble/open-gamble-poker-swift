# 02 — Core types and deck

Source: `OpenGamblePoker/Card.swift`, `Deck.swift`, `Player.swift`, `ChipRange.swift`, `CommunityCards.swift`, `Types.swift`

## Card, rank, suit (`Card.swift`)

- `CardRank: Int` — `two…nine, ten, jack, queen, king, ace`. Raw values `0…12` (rank 2 is 0). Numeric order is used for comparisons and strength encoding.
- `CardSuit: Int` — `clubs, diamonds, hearts, spades` (raw `0…3`).
- `Card: Sendable, Equatable` — value struct holding `rank` + `suit`. `Card.compare` orders by suit first, then rank (descending).

The facade (`Poker.Card.Rank`) maps these to string cards `"2"…"9","T","J","Q","K","A"`; `Poker.Card.Suit` mirrors the suit names.

## Deck (`Deck.swift`)

- A `final class` (`@unchecked Sendable`) over an internal `cards: [Card]` (52, ordered by suit then rank) plus a `size` counter.
- **Draws from the END**: `draw()` returns `cards[size - 1]` and decrements `size`. The `cards` array is never shortened — `count` always reports 52.
- `fillAndShuffle()` resets `size` to 52 and re-runs the shuffle.
- **Injectable shuffle RNG**: `init(shuffleAlgorithm:)` defaults to `Deck.defaultShuffle` (GameplayKit `GKShuffledDistribution`). Tests inject a no-op shuffle and **pre-arrange cards at `array[51 - index]`** so `draw()` returns them in the intended order. Do not break this contract.
- Preconditions: `Dealer.init` requires a whole deck (`count == 52`) and no community cards dealt.

## Player (`Player.swift`)

Value struct, two chip quantities:

- `total` — chips owned (`private`).
- `betSize` — chips committed to the current street (`private(set)`).
- `stack = total - betSize`. `totalChips = total`.

Operations:
- `addToStack` / `takeFromStack` adjust `total`.
- `bet(_ amount)` — sets `betSize`; preconditions `amount <= total` and `amount >= betSize`.
- `takeFromBet(_ amount)` — subtracts from both `total` and `betSize` (used when folded bets move to the pot).

**Bet chips remain in `total` until collected into a pot.** A player who bets 100 has `total == 100 + stack`; the 100 only leaves `total` via `takeFromBet` during pot collection.

## ChipRange (`ChipRange.swift`)

`struct ChipRange { min: Int, max: Int }`. `contains(_ amount)` = `min <= amount && amount <= max`. Used for raise/bet validation and exposed through the facade's `LegalActions`.

## CommunityCards (`CommunityCards.swift`)

Value struct wrapping `cards: [Card]`. `deal(_:)` appends (precondition: cannot deal past 5). Also declares `RoundOfBetting: Int` (`preflop=0, flop=3, turn=4, river=5`) and `next(_:)` (`preflop→flop→turn→river`; `river` is terminal).

## Type aliases (`Types.swift`)

```swift
Chips = Int
SeatIndex = Int
SeatArray = [Player?]
HoleCards = (Card, Card)
Blinds = (small: Chips, big: Chips)
ForcedBets = (ante: Chips?, blinds: Blinds)
```

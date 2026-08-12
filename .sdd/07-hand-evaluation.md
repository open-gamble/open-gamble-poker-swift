# 07 — Hand evaluation

Source: `OpenGamblePoker/Hand.swift`

Evaluates 7 cards (2 hole + 5 community) down to the best 5-card hand, encodes its strength as a single `Int`, and compares hands.

## Types

- `HandRanking: Int` — `highCard=0, pair, twoPair, threeOfAKind, straight, flush, fullHouse, fourOfAKind, straightFlush, royalFlush`. **Numeric order is load-bearing**; comparison first compares these raw values.
- `Hand` — value struct `{ ranking: HandRanking, strength: Int, cards: [Card] }` (exactly 5 `cards`). `Hand.compare` compares `ranking.rawValue` then `strength` (higher is better).

## Entry point

`Hand.create(holeCards:communityCards:)` requires 5 community cards, builds the 7-card set, and calls `Hand.of`. `Hand.of` returns the better of `highLowHandEval` and `straightFlushEval` via `findMax(…, Hand.compare)`.

## Strength encoding (`getStrength`, Hand.swift:61)

A base-13 number over the 5 ranks, descending: `sum += 28561 * rank0 + 2197 * rank1 + 169 * rank2 + 13 * rank3 + rank4` (multiplier divides by 13 each step). Equal ranks (e.g. a pair) are collapsed by `nextRank` (count of the leading equal ranks) so the pair is compared before kickers. Higher sum = better hand within a ranking.

## High/low evaluation (`highLowHandEval`, Hand.swift:127)

1. Count rank occurrences; sort so that more frequent ranks come first, ties broken by higher rank.
2. Classify by the count of the top rank group:
   - **4** → `fourOfAKind`; top 4 + best kicker.
   - **3** → if the next group (of the remaining 4) is a pair → `fullHouse`, else `threeOfAKind`.
   - **2** → if the next group (of the remaining 5) is a pair → `twoPair` (both pairs + best kicker), else `pair`.
   - else → `highCard`.
3. Take the top 5 cards; encode strength.

## Straight / flush evaluation (`straightFlushEval`, Hand.swift:168)

1. **Flush**: `getSuitedCards` finds a run of ≥5 same-suit cards (sorted by rank). If a 5+ suited straight exists (`getStraightCards`), it's a `straightFlush` (or `royalFlush` with strength 0 when the wheel is ace-high). Otherwise a `flush` using the top 5 suited cards.
2. **Straight**: dedupe ranks (keeping one card per rank), sort descending, and run `getStraightCards`. The wheel (A-2-3-4-5) is handled by rotating when the run is 4-wide on a five, with an ace at the bottom. Returns `nil` when there is no straight.

## Comparison

`Hand.compare(h1, h2)` returns a sign: `ranking` first, then `strength`. `findMax`/sorting use it so a higher-ranking or stronger hand wins; ties within a pot are broken only by the odd-chip distribution in the Dealer (04).

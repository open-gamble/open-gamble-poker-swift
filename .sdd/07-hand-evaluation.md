# 07 — Hand Evaluation

Source: `src/lib/hand.ts`, `src/util/array.ts`

Evaluates a 7-card hand (2 hole + 5 community) into the best 5-card poker hand: `Hand { ranking, strength, cards(5) }`.

## Entry points

- `Hand.create(holeCards, communityCards)` — requires all 5 community cards dealt.
- `Hand.of(7 cards)` — evaluates once via `_highLowHandEval`, once via `_straightFlushEval`, and **keeps the better of the two** (`findMax` by `compare`). Straight-flush is a separate detection path; the generic path can also produce a flush or straight.

## Comparison (`compare`, hand.ts:58-65)

```
if h1.ranking != h2.ranking:  return h2.ranking - h1.ranking   # higher enum value wins
else:                          return h2.strength - h1.strength # higher strength wins
```

`HandRanking` is `HIGH_CARD=0, PAIR=1, TWO_PAIR=2, THREE_OF_A_KIND=3, STRAIGHT=4, FLUSH=5, FULL_HOUSE=6, FOUR_OF_A_KIND=7, STRAIGHT_FLUSH=8, ROYAL_FLUSH=9`.

## Strength encoding (`getStrength`, hand.ts:77-93)

The 5 chosen cards are rank-sorted **descending, grouped by rank** (as produced by the sort below). Strength = positional base-13 number:

```
multiplier = 13^4
for each rank group {rank, count}:
    sum += multiplier * rank
    multiplier /= 13 per group
```

With at most 5 groups this encodes the 5 cards' ranks (kickers and pairs in order) as a single comparable integer. **Only ranks matter — suits never affect strength** (except via the flush/straight-flush detection path).

## Grouped descending sort (shared trick)

`_highLowHandEval` sorts the 7 cards by **rank frequency descending, ties broken by rank descending**:

```
sort key = (occurrences[rank], rank) descending
```

This places quads first, then trips/pairs, then singles by rank — so `nextRank` (first rank + its run count) immediately identifies the hand shape.

## `_highLowHandEval` (hand.ts:147-199)

1. Count occurrences per rank; sort grouped-descending as above.
2. `count = nextRank(cards).count` (cards[0]'s run):
   - `4` → **FOUR_OF_A_KIND**: reorder to `[quads..., kickers sorted desc]`; ranking 7.
   - `3` → check `nextRank(cards[-4..])` (the last 4 cards): pair among them → **FULL_HOUSE** (6); else **THREE_OF_A_KIND** (3).
   - `2` → check `nextRank(cards[-5..])`: pair → **TWO_PAIR** (2) with best-5 selection `[pair1, pair2, bestKicker]` (hand.ts:184-188; this exact kicker selection was a past bug fix); else **PAIR** (1).
   - `1` → **HIGH_CARD** (0).
3. Best 5 = first 5 cards; strength = `getStrength`.

## `_straightFlushEval` (hand.ts:201-243)

1. **Flush detection** (`getSuitedCards`): sort by `Card.compare` (suit desc, then rank desc) and scan consecutive runs of equal suit; if any run ≥ 5, return all cards of that run (sorted rank-desc).
2. If suited run exists: check for straight within it (`getStraightCards`). Found → **STRAIGHT_FLUSH** (8), strength = high card rank; if the high card is the Ace → **ROYAL_FLUSH** (9), strength = **0** (it's still a straight flush — the enum value alone outranks everything). Not a straight → **FLUSH** (5) with best-5 strength.
3. No flush: sort rank-desc, `unique` consecutive ranks (drops duplicate ranks, keeping one card per rank), and if ≥5 unique ranks remain, search for a straight → **STRAIGHT** (4), strength = high card rank. Otherwise null (generic path may still produce the pair-based hands).

### Straight detection (`getStraightCards`, hand.ts:121-145)

Input: rank-descending cards with unique ranks (≥5). Scan for runs of consecutive ranks (`rank[i] == rank[i+1] + 1`):

- Run ≥ 5 → return the first 5 cards of the run.
- Run == 4 **and** first card is `5` (index 0 is the Ace, since A is highest and sits at the front) → **wheel** (A-2-3-4-5): rotate the array so the 5-led run moves to the front, return first 5. (This is why `getStraightCards` mutates its input.)
- Fewer than 4 cards remain below the run → no straight possible, return nil.
- Else continue scanning from the run's end.

## Payout integration (dealer.ts:262-306)

- Eligible players per pot are evaluated and sorted descending by `compare`; ties split the pot.
- `payout = (pot - pot % n) / n` per winner; the remainder goes **one chip per winner**, walking clockwise from the button over winners only (`nextOrWrap`).
- A pot with a single eligible player is paid out without evaluation (see 04).

## Known subtleties (do not "fix")

- **Royal flush is not its own family** — it's a straight flush with `strength = 0`; its ranking number makes it unbeatable.
- Two-pair best-5 must include the highest kicker (regression: `8032f7a`).
- `getStraightCards` mutates its input (rotates for the wheel) — the caller passes a fresh copy.
- `findMax` uses `Array.sort` with the compare function, so the first element after sort is the max under that comparator.

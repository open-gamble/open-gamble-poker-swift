# 06 — Pot Construction

Source: `src/lib/pot-manager.ts`, `src/lib/pot.ts`

Pots are built once per street end (`Dealer.endBettingRound → PotManager.collectBetsForm(players)`). Until then, all committed chips sit in players' `betSize`.

## Pot

- `size: Int`, `eligiblePlayers: [SeatIndex]`.
- `add(amount)` — grow the pot (used for ante, folded bets, and collection).
- `collectBetsFrom(players) → minBet` — one pass that:
  - If **no player has a bet** (`betSize != 0`): eligible players = every non-nil player (folded players are already nil in the roster, so they're excluded), returns 0.
  - Else: find the **smallest non-zero bet** among players; take `minBet` from every better (`player.takeFromBet(minBet)` — chips leave `betSize` and become pot chips), record each better as eligible; return `minBet`.

## PotManager — side-pot construction loop

```
loop:
    minBet = lastPot.collectBetsFrom(players)
    # Folded chips are credited to the pot up to what its eligible players can cover
    eligibleCount = lastPot.eligiblePlayers().count
    foldedToPot = min(aggregateFoldedBets, eligibleCount * minBet)
    lastPot.add(foldedToPot)
    aggregateFoldedBets -= foldedToPot

    if any player still has a non-zero bet:
        push new Pot and continue      # everyone who bet ≥ current level moves up
    elif aggregateFoldedBets != 0:
        lastPot.add(aggregateFoldedBets); aggregateFoldedBets = 0
    break
```

### Why the folded-chips formula works

Folded chips are not tied to a seat, so they're distributed proportionally to pot construction. Rule: **a player can win at most `x * n` chips from a pot**, where `x` is what they contributed and `n` is the number of eligible players. When a level of `minBet` per eligible player is consumed, the folded chips that can be matched at this level are `eligibleCount * minBet` (each eligible player "covered" that much of the folded money). Remaining folded chips keep flowing to higher pots. If the loop ends with leftovers (no more bets to structure), they go into the last pot.

- **Folded bets are recorded during the street**: `Dealer.actionTaken(FOLD)` → `potManager.betFolded(player.betSize())` then `player.takeFromBet(betSize)` (chips leave the player but are not yet in a pot).
- **Ante** goes directly to pot #0 (`potManager.pots()[0].add(total)`).

### Example (matches `test/lib/pot-manager.spec.ts` shape)

Three players with bets `[100, 60, 60]`, one folds at some point:

1. Pot #0: minBet 60 → collects `60×3` = 180, eligible = all three. Folded chips credited `min(F, 3*60)`.
2. Remaining bets `[40, 0, 0]` → Pot #1: minBet 40 → collects `40×1` = 40, eligible = the one player still with a bet.
3. No bets left → done; leftover folded chips land in Pot #1.

Result: player who bet 100 has a 40-chip side pot; the 60-level main pot is contested by all.

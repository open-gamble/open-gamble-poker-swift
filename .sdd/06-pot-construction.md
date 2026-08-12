# 06 — Pot construction

Source: `OpenGamblePoker/Pot.swift`, `OpenGamblePoker/PotManager.swift`

## Pot (`Pot.swift`)

Value struct: `eligiblePlayers: [SeatIndex]`, `size: Chips`.

- `add(_ amount)` — grows the pot (precondition: non-negative).
- `collectBetsFrom(& players) -> Chips` — collects one **level** of bets:
  1. Find the first player with a non-zero `betSize`.
  2. `minBet` = the smallest non-zero `betSize` among all bettors.
  3. Reset `eligiblePlayers`, then for every seat with `betSize != 0`: `takeFromBet(minBet)`, add `minBet` to `size`, and record the seat as eligible.
  4. Returns `minBet` (0 if nobody bet).

Eligibility for a side pot = "had money in that level".

## PotManager (`PotManager.swift`)

State: `pots: [Pot]` (starts with a single empty pot) and `aggregateFoldedBets: Chips`.

- `betFolded(_ amount)` — accumulates folded bets (called by the Dealer when a player folds).
- `collectBetsFrom(& players)` — builds all side pots:
  ```
  loop:
    minBet = lastPot.collectBetsFrom(&players)
    eligible = lastPot.eligiblePlayers.count
    foldContribution = min(aggregateFoldedBets, eligible * minBet)
    lastPot.add(foldContribution); aggregateFoldedBets -= foldContribution
    if any player still has betSize != 0: pots.append(Pot()); continue
    else if aggregateFoldedBets != 0: lastPot.add(aggregateFoldedBets); aggregateFoldedBets = 0
    break
  ```
  Folded money is distributed **proportionally into each eligible level** (up to `eligible * minBet` per level), never creating a phantom side pot. Any remainder goes to the final pot.

## How side pots form

Because `collectBetsFrom` strips exactly one uniform `minBet` from every bettor per iteration, uneven all-in bets create one pot per distinct contribution level, each with its own eligible set. A player who is all-in for less than the biggest bet stops being eligible once their level is exhausted, while deeper stacks keep contributing to higher pots.

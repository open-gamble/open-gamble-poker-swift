# 05 — Round state machine

Source: `OpenGamblePoker/Round.swift`, `OpenGamblePoker/BettingRound.swift`

Two structs drive per-street betting. `Round` tracks turn rotation and contest state; `BettingRound` holds the player roster, the current bet, and raise validation, delegating rotation to `Round`.

## Round (`Round.swift`)

State:
- `activePlayers: [Bool]` — who remains in the street.
- `playerToAct: SeatIndex`, `lastAggressiveActor: SeatIndex`, `numActivePlayers`.
- `contested: Bool`, `firstAction: Bool`.

`Round.Action` is an `OptionSet`: `leave=1<<0, passive=1<<1, aggressive=1<<2`.

**In-progress predicate** (`inProgress`, Round.swift:29):

```
(contested || numActivePlayers > 1) && (firstAction || playerToAct != lastAggressiveActor)
```

A street is over when all players have acted (no open action) or only one player remains.

**`actionTaken(_:)`** (Round.swift:37):
1. Preconditions: in progress; not both `passive` and `aggressive`.
2. An `aggressive` action sets `lastAggressiveActor = playerToAct` and marks `contested = true`; a `passive` action marks `contested = true`.
3. A `leave` action deactivates the player (`activePlayers[playerToAct] = false`, decrement count).
4. `incrementPlayer()` advances to the next active seat, stopping at `lastAggressiveActor` (the action re-opens past the aggressor), wrapping around.

## BettingRound (`BettingRound.swift`)

State: `_players: SeatArray` (its own copy), `round: Round`, `biggestBet`, `minRaise`.

`BettingRound.Action` is a plain enum: `.leave`, `.match`, `.raise`.

**`legalActions()`** (BettingRound.swift:63): `canRaise = totalChips > biggestBet`. If so, the raise range is `[min(minBet, chips), chips]` where `minBet = biggestBet + minRaise`; otherwise `canRaise == false`.

**`actionTaken(_:bet:)`** (BettingRound.swift:78):
- `.raise`: validate via `isRaiseValid`; `player.bet(bet)`; update `minRaise = bet - biggestBet` and `biggestBet = bet`; mark `Round.Action.aggressive` (adding `.leave` if the player is now all-in `stack == 0`).
- `.match`: `player.bet(min(biggestBet, totalChips))`; mark `passive` (adding `.leave` if all-in).
- `.leave`: notify `Round` with `.leave` (used for folds).
- Delegates to `round.actionTaken`.

**Raise validation** (`isRaiseValid`, BettingRound.swift:107): a player with `chips` after the blind may:
- if `chips > biggestBet && chips < minBet` → only all-in (`bet == chips`);
- otherwise → `bet >= minBet && bet <= chips`.

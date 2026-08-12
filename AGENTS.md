# AGENTS.md

Texas Hold'em game engine written in Swift as `OpenGamblePoker`. Chips are integers only — treat as cents; do decimal conversion in the UI layer.

## Architecture

Engine layers (all in `OpenGamblePoker/`): `Table` (state + orchestration) → `Dealer` (one hand) → `BettingRound`/`Round` (per-street rotation), `PotManager`/`Pot` (side pots), `Hand` (7-card evaluation), `Deck`/`Card`/`CommunityCards`.

The public API is the facade in `Poker.swift` — a `public enum Poker` namespace containing `Poker.Table` (a `final class`) plus the facade value types (`Poker.Card`, `Poker.Action`, `Poker.AutomaticAction`, `Poker.Seat`, `Poker.LegalActions`, `Poker.ForcedBets`, `Poker.Winner`). It maps string enums ↔ internal enums and uses camelCase names; internal types are referenced as `OpenGamblePoker.Table` (to avoid clashing with the facade class's own `Table` name).

`Dealer` holds its own copy of the community cards (value semantics); the facade reads `dealer._communityCards` when exposing dealt cards.

## Idioms and gotchas

- The internal `Table` has no `_handPlayers` field — it reads `dealer.bettingRoundPlayers()` (the live `_players`) as the source of truth for `updateTablePlayers`, `clearFoldedBets`, `amendAutomaticActions`, `takeAutomaticAction`, and mid-hand `standUp`. Do not introduce a stale snapshot.
- Action **bitmask enums** (`FOLD CHECK CALL BET RAISE`, automatic actions) → `OptionSet`. Validate single-flag values with a popcount (`BitUtils`).
- `CardRank`, `CardSuit`, `HandRanking` → Int raw-value enums; **preserve numeric significance** (`HandRanking` is `HIGH_CARD=0 … ROYAL_FLUSH=9`). `CardRank` cases are `two…nine, ten, jack, queen, king, ace` — rank 2 is raw value 0.
- Preconditions (`precondition`/`assert`) are the documented API contracts — keep them.
- **Guard array bounds explicitly.** JS-style out-of-bounds reads return `undefined`, but Swift crashes. `Table.incrementButton` guards the manual-button index with `_button < count && _tablePlayers[_button] != nil`.
- **Deck draws from the END.** Tests inject a deterministic deck via a no-op shuffle RNG and pre-arrange cards at `array[51 - index]`. Do not break this contract.
- Chips are `Int` (cents); no `Double` in the engine.
- Engine is synchronous single-threaded (no actors). Public value types are `Sendable`; `Deck` takes an injectable shuffle RNG for deterministic tests.
- `Poker.Table.actionRange.contains()` is used by `Dealer.actionTaken` to validate bets.

## Hand lifecycle (high level)

`sitDown`/`standUp` (pre-hand) → `startHand` (ante, blinds, deal) → repeat `playerToAct` + `actionTaken` while `isBettingRoundInProgress` → `endBettingRound` → … → `showdown` → `winners`. During a hand, standing up is only allowed for the player to act (auto-folds) or others (sets automatic FOLD). Players busted at showdown are stood up automatically.

## Workflow

- **`project.yml` is the source of truth** for the Xcode project (XcodeGen). Never hand-edit `OpenGamblePoker.xcodeproj/project.pbxproj`.
- Run `xcodegen generate` after adding/removing source files or targets, and include the regenerated project in the **same commit** as the source change. Never commit a generated-only change.
- Test locally:
  ```sh
  xcodegen generate
  xcodebuild -project OpenGamblePoker.xcodeproj -scheme OpenGamblePoker -destination 'platform=macOS' test
  ```
- Run a single Swift test suite with `-only-testing:OpenGamblePokerTests/RoundTests` appended to the `xcodebuild` above.
- `README.md` is the API reference; keep it in sync when the facade changes. No CI.

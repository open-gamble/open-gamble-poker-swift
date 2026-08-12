# AGENTS.md

Texas Hold'em game engine, originally TypeScript and ported to Swift as `OpenGamblePoker`. The ongoing focus is **translating the current `src/` codebase into Swift** in `OpenGamblePoker/`. Chips are integers only — treat as cents; do decimal conversion in the UI layer.

## Swift translation (primary focus)

Sources of truth for the port: `.sdd/` design docs + `src/lib/` TS code + `test/` specs. Swift must match TS behavior; when TS logic changes, update `.sdd/` and re-port to Swift.

### File mapping (src → OpenGamblePoker)

| TypeScript | Swift | Status |
|---|---|---|
| `src/lib/card.ts` | `Card.swift` | ✅ ported |
| `src/lib/deck.ts` | `Deck.swift` | ✅ ported |
| `src/lib/player.ts` | `Player.swift` | ✅ ported |
| `src/lib/chip-range.ts` | `ChipRange.swift` | ✅ ported |
| `src/lib/community-cards.ts` | `CommunityCards.swift` | ✅ ported |
| `src/lib/pot.ts` | `Pot.swift` | ✅ ported |
| `src/lib/pot-manager.ts` | `PotManager.swift` | ✅ ported |
| `src/lib/round.ts` | `Round.swift` | ✅ ported |
| `src/lib/betting-round.ts` | `BettingRound.swift` | ✅ ported |
| `src/lib/dealer.ts` | `Dealer.swift` | pending |
| `src/lib/hand.ts` | `Hand.swift` | pending |
| `src/lib/table.ts` | `Table.swift` | pending |
| `src/util/array.ts`, `src/util/bit.ts` | `ArrayUtils.swift`, `BitUtils.swift` | ✅ ported |
| `src/facade/poker.ts` | public `Table` facade | pending |
| `src/types/*.d.ts` | typealiases in `Types.swift` | ✅ ported |

**Port progress:** 11 of 14 files ported. 117 tests in 30 suites pass
(`xcodegen generate && xcodebuild -project OpenGamblePoker.xcodeproj -scheme OpenGamblePoker -destination 'platform=macOS' test`).
Next in dependency order: `Hand` (all leaf dependencies are ported), then `Dealer`, then `Table` + the facade.

### TS → Swift idiom rules

- Action **bitmask enums** (`FOLD CHECK CALL BET RAISE`, automatic actions) → `OptionSet`. Validate single-flag values with a popcount (`BitUtils`).
- `CardRank`, `CardSuit`, `HandRanking` → Int raw-value enums; **preserve numeric significance** (`HandRanking` is `HIGH_CARD=0 … ROYAL_FLUSH=9`).
- Node `assert` guards → `precondition`/`assert`. Assertions ARE the documented API contracts — keep them.
- **Deck draws from the END**. Tests inject a deterministic deck via a no-op shuffle RNG and pre-arrange cards at `array[51 - index]`. Do not break this contract.
- Chips are `Int` (cents); no `Double` in the engine.
- The public `Table` facade maps string enums ↔ internal enums and uses camelCase names. Don't change facade behavior.
- Engine is synchronous single-threaded (no actors). Public value types are `Sendable`; `Deck` takes an injectable shuffle RNG for deterministic tests.

### Verification

Port each spec (`test/lib/*.spec.ts`, `test/facade/poker.spec.ts`) to swift-testing (`@Test`/`#expect`) in `Tests/OpenGamblePokerTests/`, mirroring `test/`. Parity = both the TS suite and the Swift suite pass.

### Workflow

- **`project.yml` is the source of truth** for the Xcode project (XcodeGen). Never hand-edit `OpenGamblePoker.xcodeproj/project.pbxproj`.
- Run `xcodegen generate` after adding/removing source files or targets, and include the regenerated project in the **same commit** as the source change. Never commit a generated-only change.
- Test locally:
  ```sh
  xcodegen generate
  xcodebuild -project OpenGamblePoker.xcodeproj -scheme OpenGamblePoker -destination 'platform=macOS' test
  ```

## Commands

### TypeScript (reference)
```sh
npm test                     # jest (ts-jest, node env)
npx jest test/lib/xxx.spec.ts   # run a single spec file
npm run watch                # jest --watch
npm run build                # rimraf dist && tsc (src only; test/ is excluded in tsconfig)
npm run lint                 # tslint --project tsconfig.json (defaultSeverity: error)
npm run coverage
npm run dev                  # nodemon + ts-node on src/index.ts
```

`dist/` is committed to the repo — run `npm run build` when changing src and include the output in the commit (repo convention, see git history).

## Architecture (reference)

- TS engine layers (all in `src/lib/`): `Table` (state + orchestration) → `Dealer` (one hand) → `BettingRound`/`Round` (per-street rotation), `PotManager`/`Pot` (side pots), `Hand` (7-card evaluation), `Deck`/`Card`/`CommunityCards`. The Swift port mirrors this layering.
- `src/index.ts` exports only `Poker.Table` (the facade in `src/facade/poker.ts`). The facade is the public API; it maps string enums ↔ internal bitmask enums and uses camelCase names.
- `src/types/*.d.ts` are pure type aliases (`Chips = number`, `SeatArray = (Player | null)[]`, etc.), imported via tsconfig path alias `types/* → src/types/*`.
- `test/` mirrors `src/` (`test/lib/*.spec.ts`, `test/facade/poker.spec.ts`). ts-jest compiles specs even though `tsconfig.json` excludes them.

## Conventions and gotchas (TS reference)

- `CardRank` enum is `_2 ... _9, T, J, Q, K, A` (underscore only so `2` is a valid identifier); the facade strips it.
- `Table.ActionRange.contains()` is used by `Dealer.actionTaken` to validate bets.
- No CI. README.md is the API reference; keep it in sync when the facade changes.

## Hand lifecycle (high level)

`sitDown`/`standUp` (pre-hand) → `startHand` (ante, blinds, deal) → repeat `playerToAct` + `actionTaken` while `isBettingRoundInProgress` → `endBettingRound` → … → `showdown` → `winners`. During a hand, standing up is only allowed for the player to act (auto-folds) or others (sets automatic FOLD). Players busted at showdown are stood up automatically.

# AGENTS.md

Texas Hold'em game engine (TypeScript), port of [JankoDedic/poker](https://github.com/JankoDedic/poker) (C++). Chips are integers only — treat as cents; do decimal conversion in the UI layer.

## Commands

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

## Architecture

- `src/index.ts` exports only `Poker.Table` (the facade in `src/facade/poker.ts`). The facade is the public API; it maps string enums ↔ internal bitmask enums and uses camelCase names. Don't change the facade's behavior — it conforms to the upstream JS API.
- Engine layers (all in `src/lib/`): `Table` (table state + orchestration) → `Dealer` (one hand) → `BettingRound`/`Round` (per-street rotation), `PotManager`/`Pot` (side pots), `Hand` (7-card evaluation), `Deck`/`Card`/`CommunityCards`.
- `src/types/*.d.ts` are pure type aliases (`Chips = number`, `SeatArray = (Player | null)[]`, etc.), imported via tsconfig path alias `types/* → src/types/*`.
- `src/util/array.ts` holds shared helpers (`nextOrWrap`, `findIndexAdjacent`, `rotate`, `unique`, `shuffle`, `findMax`); `src/util/bit.ts` is a popcount.

## Conventions and gotchas

- Actions are **bitmask enums**: `Dealer.Action` (`FOLD CHECK CALL BET RAISE`) and `Table.AutomaticAction`. Validate single-flag values with `bitCount()` from `src/util/bit.ts`. `Table.ActionRange.contains()` is used by `Dealer.actionTaken` to validate bets.
- `CardRank` enum is `_2 ... _9, T, J, Q, K, A` (underscore only so `2` is a valid identifier); the facade strips it. `HandRanking` enum order is numerically significant (`HIGH_CARD=0 … ROYAL_FLUSH=9`).
- **Deck draws from the END**: `draw()` does `--_size`. Tests inject a deterministic deck via `new Deck(() => {})` (no-op shuffle) and pre-arrange cards with `array[51 - index] = card` — see `test/helper/card.ts` (it also provides ready-made fixed-deal helpers). Do not break this contract.
- Heavy use of Node `assert` as precondition guards — assertions ARE the documented API contracts. Keep them when porting logic.
- `test/` mirrors `src/` (`test/lib/*.spec.ts`, `test/facade/poker.spec.ts`). ts-jest compiles specs even though `tsconfig.json` excludes them.
- No CI. README.md is the API reference; keep it in sync when the facade changes.
- `.sdd/` contains language-agnostic design docs of the engine logic (written for a Swift re-port) — update them when the logic in `src/lib/` changes.

## Swift port (OpenGamblePoker)

- `OpenGamblePoker/` is the Swift library source (single framework target `OpenGamblePoker`, iOS + macOS), ported from `.sdd/` + `src/lib/`. `Tests/OpenGamblePokerTests/` holds swift-testing (`@Test`/`#expect`) unit tests.
- **`project.yml` is the source of truth** for the Xcode project (XcodeGen). Never hand-edit `OpenGamblePoker.xcodeproj/project.pbxproj`.
- Run `xcodegen generate` after adding/removing source files or targets, and include the regenerated project in the **same commit** as the source change. Never commit a generated-only change.
- Test locally:
  ```sh
  xcodegen generate
  xcodebuild -project OpenGamblePoker.xcodeproj -scheme OpenGamblePoker -destination 'platform=macOS' test
  ```
## Hand lifecycle (high level)

`sitDown`/`standUp` (pre-hand) → `startHand` (ante, blinds, deal) → repeat `playerToAct` + `actionTaken` while `isBettingRoundInProgress` → `endBettingRound` → … → `showdown` → `winners`. During a hand, standing up is only allowed for the player to act (auto-folds) or others (sets automatic FOLD). Players busted at showdown are stood up automatically.

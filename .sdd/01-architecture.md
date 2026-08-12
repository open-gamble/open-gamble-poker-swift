# 01 — Architecture

Source: `OpenGamblePoker/Poker.swift`, `OpenGamblePoker/Table.swift`, `OpenGamblePoker/Dealer.swift`

## Layers and ownership

```
┌─────────────────────────────────────────────────────────────┐
│ Facade (Poker.Table, in Poker.swift)                        │  public API; no logic
│  string enums ↔ internal enums; camelCase names             │
└───────────────▲─────────────────────────────────────────────┘
                │ delegates (final class wrapping a Table struct)
┌───────────────┴─────────────────────────────────────────────┐
│ Table (struct)                                              │  table lifetime; one hand at a time
│  _tablePlayers (seated)                     no _handPlayers │
│  _staged[] (changed since hand start)   _automaticActions[] │
│  _button, _forcedBets, _deck, _dealer?                      │
│  owns Dealer lifecycle per hand; reads dealer.bettingRoundPlayers() │
└───────────────▲─────────────────────────────────────────────┘
                │ creates one Dealer per hand
┌───────────────┴─────────────────────────────────────────────┐
│ Dealer (struct, one hand)                                   │
│  _players (current street roster), _bettingRound            │
│  _potManager, _holeCards, _roundOfBetting, _communityCards  │
│  hand start / action mapping / street transitions /         │
│  showdown payouts                                           │
└───────┬───────────────┬──────────────────┬──────────────────┘
        │               │                  │
┌───────┴─────┐  ┌──────┴──────┐   ┌───────┴────────┐
│ Round/      │  │ PotManager/ │   │ Hand (static   │
│ BettingRound│  │ Pot         │   │ evaluator)     │
│ turn order  │  │ side pots   │   │ 7→5 + compare  │
└─────────────┘  └─────────────┘   └────────────────┘
```

## Key decisions

- **One `Dealer` per hand.** The dealer is constructed, `startHand()`ed, driven to completion, then discarded. `Table` recreates it on every `startHand` (`Table.startHand`, `Table.swift:96`).
- **Value semantics, no aliasing.** Everything is a `struct` (with copy-on-write). Where the original engine relied on shared mutable `Player` objects, Swift copies instead. Two consequences:
  1. **`Table` has no `_handPlayers` snapshot.** It reads the dealer's live roster (`dealer.bettingRoundPlayers()`, the dealer's `_players`) as the source of truth for `updateTablePlayers`, `clearFoldedBets`, `amendAutomaticActions`, `takeAutomaticAction`, and mid-hand `standUp`. A stale snapshot would silently diverge — do not reintroduce one.
  2. `Dealer` keeps its **own copy** of the community cards (`dealer._communityCards`); `Table.communityCards()` returns that copy, and the facade maps it to cards.
- **Hand players are clones.** `startHand` passes `_tablePlayers` (a value copy) into the dealer, so the seated players' pre-hand stack survives street-by-street accounting; `updateTablePlayers()` copies hand-player chip state back into `_tablePlayers` only for seats not flagged `_staged`.

## One-hand call flow

```
sitDown/standUp (pre-hand)  →  startHand(seat?)  →  repeat { playerToAct, actionTaken }  →  endBettingRound  →  … →  showdown  →  winners
```

During a hand, standing up is only allowed for the player to act (auto-folds) or for others (sets automatic FOLD). Players busted at showdown are stood up automatically.

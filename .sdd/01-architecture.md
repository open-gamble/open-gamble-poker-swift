# 01 — Architecture

Source: `src/facade/poker.ts`, `src/lib/table.ts`, `src/lib/dealer.ts`

## Layers and ownership

```
┌─────────────────────────────────────────────────────────────┐
│ Facade (Poker.Table)                                        │  public API; no logic
│  string enums ↔ bitmask enums; camelCase names              │
└───────────────▲─────────────────────────────────────────────┘
                │ delegates
┌───────────────┴─────────────────────────────────────────────┐
│ Table                                                       │  table lifetime; one hand at a time
│  _tablePlayers (seated)      _handPlayers (in hand, cloned)│
│  _staged[] (changed since hand start)   _automaticActions[] │
│  _button, _forcedBets, _deck, _communityCards               │
│  owns Dealer lifecycle per hand                             │
└───────────────▲─────────────────────────────────────────────┘
                │ creates one Dealer per hand
┌───────────────┴─────────────────────────────────────────────┐
│ Dealer (one hand)                                           │
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

- **Two player rosters exist.** `Table._tablePlayers` is who is physically seated; `Table._handPlayers` is the cloned roster the hand runs on. Every action/street transition mutates the hand roster; `Table.updateTablePlayers()` copies hand-player chip state back into table players **only for seats not flagged `_staged`** (table.ts:429-438).
- **One `Dealer` per hand.** The dealer is constructed, `startHand()`ed, driven to completion, then discarded. `Table` recreates it on every `startHand` (table.ts:119).
- **Hand players are clones.** `startHand` clones each seated player via the `Player(Player)` copy constructor so the table player's pre-hand stack survives street-by-street accounting (table.ts:115).
- **Preconditions = contracts.** Every public method asserts its precondition (e.g. "betting round must be in progress"). Callers must satisfy them; the engine is a strict state machine, not defensive.

## One-hand call flow

```
Table.sitDown(seat, buyIn)                     (pre-hand only)
Table.startHand(seat?)                        → button resolve → deck reset
                                               → Dealer.startHand:
                                                   ante → blinds → hole cards
                                                   → first BettingRound (if >1 participant)
Table.playerToAct() / Table.legalActions()
Table.actionTaken(action, bet)                → Dealer.actionTaken → BettingRound.actionTaken
                                               → Table resolves automatic actions (see 03)
Table.endBettingRound()                       → pots formed → next street or river done
Table.showdown()                              → payouts → winners()
```

## State flag cross-references

| Flag | Owner | Meaning |
|------|-------|---------|
| `handInProgress` | Dealer | a hand is active (between startHand and showdown) |
| `bettingRoundInProgress` | BettingRound/Round | players still must act on the current street |
| `bettingRoundsCompleted` | Dealer | river betting done; showdown is the only legal next step |
| `_firstTimeButton` / `_buttonSetManually` | Table | button placement algorithm, see 03 |
| `_staged[seat]` | Table | seat changed (sat down / stood up) since hand start — shields table player from hand updates and automatic actions |

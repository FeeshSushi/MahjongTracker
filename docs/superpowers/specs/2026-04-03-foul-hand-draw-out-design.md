# False Win & Draw Out — Design Spec

**Date:** 2026-04-03  
**Status:** Approved

## Context

Beginners sometimes declare invalid wins (false win / 詐糊) or rounds end with no winner (draw out). Currently neither case is supported — the only options are tsumo, deal-in, and manual adjust. This spec adds dedicated flows for both.

---

## Rules

### False Win (詐糊)
- The offending player pays a **flat penalty** (not scaled by multiplier) to each of the other 3 players.
- After a false win: **dealer stays, honba increments** (same as dealer winning a hand).
- Penalty amount is configurable in game settings (default: 384 pts).

### Draw Out (no winner)
- No point changes — tiles exhausted with no winner.
- **Dealer stays, honba increments** (same as false win round advancement).

---

## Data Layer

### `WinType` (ScoreRecord.swift)
Add two new cases:
```swift
case foulHand   // false win — offender identified by winnerSeatIndex
case drawOut    // no winner — all deltas zero
```

### `GameSession`
New stored property:
```swift
var foulPenalty: Int = 384
```
Passed in from `StartView` settings at game creation. Stored directly on `GameSession` like `multiplier`.

New methods:
```swift
func applyFoulHand(deltas: [Int], record: ScoreRecord) {
    for player in players { player.points += deltas[player.seatIndex] }
    history.append(record)
    advanceRound(dealerWon: true)  // dealer stays, honba increments
}

func applyDrawOut(record: ScoreRecord) {
    history.append(record)         // no point changes
    advanceRound(dealerWon: true)  // dealer stays, honba increments
}
```

---

## Scoring Engine

New static function in `ScoringEngine`:
```swift
static func foulHandDeltas(penalty: Int, offenderSeatIndex: Int) -> [Int] {
    var deltas = Array(repeating: penalty, count: 4)
    deltas[offenderSeatIndex] = -(penalty * 3)
    return deltas
}
```

`summaryString` gains two new switch cases:
- `.foulHand`: `"[Name] false win (-[penalty×3])"`
- `.drawOut`: `"Draw out — no winner"`

---

## UI

### Settings (`StartView` → `SettingsSheetView`)
New Stepper: **"False Win Penalty"**, range 100...10000, step 100, default 384.  
Displayed alongside existing multiplier / min fan steppers.  
`startGame()` passes it into `GameSession.init(... foulPenalty: foulPenalty)`. `GameSession.init` gains `foulPenalty: Int` as a new parameter.

### `CenterBoxView` More menu
Two new `@Binding` properties added: `showFoulHand: Bool` and `showDrawOutAlert: Bool`.  
Two new entries in the More menu below "Manual Adjust":
- **False Win** → sets `showFoulHand = true`
- **Draw Out** → sets `showDrawOutAlert = true`

### `FoulHandView` (new file)
Sheet modelled after `ManualAdjustView`:
- `PlayerSegmentedPicker` to select the offender
- Payment preview: offender `-(penalty × 3)`, others each `+penalty`
- Confirm → builds `ScoreRecord(winType: .foulHand, winnerSeatIndex: offenderSeatIndex, deltas: ...)` → calls `session.applyFoulHand`

### `GameBoardView`
- `showFoulHand: Bool` state drives the `FoulHandView` sheet
- `showDrawOutAlert: Bool` state drives the draw out confirm alert
- Draw out confirm → builds `ScoreRecord(winType: .drawOut, winnerSeatIndex: nil, deltas: [0,0,0,0], ...)` → calls `session.applyDrawOut`

### History (`HistoryRowView`)
No structural changes — `entry.summary` already drives display. The new summary strings handle both cases.

---

## Files Changed

| File | Change |
|---|---|
| `Models/ScoreRecord.swift` | Add `.foulHand`, `.drawOut` to `WinType` |
| `Models/GameSession.swift` | Add `foulPenalty`, `applyFoulHand`, `applyDrawOut` |
| `Scoring/ScoringEngine.swift` | Add `foulHandDeltas`, update `summaryString` |
| `Views/StartView.swift` | Add foulPenalty stepper in settings; pass to GameSession.init |
| `Views/GameBoardView.swift` | Add sheet/alert state; wire up More menu actions |
| `Views/FoulHandView.swift` | New file |
| `Views/CenterBoxView` (in GameBoardView.swift) | Add False Win + Draw Out menu items |

---

## Out of Scope
- Configuring draw out behavior (always dealer stays + honba increments)
- Multiple false wins in one round
- Tracking false win count per player in profile stats

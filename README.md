# MahjongTracker

A native iOS scorekeeper for Hong Kong Style Mahjong. Handles all fan-based payment calculations automatically so players can focus on the game.

**Platform:** iOS 18+ · **Stack:** SwiftUI + SwiftData · **Storage:** Local only, no network

---

## Features

- **Automatic scoring** — Deal-in and tsumo payments from fan count with configurable multiplier
- **Honba payments** — Each honba adds 100 pts per payer (standard HK rules)
- **Dealer rotation** — Seat wind and prevailing wind progression (East → South → West → North)
- **False win (詐糊)** — Configurable flat penalty paid to all other players
- **Draw out** — No-winner round; dealer stays, honba increments
- **Manual adjust** — Point corrections with optional reason
- **Auto game-over** — Ends when North round completes
- **Player profiles** — Reusable profiles with name, emoji, and color; game history tracked per profile
- **Hand reference** — 40+ hand types with English/Chinese names, fan values, and fan → points table
- **Offline** — All data stored locally via SwiftData

---

## Game Settings (per game)

| Setting | Default | Range |
|---|---|---|
| Starting Points | 10,000 | 1,000 – 100,000 |
| Multiplier | 1× | 1 – 1,000 |
| Minimum Fan | 3 | 0 – 5 |
| False Win Penalty | 384 pts | 100 – 10,000 |

---

## Project Structure

```
MahjongTracker/
├── MahjongTrackerApp.swift       # Entry point, ModelContainer, schema wipe on version bump
├── ContentView.swift             # Root router
├── AppStorageKeys.swift          # Centralized UserDefaults keys + schema version
├── MahjongTheme.swift            # Design tokens (colors, radii, layout, timing)
│
├── Models/
│   ├── GameSession.swift         # @Model — game state, round logic, player + history relationships
│   ├── UserProfile.swift         # @Model — player profile + game result history
│   ├── PlayerRecord.swift        # @Model — player in an active game (seatIndex is stable identity)
│   ├── ScoreRecord.swift         # @Model — one round's result (WinType, deltas, summary)
│   ├── GameResultRecord.swift    # @Model — final points + placement for a completed game
│   └── Wind.swift                # Enum — East/South/West/North
│
├── Scoring/
│   └── ScoringEngine.swift       # Pure functions — fan→points, tsumo/deal-in/foul deltas, summaries
│
└── Views/
    ├── SplashView.swift          # Home screen (Play / Continue / New Game / Players)
    ├── StartView.swift           # New game setup, player slots, settings
    ├── GameBoardView.swift       # Main 4-player board, intro animation, center box
    ├── PlayerTileView.swift      # Individual player card
    ├── ScoringSheetView.swift    # Score a hand (win type, fan, payment preview)
    ├── FoulHandView.swift        # False win — pick offender, penalty preview
    ├── GameOverCard.swift        # End-game rankings overlay
    ├── HistoryView.swift         # Score log for current game
    ├── HistoryRowView.swift      # Expandable history row with per-player deltas
    ├── ManualAdjustView.swift    # Manual point adjustment
    ├── HandReferenceView.swift   # Tile guide, hand types, fan→points table
    ├── PlayersView.swift         # Profile grid + per-profile game history
    └── ProfilePickerSheet.swift  # Profile picker, add/edit profile forms
```

---

## Architecture Notes

**SwiftData @Relationship** — `GameSession` owns `[PlayerRecord]` and `[ScoreRecord]` via cascade-delete relationships. `UserProfile` owns `[GameResultRecord]`. 

**Pure scoring engine** — `ScoringEngine` is a stateless enum with static functions. No view or model dependencies.

**Schema versioning** — `currentSchemaVersion` in `AppStorageKeys.swift`. Bumping it triggers a synchronous store wipe on next launch before any `@Query` runs.

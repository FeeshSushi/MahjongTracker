# MahjongTracker

A scorekeeper for Hong Kong Style Mahjong, built natively for iOS with SwiftUI and SwiftData. Handles all fan-based payment calculations automatically, tracks dealer rotation and wind progression, and persists player profiles and game history.

---

## Features

- **Automatic scoring** — Tsumo (self-draw) and deal-in payments calculated from fan count with configurable multiplier
- **Full fan → points table** — 1–12 fan with limit hand support (13+ fan = 384 pts)
- **Dealer rotation** — Automatic seat wind and prevailing wind progression (East → South → West → North)
- **Honba tracking** — Consecutive dealer wins increment honba; resets on dealer change
- **Auto game-over** — Game ends automatically when the North round completes
- **Player profiles** — Save reusable profiles with custom name, emoji, and color
- **Game history** — Full score log per game with expandable round detail
- **Hand reference** — 40+ hand types with English/Chinese names and fan values
- **No network, no tracking** — All data stored locally via SwiftData

---

## Tech Stack

| | |
|---|---|
| **Platform** | iOS 18+ |
| **UI** | SwiftUI |
| **Persistence** | SwiftData |
| **Architecture** | Single `ModelContainer`, `@Model` classes, JSON-encoded value-type blobs |
| **Logging** | OSLog (`GameSession`, `UserProfile` categories) |

---

## Project Structure

```
MahjongTracker/
├── MahjongTrackerApp.swift     # App entry, ModelContainer setup with in-memory fallback
├── ContentView.swift           # Root router (Splash / StartView / GameBoardView)
├── MahjongTheme.swift          # Design token system (colors, radii, layout, timing)
│
├── Models/
│   ├── GameSession.swift       # @Model — active game state, score history, round logic
│   ├── UserProfile.swift       # @Model — player profile, game result history
│   ├── PlayerState.swift       # Codable value type — name, emoji, color, points
│   ├── ScoreEntry.swift        # Codable value type — one round's result + deltas
│   ├── GameResult.swift        # Codable value type — final points + placement per game
│   └── Wind.swift              # Enum — East/South/West/North with character/label
│
├── Views/
│   ├── SplashView.swift        # Home screen
│   ├── StartView.swift         # New game setup + SettingsSheetView
│   ├── GameBoardView.swift     # Main 4-player board + intro animation
│   ├── PlayerTileView.swift    # Individual player card (dealer styling, points)
│   ├── GameOverCard.swift      # End-game results overlay
│   ├── ScoringSheetView.swift  # Score a hand (win type, fan, payment preview)
│   ├── HandReferenceView.swift # Tile reference + hand types + fan→points table
│   ├── HistoryView.swift       # Full game score log
│   ├── HistoryRowView.swift    # Single expandable history row
│   ├── ManualAdjustView.swift  # Manual point adjustment for any player
│   ├── PlayersView.swift       # Profile management grid + game history per player
│   └── ProfilePickerSheet.swift # Profile picker + ProfileCard + AddProfileView + EditProfileView
│
└── ScoringEngine.swift         # Pure functions — fan→points table, tsumo/deal-in deltas
```

---

## View Flow

```
App Launch
└── ContentView (root router)
    ├── No active game  →  SplashView  →  "Play"         →  StartView
    ├── Active game     →  SplashView  →  "Continue"     →  GameBoardView
    └── Active game     →  SplashView  →  "New Game"     →  StartView (ends prior game)
```

### SplashView
Home screen on dark felt green. Shows **Play** (no active game) or **Continue / New Game** (active game). **Players** button opens the profile manager.

```
SplashView
├── "Play" / "New Game"  →  StartView
├── "Continue"           →  GameBoardView
└── "Players"            →  PlayersView (sheet)
    ├── Tap profile card     →  ProfileResultsSheet (game history)
    ├── Context menu › Edit  →  EditProfileView (sheet)
    └── "+ New"              →  AddProfileView (sheet)
```

### StartView
Configure a new game before it begins. Four player slots default to "Player 1–4"; tapping a slot opens the profile picker. Unassigned players get auto-assigned colors from a default palette. The gear icon opens game settings.

```
StartView
├── Tap player slot  →  ProfilePickerSheet (sheet)
│   ├── Tap profile      →  selects profile, dismisses
│   ├── Context › Edit   →  EditProfileView (sheet)
│   └── "+ New"          →  AddProfileView (sheet)
├── Gear icon        →  SettingsSheetView (sheet)
│   ├── Starting Points  (1,000 – 100,000, step 1,000; default 10,000)
│   ├── Multiplier       (1 – 1,000; scales all payments)
│   └── Minimum Fan      (0 = none, or 1–5; enforced on confirm)
└── "Start Game"     →  GameBoardView
```

### GameBoardView
The main game screen. Four player tiles surround a center info box — bottom is the local player, top is opposite, left and right are the side players. Each tile shows name, emoji, seat wind, and current points. Tapping a tile opens scoring for that player as the winner.

On first launch the board runs a two-phase intro animation: players are randomly shuffled into seats, then a spinning highlight selects the starting dealer.

```
GameBoardView
├── Tap player tile      →  ScoringSheetView (sheet)
│   ├── Win type: Tsumo or Deal-in
│   ├── Winner picker    (player color segmented control)
│   ├── Discarder picker (deal-in only)
│   ├── Fan count        (stepper 0–12, or Limit Hand toggle)
│   ├── Payment preview  (live delta per player)
│   └── "Confirm"        →  applies deltas, advances round, dismisses
│
├── Center box
│   ├── Prevailing wind character + round label + honba
│   ├── "Hand Reference" →  HandReferenceView (sheet)
│   │   ├── Tile reference (Characters, Circles, Bamboo, Winds, Dragons)
│   │   ├── Fan → Points table (1–12 fan + Limit)
│   │   └── Hand types by category (40+ entries, highlighted = key hands)
│   └── "More" menu
│       ├── "End Game"       →  alert → GameOverCard (overlay)
│       ├── "Score History"  →  HistoryView (sheet)
│       │   └── Tap row      →  expands inline (per-player deltas)
│       └── "Manual Adjust"  →  ManualAdjustView (sheet)
│           ├── Player picker
│           ├── Amount stepper
│           └── "Apply"      →  adjusts points, logs to history
│
└── Auto end (North round complete)  →  GameOverCard (overlay)
```

### GameOverCard
Full-screen overlay (not a sheet) that appears when the game ends — either manually via "End Game" or automatically when the North round completes. Shows final rankings with placement medals, net point gain/loss per player, and the biggest single hand of the game. Tapping **Done** saves results to each linked player profile and returns to SplashView.

---

## Scoring Engine

`ScoringEngine.swift` contains pure, stateless functions:

| Function | Description |
|---|---|
| `points(for fan:)` | Maps fan count to base point value (1 fan = 1 pt … 13+ fan = 384 pts) |
| `tsumoDeltas(fan:multiplier:winnerIndex:)` | All three non-winners each pay winner; dealer pays double if non-dealer wins |
| `dealInDeltas(fan:multiplier:winnerIndex:discarderIndex:)` | Discarder pays full amount to winner; others pay nothing |
| `summaryString(...)` | Human-readable round summary for history display |

---

## Data Model

### GameSession (`@Model`)
Persists one game. Game state (players, history, profileIDs) is stored as JSON-encoded blobs inside SwiftData properties. Round logic lives in `advanceRound(dealerWon:)` — honba increments on dealer win; otherwise dealer rotates and prevailing wind advances after four full rotations.

### UserProfile (`@Model`)
Stores a reusable player profile. `gameResults` (placement + final points per game) is JSON-encoded. Linked to a game via UUID stored in `GameSession.profileIDs`.

---

## Design System

All visual constants live in `MahjongTheme.swift`:

| Token | Usage |
|---|---|
| `feltDark` | Background for game screens (dark green) |
| `panelDark` | Background for utility sheets (dark gray) |
| `tableFelt` | Button tint, highlighted rows |
| `tileBackground` | Dark glass card background |
| `dealerTileBackground` / `dealerBorderColor` | Amber + gold dealer styling |
| `primaryText` / `secondaryText` | White / white-85% |
| `dealerText` | Gold — limit hands, biggest win label |
| `MahjongTheme.Radius.*` | Corner radii by context |
| `MahjongTheme.Opacity.*` | Named opacity levels |
| `MahjongTheme.Layout.*` | Dimensions, spacings, border widths |
| `MahjongTheme.Timing.*` | Animation durations |

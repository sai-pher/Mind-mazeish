# Plan: Maze Mode (Core Game)

## Context
Issue #40 requests a maze navigation element in Mind Mazeish, mirroring the original Mind Maze game. The owner has specified a 10×10 grid layout, hidden Throne Room, fog-of-war reveal, answer-to-unlock doors, skip-to-pass, and free backtracking. XP / reward systems are explicitly out of scope for this iteration. The feature is additive — existing standard/endless modes are untouched.

---

## Data Models (`lib/features/maze/domain/models/`)

| Model | Purpose |
|-------|---------|
| `MazePosition` | `(x, y)` coordinate on 10×10 grid |
| `DoorState` enum | `wall / locked / open / skipped` — per connection |
| `RoomStatus` enum | `hidden / visible / visited / answered / skipped` — per room |
| `MazeRoom` | Cell: position, questionId, isThroneRoom, status, answeredCorrectly |
| `MazeStatus` enum | `loading / navigating / questionActive / answerRevealed / complete / gameOver` |
| `MazeState` | Full state: grid, connections map, playerPosition, thronePosition, questions, lives, status |

All immutable, pure Dart, `copyWith` pattern. See `proposal/01-maze-state-model.md`.

---

## Maze Generation (`lib/features/maze/data/maze_generator.dart`)

- **Algorithm**: Recursive backtracker DFS (perfect maze — one path between any two cells)
- **Grid**: 10×10, player starts at `(0,0)`, Throne Room at maximum BFS distance from start
- **Questions**: One `QuizQuestion` per non-start, non-throne cell; drawn from `selectQuestionsFrom(config)`; cycles if pool < 98
- **Fog of war**: Derived from `RoomStatus` at render time — not stored in state
- **Pure function**: `MazeGenerator.generate(config, questionPool, seed)` → `MazeState`

See `proposal/02-maze-generation.md`.

---

## State Provider (`lib/features/maze/presentation/providers/maze_state_provider.dart`)

```
MazeStateNotifier extends Notifier<MazeState?>
  startMaze(QuizConfig)       — generate + load questions → MazeState
  movePlayer(Direction)       — validate connection, update position, open question if needed
  submitAnswer(int index)     — check correctness, update room/connection, decrement lives if wrong
  skipRoom()                  — mark room skipped, connection skipped, stay navigating
  dismissFunFact()            — answerRevealed → navigating
  restart()                   — null state

enum Direction { north, south, east, west }
```

---

## Screens & Widgets

| File | Purpose |
|------|---------|
| `MazeSettingsScreen` | Topic + difficulty picker; "Enter the Maze" CTA |
| `MazeScreen` | Main screen: map + action panel |
| `MazeMapWidget` | 10×10 grid; fog of war; player position |
| `MazeCellWidget` | Single cell: status-driven appearance |
| `MazeActionPanel` | Direction arrows, lives, contextual room buttons |
| Question bottom sheet | Reuse `AnswerButton` + `QuestionCard` widgets from gameplay |

See `proposal/03-maze-ui.md` for visual spec.

---

## Routing

| Route | Screen | Notes |
|-------|--------|-------|
| `/maze-settings` | MazeSettingsScreen | Entry from StartScreen |
| `/maze` | MazeScreen | Replaces `/game` for maze flow |

Results navigate to existing `/results` with maze-specific extras.

---

## Entry Point

Add "Maze Mode" tile on `StartScreen` alongside existing "Play" / "Endless" tiles.

---

## Order of Operations

1. **Branch**: create `feat/issue-40-put-maze-in-mind-mazeish` from `main`
2. **Domain models**: `MazePosition`, `DoorState`, `RoomStatus`, `MazeRoom`, `MazeStatus`, `MazeState` — pure Dart, no Flutter
3. **Unit tests**: `test/features/maze/domain/maze_state_test.dart` — state transitions, lives, win/lose
4. **Maze generator**: `MazeGenerator.generate()` — DFS, throne placement, question assignment
5. **Generator tests**: `test/features/maze/data/maze_generator_test.dart` — connectivity, throne placement, 99 connections
6. **State provider**: `MazeStateNotifier` — `startMaze`, `movePlayer`, `submitAnswer`, `skipRoom`, `dismissFunFact`
7. **Routing**: add `/maze-settings` and `/maze` to `lib/app.dart`
8. **MazeSettingsScreen**: topic + difficulty picker reusing existing components
9. **MazeMapWidget + MazeCellWidget**: grid render, fog of war, player icon
10. **MazeActionPanel**: direction arrows, lives display, room context buttons
11. **MazeScreen**: compose map + action panel + question bottom sheet
12. **StartScreen**: add Maze Mode entry tile
13. **Results integration**: pass maze summary to ResultsScreen
14. **flutter analyze + flutter test**: zero errors
15. **Release notes**: run `release-notes` skill, commit
16. **Push + PR**: target `main`

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `lib/features/maze/domain/models/maze_position.dart` | Create |
| `lib/features/maze/domain/models/door_state.dart` | Create |
| `lib/features/maze/domain/models/room_status.dart` | Create |
| `lib/features/maze/domain/models/maze_room.dart` | Create |
| `lib/features/maze/domain/models/maze_status.dart` | Create |
| `lib/features/maze/domain/models/maze_state.dart` | Create |
| `lib/features/maze/data/maze_generator.dart` | Create |
| `lib/features/maze/presentation/providers/maze_state_provider.dart` | Create |
| `lib/features/maze/presentation/screens/maze_settings_screen.dart` | Create |
| `lib/features/maze/presentation/screens/maze_screen.dart` | Create |
| `lib/features/maze/presentation/widgets/maze_map_widget.dart` | Create |
| `lib/features/maze/presentation/widgets/maze_cell_widget.dart` | Create |
| `lib/features/maze/presentation/widgets/maze_action_panel.dart` | Create |
| `lib/app.dart` | Modify — add `/maze-settings`, `/maze` routes |
| `lib/features/start/presentation/screens/start_screen.dart` | Modify — add Maze Mode tile |
| `test/features/maze/domain/maze_state_test.dart` | Create |
| `test/features/maze/data/maze_generator_test.dart` | Create |
| `release_notes.md` | Modify (release-notes skill) |

---

## Verification

```bash
export PATH="$PATH:/opt/flutter/bin"
flutter analyze --fatal-infos
flutter test --reporter expanded
# Expected: 0 errors, 0 warnings; all maze tests pass
```

Manual smoke test on device:
1. Start → Maze Mode → pick topic → Enter the Maze
2. Fog of war visible on initial render (only start cell + neighbours shown)
3. Move N/S/E/W — walls block invalid moves
4. Enter room → question sheet appears
5. Answer correctly → cell turns gold, door opens
6. Answer wrong → life lost; red flash; can retry or skip
7. Skip → cell muted amber, door stays "skipped"
8. Backtrack through visited rooms freely
9. Reach Throne Room → complete screen
10. Lives reach 0 → game over screen

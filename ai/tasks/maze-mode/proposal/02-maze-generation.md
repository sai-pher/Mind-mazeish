# Proposal 02: Maze Generation

## Algorithm: Recursive Backtracker (DFS)

Standard algorithm that produces a **perfect maze** (exactly one path between any two cells, no isolated cells). Every cell is reachable from the start. Produces long winding corridors — good for exploration.

### Steps
1. Start at cell (0,0).
2. Mark current cell visited.
3. While unvisited neighbors exist:
   a. Pick a random unvisited neighbor.
   b. Remove the wall between current and chosen (add connection `DoorState.locked`).
   c. Recurse into chosen.
4. Backtrack when no unvisited neighbors remain.

All walls not carved remain `DoorState.wall`.

### Throne Room placement
- After generation, compute **distance from start** for all cells (BFS).
- Place Throne Room at the cell with **maximum distance**.
- This guarantees the player must traverse most of the maze to win.

### Question assignment
```dart
// 1. Collect all cells except start and throne
// 2. Call selectQuestionsFrom(config, count: cells.length) — cycles if needed
// 3. Assign one QuizQuestion per cell in shuffled order
```

### Seeding
- Use `Random(seed)` where seed = `DateTime.now().millisecondsSinceEpoch`
- Store seed in `MazeState` for potential future replay/debug use

---

## `MazeGenerator` API

```dart
class MazeGenerator {
  /// Returns a fully initialized MazeState ready to play.
  static MazeState generate({
    required QuizConfig config,
    required List<QuizQuestion> questionPool,
    int seed,
  });
}
```

Pure function — no side effects, fully testable.

---

## Grid representation

`grid[y][x]` — row 0 is top, column 0 is left.

Player starts at `(x:0, y:0)` (top-left). Throne Room at max-distance cell.

---

## Fog of war rules
Applied during render, not stored (derived from `RoomStatus`):
- `hidden` → cell not visible to player
- `visible` → cell is adjacent (N/S/E/W) to any visited/answered/skipped cell
- `visited+` → always shown

The `throneDiscovered` flag is set when the throne becomes `visible` (adjacent), revealing its icon on the map.

---

## Validation
After generation, assert:
- All 100 cells are reachable from (0,0) (BFS count == 100)
- Exactly 1 throne room
- Start cell has no question, throne room has no question
- Connection map contains exactly 99 connections (spanning tree: n-1 edges for n=100)

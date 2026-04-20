# Proposal 01: Maze State Model

## Design goals
- Pure Dart domain objects, no Flutter imports
- Immutable with `copyWith`
- No dependency on existing `GameState` (separate concern)
- Reuses `QuizQuestion`, `QuizConfig`, `Question` as-is

---

## Core types

### `MazePosition`
```dart
class MazePosition {
  final int x; // 0–9 column
  final int y; // 0–9 row
}
```

### `DoorState`
```dart
enum DoorState {
  wall,      // no connection between cells
  locked,    // connected but question not yet answered
  open,      // answered correctly
  skipped,   // player passed through without answering
}
```
Doors belong to **connections**, not rooms. A connection is an edge `(pos, direction)`.

### `RoomStatus`
```dart
enum RoomStatus {
  hidden,    // fog of war — not yet visible
  visible,   // adjacent to a visited room, shown on map but not entered
  visited,   // entered; question not answered (or no question)
  answered,  // question answered correctly
  skipped,   // question skipped
}
```

### `MazeRoom`
```dart
class MazeRoom {
  final MazePosition position;
  final String? questionId;       // null if this cell is a plain passage
  final bool isThroneRoom;
  final RoomStatus status;
  final bool? answeredCorrectly;  // null until attempt
}
```

### `MazeStatus`
```dart
enum MazeStatus {
  loading,
  navigating,      // player choosing a direction
  questionActive,  // question sheet open for current room
  answerRevealed,  // after answering, showing fun fact
  complete,        // player reached throne room
  gameOver,        // lives exhausted
}
```

### `MazeState`
```dart
class MazeState {
  // Grid: grid[y][x] — row-major
  final List<List<MazeRoom>> grid;               // 10×10

  // Connections: key = "$x1,$y1-$x2,$y2" (smaller coords first)
  final Map<String, DoorState> connections;

  final MazePosition playerPosition;
  final MazePosition thronePosition;  // used for win detection; hidden on map until discovered
  final bool throneDiscovered;        // true once player enters adjacent cell

  final Map<String, QuizQuestion> questions; // questionId → QuizQuestion

  final int lives;                    // starts at 3
  final MazeStatus status;
  final QuizConfig config;
  final QuizQuestion? activeQuestion; // non-null during questionActive/answerRevealed
  final bool? lastAnswerCorrect;
}
```

---

## Connection key convention
For adjacent positions `a` and `b`, sort by `(y, x)` ascending then join:
`"${a.y},${a.x}-${b.y},${b.x}"` where `a` always < `b`.

---

## State transitions

```
loading
  └─► navigating             (maze generated)

navigating
  ├─► navigating             (move to room with no question / already answered / skipped)
  ├─► questionActive         (enter unvisited room that has a question)
  └─► complete               (enter throne room)

questionActive
  └─► answerRevealed         (player submits answer)

answerRevealed
  └─► navigating             (player taps "Onward!" / "Continue")

navigating (lives == 0)
  └─► gameOver
```

Skipping: player dismisses question sheet without answering → `DoorState.skipped`, `RoomStatus.skipped`, stays `navigating`.

---

## Question assignment
- Generate 10×10 = 100 cells
- Throne Room: no question (win condition room)
- Start cell: no question (entry point)
- Remaining 98 cells each get 1 question, drawn with `selectQuestionsFrom(config)`
- If question pool < 98, questions repeat (shuffle + cycle)

---

## Lives
- Start: 3
- Wrong answer: `lives -= 1`
- If `lives == 0` after wrong answer: transition to `gameOver`
- No life restoration in v1 (XP system out of scope)

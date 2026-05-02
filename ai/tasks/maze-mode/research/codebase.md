# Research: Maze Mode — Codebase Findings

## Key models

### GameState (`lib/features/gameplay/domain/models/game_state.dart`)
Linear progress: `currentQuestionIndex`, `lives` (start 3), `score`, `status`, `streak`.
Status enum: `idle | loading | playing | answerRevealed | gameOver | complete`
All models are immutable with `copyWith`.

### Room (`lib/features/gameplay/domain/models/room.dart`)
Exists but **unused in GameState**. Has `index`, `theme`, `completed`, `answeredCorrectly`.
Safe to repurpose the concept; do not modify this file.

### QuizQuestion (runtime) / Question (source)
Source lives in `assets/questions/topics/{topicId}.json`.
Runtime: 4 shuffled options, `correctIndex`.
`selectQuestionsFrom()` in `question_bank.dart` is reusable as-is.

## State provider
`GameStateNotifier extends Notifier<GameState?>` — `startGame`, `answerQuestion`, `advanceQuestion`.
Maze mode should use a **separate** `MazeStateNotifier` to avoid coupling.

## Routes (lib/app.dart)
GoRouter. Current: `/`, `/mode`, `/game-settings`, `/topics`, `/game`, `/article`, `/results`, `/notebook`, `/settings`, `/how-to-play`, `/feedback`, `/stats`.
Adding `/maze-settings` and `/maze` is straightforward.

## Dependencies relevant to maze
- `flutter_animate: ^4.5.0` — cell animations, reveal effects
- `shared_preferences` — could persist maze seed between sessions (out of scope for v1)
- `maze_builder` — **NOT in pubspec**; owner suggested it but it is optional

## Tests
- `test/features/gameplay/domain/game_state_test.dart` — pure domain unit tests
- `test/question_bank_test.dart` — question selection
- Tests are pure Dart; pattern is `group`/`test`; no mocks needed for domain logic.

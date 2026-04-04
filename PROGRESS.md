# Mind Maze — Progress Tracker

## Current Phase
Phase 4 — Gameplay Screen UI

## Status
🟡 In Progress

## Last Updated
2026-04-04 — Phase 3 complete: WikipediaService, ClaudeQuestionService, prompt template, QuestionNotifier provider, 25 tests passing.

## Phase Completion

| Phase | Title                          | Status      |
|-------|--------------------------------|-------------|
| 1     | Project Scaffold & Theme       | ✅ Complete |
| 2     | Domain Models & Game State     | ✅ Complete |
| 3     | Wikipedia + Claude API         | ✅ Complete |
| 4     | Gameplay Screen UI             | 🔲 Not started |
| 5     | Article Viewer                 | 🔲 Not started |
| 6     | Polish & Game Loop             | 🔲 Not started |

## Notes for Next Agent
- Flutter SDK at `/opt/flutter` — `export PATH="$PATH:/opt/flutter/bin"` + `git config --global --add safe.directory /opt/flutter`
- Project root is `/home/user/Mind-mazeish`
- `.env` must exist locally; copy `.env.example` and add real `ANTHROPIC_API_KEY`
- Service layer complete:
  - `WikipediaService` (`lib/features/gameplay/data/wikipedia_service.dart`)
  - `ClaudeQuestionService` (`lib/features/gameplay/data/claude_question_service.dart`)
  - `QuestionNotifier` provider (`lib/features/gameplay/presentation/providers/question_provider.dart`)
  - Both services accept injectable `http.Client` for test mocking
- Phase 4 tasks:
  - Replace placeholder `GameplayScreen` with full interactive implementation
  - Wire Riverpod providers (gameStateProvider + questionProvider) to the screen
  - `AnswerButton` widget with correct/wrong flash animations (flutter_animate)
  - `QuestionCard` widget (parchment card with Wikipedia source link)
  - `RoomHeader` widget (room name + score)
  - Fun fact bottom sheet after answering
  - Loading skeleton while question is fetching
  - Error state with retry button
  - 500ms delay before advancing room

## Known Issues
- Java 21 / Gradle AGP 8.3 warning — use `flutter analyze` + `flutter test` in this env

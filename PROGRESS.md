# Mind Maze — Progress Tracker

## Current Phase
Phase 3 — Wikipedia + Claude API Integration

## Status
🟡 In Progress

## Last Updated
2026-04-04 — Phase 2 complete: all domain models, room data, GameStateNotifier provider, and 15 unit tests passing.

## Phase Completion

| Phase | Title                          | Status      |
|-------|--------------------------------|-------------|
| 1     | Project Scaffold & Theme       | ✅ Complete |
| 2     | Domain Models & Game State     | ✅ Complete |
| 3     | Wikipedia + Claude API         | 🔲 Not started |
| 4     | Gameplay Screen UI             | 🔲 Not started |
| 5     | Article Viewer                 | 🔲 Not started |
| 6     | Polish & Game Loop             | 🔲 Not started |

## Notes for Next Agent
- Flutter SDK at `/opt/flutter` — `export PATH="$PATH:/opt/flutter/bin"` + `git config --global --add safe.directory /opt/flutter`
- Project root is `/home/user/Mind-mazeish`
- `.env` must exist locally (copy `.env.example`, add real `ANTHROPIC_API_KEY`)
- Domain models: `lib/features/gameplay/domain/models/` — Question, Room, GameState
- Room data: `lib/features/gameplay/data/room_data.dart` (10 rooms, `buildInitialGameState()`)
- Riverpod provider: `lib/features/gameplay/presentation/providers/game_state_provider.dart`
- Phase 3 tasks:
  - `wikipedia_service.dart` — `fetchArticleSummary(topic)` → WikiArticle via Wikipedia REST API
  - `claude_question_service.dart` — `generateQuestion(article)` → Question via Anthropic API
  - `question_prompt_template.dart` — prompt string constant
  - `question_provider.dart` — async Riverpod provider for question fetching
  - Loading state (shimmer/animation while fetching)
  - Integration test with mocked HTTP

## Known Issues
- Java 21 / Gradle AGP 8.3 compatibility warning — no emulator in env; use `flutter analyze` + `flutter test`

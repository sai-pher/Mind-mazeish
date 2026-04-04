# Mind Mazeish — Claude Code Context

## Project overview
Medieval castle trivia game for Android (Flutter). Players answer one trivia
question per room across 10 castle rooms. All questions are hardcoded in
`lib/features/gameplay/data/seeded_questions.dart`.

## Key facts for every session
- **Target device**: Google Pixel 9 (Android 16, API 36), portrait only
- **Min SDK**: 26 (Android 8.0)
- **Flutter**: 3.27.4 stable
- **State management**: Riverpod (`NotifierProvider`, `AsyncNotifierProvider`)
- **Navigation**: GoRouter — routes: `/` start, `/game` gameplay, `/article` WebView, `/results`
- **No external APIs at runtime** — questions are hardcoded; the article viewer
  uses a WebView that the user opens voluntarily (requires internet)

## Directory map
```
lib/
├── core/theme/app_theme.dart        # AppColors + AppTheme (castle palette)
├── core/constants/app_constants.dart
├── features/
│   ├── start/                       # StartScreen
│   ├── gameplay/
│   │   ├── data/
│   │   │   ├── seeded_questions.dart   ← ADD NEW QUESTIONS HERE
│   │   │   └── room_data.dart          ← ADD NEW ROOMS HERE
│   │   ├── domain/models/           # Question, Room, GameState, WikiArticle
│   │   └── presentation/
│   │       ├── screens/gameplay_screen.dart
│   │       ├── widgets/             # AnswerButton, QuestionCard, RoomHeader
│   │       └── providers/           # gameStateProvider, questionProvider
│   ├── article_viewer/              # ArticleScreen (WebView)
│   └── results/                     # ResultsScreen
.claude/
├── generate-questions.md            # /generate-questions skill
└── resources/                       # Reference implementations (not compiled)
    ├── wikipedia_service.dart
    ├── claude_question_service.dart
    └── question_prompt_template.dart
```

## Running checks
```bash
export PATH="$PATH:/opt/flutter/bin"
git config --global --add safe.directory /opt/flutter  # needed when running as root
flutter pub get
flutter analyze --fatal-infos
flutter test --reporter expanded
```

## Available skills
- `/generate-questions` — generate new trivia questions and add them to the game

## Colour palette (AppColors)
| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#1A1208` | Scaffold background |
| `stone` | `#3D3020` | Cards, buttons |
| `parchment` | `#F5E6C8` | Question card background |
| `torchAmber` | `#FF8C00` | Primary accent, progress |
| `torchGold` | `#FFD700` | Correct answer, stars |
| `dangerRed` | `#C0392B` | Wrong answer, lives |
| `textDark` | `#2C1810` | Text on parchment |
| `textLight` | `#F5E6C8` | Text on stone |

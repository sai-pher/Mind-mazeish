# Mind Mazeish — Claude Code Context

## Project overview
Medieval castle trivia game for Android (Flutter). Players answer trivia
questions drawn from a JSON asset. All questions live in
`assets/questions/questions.json`.

## Key facts for every session
- **Target device**: Google Pixel 9 (Android 16, API 36), portrait only
- **Min SDK**: 26 (Android 8.0)
- **Flutter**: 3.41.6 stable
- **State management**: Riverpod (`NotifierProvider`, `AsyncNotifierProvider`)
- **Navigation**: GoRouter — routes: `/` start, `/game` gameplay, `/article` WebView, `/results`
- **No external APIs at runtime** — questions are bundled as a JSON asset; the
  article viewer uses a WebView that the user opens voluntarily (requires internet)

## Directory map
```
assets/
└── questions/
    └── topics/
        ├── coffee.json             ← one file per topicId — ADD / EDIT QUESTIONS HERE
        ├── tennis.json
        └── ...                     # 35 files total, one per topic
lib/
├── core/theme/app_theme.dart        # AppColors + AppTheme (castle palette)
├── core/constants/app_constants.dart
├── features/
│   ├── start/                       # StartScreen, TopicPickerScreen
│   ├── gameplay/
│   │   ├── data/
│   │   │   ├── question_repository.dart  # loads questions.json via rootBundle
│   │   │   ├── question_bank.dart        # selectQuestionsFrom() pure function
│   │   │   └── topic_registry.dart       ← ADD NEW TOPICS HERE
│   │   ├── domain/models/           # Question, Room, GameState, WikiArticle
│   │   └── presentation/
│   │       ├── screens/gameplay_screen.dart
│   │       ├── widgets/             # AnswerButton, QuestionCard, RoomHeader
│   │       └── providers/           # gameStateProvider, questionsProvider
│   ├── article_viewer/              # ArticleScreen (WebView)
│   └── results/                     # ResultsScreen
.claude/
└── generate-questions/              # /generate-questions skill (Agent Skills spec)
    ├── SKILL.md                     # skill entry point
    ├── scripts/
    │   ├── search_wiki.py           # Wikipedia search
    │   ├── fetch_wiki.py            # Wikipedia article fetch
    │   └── requirements.txt         # pip install -r to set up
    └── references/
        └── examples.md              # workflow examples + new-topic guide
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

### Question management
- `generate-questions` — generate new trivia questions and append to a topic JSON file
  - Invoke: `skill: "generate-questions"`
- `audit-questions` — full health report: difficulty spread, thin topics, validation errors
  - Invoke: `skill: "audit-questions"`
- `add-topic` — add a brand-new topic (registry, JSON files, 30 starter questions)
  - Invoke: `skill: "add-topic"`
- `relearn` — extract/verify facts from Wikipedia into sources files
  - Invoke: `skill: "relearn"`
- `research-rabbit` — discover related Wikipedia sources; group into book sets
  - Invoke: `skill: "research-rabbit"`

### Issue management
- `triage-issue` — classify a GitHub issue and post initial understanding comment
  - Invoke: `skill: "triage-issue"`
- `investigate-issue` — trace root cause of a bug; post investigation comment
  - Invoke: `skill: "investigate-issue"`
- `fix-bug` — apply minimal fix, add regression test, open PR
  - Invoke: `skill: "fix-bug"`
- `implement-feature` — implement scoped feature/UI/improvement, open PR
  - Invoke: `skill: "implement-feature"`
- `resolve-issue` — post resolution comment, update labels, close or mark awaiting-merge
  - Invoke: `skill: "resolve-issue"`

### Planning
- `plan-task` — research and plan a new initiative in `ai/tasks/`
  - Invoke: `skill: "plan-task"`

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

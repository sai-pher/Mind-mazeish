# Skill: Generate New Questions for Mind Maze

Use this skill to add new trivia questions to the game — either replacing
existing ones or extending to new rooms. All questions live in one file:
`lib/features/gameplay/data/seeded_questions.dart`.

---

## When to use this skill

- Adding a second "season" of questions (rotate the map with new themes)
- Replacing existing questions that feel too easy or too obscure
- Expanding rooms with multiple difficulty tiers (future feature)

---

## Question schema

Each question maps to a `Question` object defined in
`lib/features/gameplay/domain/models/question.dart`:

```dart
class Question {
  final String question;       // The trivia question text
  final List<String> options;  // Exactly 4 answer choices
  final int correctIndex;      // 0-based index of the correct option
  final String funFact;        // 1–2 sentence educational payoff shown after answer
  final String articleTitle;   // Wikipedia article title (used as link label)
  final String articleUrl;     // Full mobile Wikipedia URL (en.m.wikipedia.org)
}
```

**Rules:**
- `options` must have exactly **4 items**
- `correctIndex` is always a valid index into `options` (0–3)
- The correct answer should not always be index 0 — vary it
- `funFact` must be genuinely interesting and distinct from the question text
- `articleUrl` must use `https://en.m.wikipedia.org/wiki/...` (mobile Wikipedia)
- Question text should be answerable without the article — the article is for enrichment

---

## Current rooms and themes

The game has 10 rooms. Each room has an `id` (the map key in `seeded_questions.dart`)
and a human-readable `name`. Questions must match the room's historical theme.

| Room ID      | Room Name         | Theme / Era                              | Wiki topics in room_data.dart                         |
|--------------|-------------------|------------------------------------------|-------------------------------------------------------|
| entrance     | Castle Gates      | Castle architecture, defences            | Castle, Drawbridge, Portcullis, Moat                  |
| throne       | Throne Room       | Medieval royalty, power, ceremony        | Medieval kingship, Coronation, Feudalism, Magna Carta |
| library      | Library           | Medieval knowledge, manuscripts, science | Scriptorium, Illuminated manuscript, Printing press   |
| dungeon      | Dungeon           | Imprisonment, justice, torture           | Dungeon, Oubliette, Torture devices, Medieval law     |
| chapel       | Chapel            | Religion, architecture, the Church       | Gothic architecture, Crusades, Pope, Flying buttress  |
| armory       | Armoury           | Weapons, armour, knighthood              | Knight, Plate armour, Sword, Siege warfare            |
| kitchen      | Great Kitchen     | Food, trade, daily castle life           | Medieval cuisine, Spice trade, Feast, Herb garden     |
| observatory  | Observatory Tower | Astronomy, natural philosophy            | Copernicus, Astrolabe, Alchemy, Medieval cosmology    |
| garden       | Castle Garden     | Herbalism, alchemy, medicine             | Alchemy, Herb, Plague, Apothecary                     |
| tower        | Watch Tower       | Siege warfare, military engineering      | Trebuchet, Siege, Ballista, Castle walls              |

---

## Step-by-step: generating a new question set

### Step 1 — Research the topic

For each room you want to update, pick a Wikipedia article that is:
- Historically accurate and well-sourced
- Surprising or counter-intuitive (the best trivia)
- Distinct from the current question (don't repeat drawbridge → coronation etc.)

Good sources for medieval trivia:
- https://en.wikipedia.org/wiki/History_of_medieval_warfare
- https://en.wikipedia.org/wiki/Medieval_castle
- https://en.wikipedia.org/wiki/Daily_life_in_medieval_England

### Step 2 — Prompt Claude to draft a question

Paste this prompt into a Claude conversation, substituting `[TOPIC]` and `[ARTICLE_URL]`:

```
You are writing trivia questions for "Mind Maze", a medieval castle quiz game.

Room theme: [ROOM_NAME] — focuses on [THEME_DESCRIPTION]
Wikipedia article: [ARTICLE_URL]

Write one trivia question following these rules:
1. The question tests genuine historical knowledge about [TOPIC]
2. It has exactly 4 answer options (labelled A–D)
3. Exactly one option is correct
4. The correct answer should be at a random index (not always A)
5. Include a fun fact (1–2 sentences) that reveals something surprising — ideally a detail NOT in the question
6. Keep question text under 120 characters; each option under 60 characters

Output as valid Dart code in this exact format:
  '[ROOM_ID]': Question(
    question: '...',
    options: [
      '...',
      '...',
      '...',
      '...',
    ],
    correctIndex: N,
    funFact: '...',
    articleTitle: '...',
    articleUrl: 'https://en.m.wikipedia.org/wiki/...',
  ),
```

### Step 3 — Validate the output

Before pasting into the source file, verify:
- [ ] `options` has exactly 4 strings
- [ ] `correctIndex` matches the correct answer (count from 0)
- [ ] `articleUrl` loads correctly in a browser
- [ ] No escaped single quotes inside single-quoted Dart strings (use `\'` or switch to double quotes)
- [ ] `funFact` does not just restate the question

### Step 4 — Insert into seeded_questions.dart

Replace the existing entry for that room ID in
`lib/features/gameplay/data/seeded_questions.dart`.

The file structure is:
```dart
const Map<String, Question> seededQuestions = {
  'entrance': Question( ... ),
  'throne':   Question( ... ),
  // ... one entry per room ID
};
```

Replace only the `Question(...)` value for the room(s) you are updating.
The map key (room ID) must stay the same.

### Step 5 — Run checks

```bash
flutter analyze --fatal-infos
flutter test
```

Both must pass before committing.

---

## Example: full replacement question (throne room)

```dart
  'throne': Question(
    question: 'Which document, forced on King John in 1215, first limited English royal power?',
    options: [
      'Magna Carta',
      'The Domesday Book',
      'The Assize of Clarendon',
      'The Provisions of Oxford',
    ],
    correctIndex: 0,
    funFact:
        'Magna Carta\'s most famous clause — habeas corpus — was not actually in the original 1215 version; it was added in later reissues.',
    articleTitle: 'Magna Carta',
    articleUrl: 'https://en.m.wikipedia.org/wiki/Magna_Carta',
  ),
```

---

## Adding a new room (future expansion)

If you add new rooms to the game, you must update **both** files:

1. `lib/features/gameplay/data/room_data.dart` — add a `RoomTheme` entry to the list
2. `lib/features/gameplay/data/seeded_questions.dart` — add a matching map entry

The room ID in both files must match exactly. Room order in `room_data.dart`
determines the play order.

---

## Reference files (in `.claude/resources/`)

The following files were removed from the active codebase but are preserved
as reference for anyone wanting to restore API-powered question generation:

| File | Description |
|------|-------------|
| `wikipedia_service.dart` | Fetches a random Wikipedia article summary for a given topic via the Wikipedia REST API |
| `claude_question_service.dart` | Calls the Anthropic Messages API to generate a `Question` from a Wikipedia excerpt |
| `question_prompt_template.dart` | The system + user prompt sent to Claude — edit this to tune question style |

To restore API mode, you would:
1. Add `http: ^1.2.1` and `flutter_dotenv: ^5.1.0` back to `pubspec.yaml`
2. Move the three files from `.claude/resources/` back to `lib/features/gameplay/data/`
3. Add `ANTHROPIC_API_KEY=sk-ant-...` to a `.env` file (gitignored)
4. Restore the `QuestionMode` enum in `question_provider.dart` and wire up
   `WikipediaService` → `ClaudeQuestionService` → `questionProvider`

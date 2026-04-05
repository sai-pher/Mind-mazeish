# Skill: Generate New Questions for Mind Maze

Use this skill to add new trivia questions to the game. All questions live in
a single JSON asset file: `assets/questions/questions.json`.

---

## When to use this skill

- Adding questions for new topics
- Expanding existing topics with more questions
- Replacing questions that feel too easy or too obscure

---

## Question schema

Each question in `assets/questions/questions.json` is a JSON object:

```json
{
  "id": "unique_id_001",
  "question": "The trivia question text?",
  "correctAnswers": ["The correct answer"],
  "wrongAnswers": ["Wrong 1", "Wrong 2", "Wrong 3", "Wrong 4"],
  "funFact": "1–2 sentence educational payoff shown after the player answers.",
  "articleTitle": "Wikipedia article title",
  "articleUrl": "https://en.m.wikipedia.org/wiki/Article_Title",
  "topicId": "topic_id_from_topic_registry",
  "difficulty": "easy"
}
```

**Field rules:**
- `id` — unique, snake_case, e.g. `coffee_006`. Never reuse an ID.
- `correctAnswers` — 1–3 correct answers (all are equally valid; the game picks one at random per round)
- `wrongAnswers` — **minimum 4**, up to 10. The game always picks exactly 3 wrong answers per round.
- `difficulty` — one of `"easy"`, `"medium"`, `"hard"`
- `articleUrl` — must use `https://en.m.wikipedia.org/wiki/...` (mobile Wikipedia)
- `topicId` — must match an existing ID in `lib/features/gameplay/data/topic_registry.dart`

---

## Adding new questions (existing topic)

1. Open `assets/questions/questions.json`
2. Find the section for the topic you want (search for `"topicId": "your_topic"`)
3. Append a new JSON object to the array
4. Ensure the `id` is unique

---

## Adding a new topic

1. **Register the topic** in `lib/features/gameplay/data/topic_registry.dart`:
   - Add a `Topic` entry under the appropriate `TopicCategory` / `SuperCategory`
   - The `Topic.id` becomes the `topicId` used in question JSON

2. **Add questions** to `assets/questions/questions.json` for that `topicId`

No Dart code changes needed for the questions themselves — only the topic registry update and the JSON additions are required.

---

## Step-by-step: generating questions

### Step 1 — Pick a topic and research it

Find a Wikipedia article that is:
- Genuinely interesting and well-sourced
- Surprising or counter-intuitive (the best trivia)

### Step 2 — Prompt Claude to draft questions

Use this prompt, substituting `[TOPIC]` and `[ARTICLE_URL]`:

```
Write 3 trivia questions for the Mind Maze game about [TOPIC].
Reference article: [ARTICLE_URL]

Rules:
1. Each question must have 1 correct answer and at least 4 wrong answers
2. Wrong answers must be plausible (same category, similar scope)
3. Include a fun fact (1–2 sentences) distinct from the question text
4. Keep question text under 150 characters; each answer under 80 characters
5. Mix difficulties: one easy, one medium, one hard

Output as a JSON array ready to paste into questions.json:
[
  {
    "id": "[TOPIC_ID]_XXX",
    "question": "...",
    "correctAnswers": ["..."],
    "wrongAnswers": ["...", "...", "...", "..."],
    "funFact": "...",
    "articleTitle": "...",
    "articleUrl": "https://en.m.wikipedia.org/wiki/...",
    "topicId": "[TOPIC_ID]",
    "difficulty": "easy|medium|hard"
  }
]
```

### Step 3 — Validate before inserting

- [ ] `wrongAnswers` has at least 4 items
- [ ] `id` is unique across the whole file
- [ ] `topicId` matches a value in `topic_registry.dart`
- [ ] `articleUrl` uses the mobile Wikipedia domain
- [ ] `funFact` does not restate the question

### Step 4 — Insert into questions.json

Paste the new objects into `assets/questions/questions.json`.
The file is a flat JSON array — add entries anywhere; order does not matter.

### Step 5 — Run checks

```bash
export PATH="$PATH:/opt/flutter/bin"
git config --global --add safe.directory /opt/flutter
flutter analyze --fatal-infos
flutter test
```

Both must pass before committing.

---

## Example question

```json
{
  "id": "coffee_006",
  "question": "Which country invented the drip coffee maker?",
  "correctAnswers": ["Germany"],
  "wrongAnswers": ["France", "Italy", "United States", "Sweden", "Netherlands"],
  "funFact": "Melitta Bentz, a German housewife, patented the first paper filter drip coffee maker in 1908 after poking holes in a tin can and using blotting paper from her son's schoolbook.",
  "articleTitle": "Drip coffee maker",
  "articleUrl": "https://en.m.wikipedia.org/wiki/Drip_coffee_maker",
  "topicId": "coffee",
  "difficulty": "medium"
}
```

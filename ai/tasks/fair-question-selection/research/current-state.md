# Research: Current State of Question Selection & Variety

## Current algorithm (`question_bank.dart:selectQuestionsFrom`)

```dart
final pool = allQuestions
    .where((q) => topicIds.contains(q.topicId))
    .toList()
  ..shuffle();
final selected = pool.take(count).toList();
return selected.map((q) => q.toQuizQuestion()).toList();
```

**The bug:** Questions from all topics are merged into one flat pool and shuffled together.
Probability of any question being selected = 1/totalQuestions.
A topic with 25 questions is ~8× more likely to fill a slot than a topic with 3 questions.

**Concrete example from the report:**
- crocheting: 3 questions → 3/28 = 10.7% chance per slot
- west_african_history: 25 questions → 25/28 = 89.3% chance per slot
- With 5 slots, expected WAH questions: 4.46 — so all-WAH result is highly probable

---

## Topic question counts (as of 2026-04-14)

| Count | Topics |
|-------|--------|
| 2 | physical_geography |
| 3 | bridges, candy, chemical_engineering, crocheting, deep_sea, footwear, handheld_devices, mechanical_engineering, perfumes, plastics, water_bodies |
| 4 | adhd, coffee_brewing, countries, pharmaceutical_drugs, recreational_drugs, therapy |
| 5 | coffee, medieval_history, puzzles, theology |
| 10 | socks |
| 11 | anatomy, lily_mayne, medicine |
| 12 | french_literature |
| 13 | agatha_christie, autism, human_geography |
| 14 | dictionaries |
| 15 | linguistics |
| 25 | west_african_history |
| 33 | rocks |
| 36 | tennis |
| 40 | software_architecture |

**Range:** 2–40 questions. 20× spread between smallest and largest.

---

## Existing randomization points (already working well)

### 1. `question_bank.dart` — pool shuffle
Pool is shuffled before `take(count)`. This handles question order randomness but is topic-unfair.

### 2. `question.dart:toQuizQuestion()` — answer option randomization
Each play through a question:
- Randomly picks 1 from 1–3 correct answers
- Randomly picks 3 from 4–12 wrong answers
- Shuffles all 4 options

**Result:** The same question can present differently on each encounter — different correct answer wording, different wrong answers, different option positions.

### 3. `question_bank.dart` — full pool shuffle for question ordering
After selection, question order is already random.

---

## All places variety can be introduced

| Layer | What varies | Current state | Opportunity |
|-------|-------------|---------------|-------------|
| **Topic sampling** | Which topics contribute questions | Flat pool (unfair) | Fair per-topic sampling |
| **Question ordering** | Sequence questions appear in-game | Random (but topic-clustered possible) | Interleaved topic ordering |
| **Answer options** | Which correct answer shown, which 3 wrongs, option positions | ✅ Already random per play | No change needed |
| **Difficulty sequence** | easy→hard or random ordering | Not implemented | Could ramp or randomize |
| **Topic interleaving** | Whether questions alternate topics | Not guaranteed | Round-robin interleaving |

---

## Data flow for a game session

```
QuizConfig (selectedTopicIds, questionCount, gameMode)
    ↓
loadQuestionsForTopics()        ← loads raw Question objects from JSON assets
    ↓
selectQuestionsFrom()           ← THE BROKEN STEP
    ↓
Question.toQuizQuestion()       ← already randomizes answer options
    ↓
GameState.initial()
    ↓
GameState.currentQuestion       ← drives gameplay screen
```

---

## Key constraints

- No runtime network calls — all questions are bundled JSON assets
- `loadQuestionsForTopics` returns a `List<Question>` (not a stream)
- `selectQuestionsFrom` is a pure function — easy to test
- Endless mode uses `pool.length` as count — the fix must still work for this
- `toQuizQuestion` is called once per question, at selection time (not re-rolled at display time)

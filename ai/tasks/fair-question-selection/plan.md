# Plan: Fair Question Selection + Difficulty Bias (Issue #44)

## Context
When a player selects topics with very different question counts, the current flat-pool
shuffle causes the larger topic to dominate — all questions can come from one topic.
This plan fixes that with a round-robin interleaved selection algorithm that gives each
topic an equal expected contribution. It also adds a 1–5 difficulty bias scale so players
can tune how hard their questions are, plus a visual difficulty badge on each question card.

---

## Root Cause

`selectQuestionsFrom` in `question_bank.dart` merges all topic questions into one list,
shuffles, and takes the first N. Each question has equal probability `1/total`, so a
25-question topic is ~8× more likely to fill a slot than a 3-question topic. Difficulty
is ignored entirely.

---

## Feature 1 — Round-Robin Topic Sampling (fairness fix)

1. Group loaded questions by topic into independent buckets.
2. Apply weighted shuffle within each bucket (see Feature 2 — same step).
3. Shuffle the topic list itself (randomizes which topic fills round-1 slots).
4. Cycle through topics picking one question per topic per round until `count` reached or all buckets exhausted.
5. Final `shuffle()` on selected list — breaks visible interleaving pattern.
6. Map each `Question` → `QuizQuestion` via `toQuizQuestion()`.

**Properties:**
- Each topic fills at most `ceil(count / numTopics)` slots per pass
- No hard minimums — a topic that runs dry is skipped
- Endless mode (`count = pool.length`): round-robin completes all rounds, selecting everything
- Pure function — easy to unit test

---

## Feature 2 — Difficulty Bias Scale (1–5)

Add `difficultyBias: int` (default 3) to `QuizConfig`.

### Weight table

| difficultyBias | easy | medium | hard | Player experience |
|---------------|------|--------|------|-----------------|
| 1 | 5 | 2 | 0 | Almost all easy, no hard |
| 2 | 3 | 2 | 1 | Mostly easy |
| 3 | 1 | 1 | 1 | Balanced (default) |
| 4 | 1 | 2 | 3 | Mostly hard |
| 5 | 0 | 2 | 5 | Almost all hard, no easy |

### Implementation: weighted shuffle within each topic bucket

```dart
List<Question> _weightedShuffle(List<Question> bucket, int bias, Random rng) {
  if (bias == 3) return bucket..shuffle(rng); // uniform — plain shuffle
  final expanded = bucket
      .expand((q) => List.filled(_difficultyWeight(q, bias), q))
      .toList()..shuffle(rng);
  final seen = <String>{};
  return [for (final q in expanded) if (seen.add(q.id)) q];
}
```

Each topic bucket is weighted-shuffled before the round-robin loop, so high-weight
questions appear earlier in their bucket and are more likely to be picked in early rounds.

---

## Feature 3 — Visual Difficulty Cue on Question Card

### Emoji + colour mapping

| Difficulty | Emoji | Colour | Token |
|------------|-------|--------|-------|
| easy | 🕯️ | `#FFD700` | `AppColors.torchGold` |
| medium | 🔥 | `#FF8C00` | `AppColors.torchAmber` |
| hard | ⚔️ | `#C0392B` | `AppColors.dangerRed` |

### Badge design

Pill-shaped chip in the **bottom-left of the question card**, below the question text.
Background: colour at 15% opacity. Border: colour at 45% opacity. Matches existing book-icon style.

### Difficulty selector in `_BottomBar` (topic picker)

Five tappable chips (1–5) with `🕯️ Easier` ← → `⚔️ Harder` labels.
Active chip fills with the corresponding difficulty colour.
Chips sit between the question-count row and the Start button.

---

## Variety Opportunities (all layers — updated)

| Layer | Status | Notes |
|-------|--------|-------|
| Topic sampling | **Fix in this task** | Round-robin replaces flat pool |
| Question ordering | **Fixed as side-effect** | Final shuffle + interleaved selection |
| Topic order in each round | **Fixed as side-effect** | Topic list shuffled before cycling |
| Difficulty weighting | **New in this task** | `difficultyBias` 1–5 controls easy/hard mix |
| Answer options (correct pick, wrong picks, button positions) | Already working | `toQuizQuestion()` randomizes independently |

---

## Order of Operations

1. **`quiz_config.dart`** — add `difficultyBias` field (int, default 3)
2. **`question_bank.dart`** — rewrite `selectQuestionsFrom`:
   - Add `difficultyBias` parameter
   - Add `_difficultyWeight()` helper
   - Add `_weightedShuffle()` helper
   - Implement round-robin loop
3. **`game_state_provider.dart`** — pass `config.difficultyBias` into `selectQuestionsFrom`
4. **`question.dart`** — add `difficultyDisplay` getter to `QuizQuestion`
5. **`question_card.dart`** — add `_DifficultyBadge` widget; update `QuestionCard.build`
6. **`topic_picker_screen.dart`** — add `_difficultyBias` state; update `_BottomBar` with chips row; pass value through `_startGame` into `QuizConfig`
7. **`question_bank_test.dart`** — write/update unit tests
8. Run `flutter analyze --fatal-infos` and `flutter test`
9. Commit

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `lib/features/gameplay/domain/models/quiz_config.dart` | Add `difficultyBias` field + copyWith |
| `lib/features/gameplay/data/question_bank.dart` | Rewrite `selectQuestionsFrom` with round-robin + weighted shuffle |
| `lib/features/gameplay/presentation/providers/game_state_provider.dart` | Pass `config.difficultyBias` to `selectQuestionsFrom` |
| `lib/features/gameplay/domain/models/question.dart` | Add `difficultyDisplay` getter to `QuizQuestion` |
| `lib/features/gameplay/presentation/widgets/question_card.dart` | Add `_DifficultyBadge`; update `QuestionCard` layout |
| `lib/features/start/presentation/screens/topic_picker_screen.dart` | Add difficulty chips to `_BottomBar`; wire state |
| `test/question_bank_test.dart` | Create with fairness, weighting, and edge-case tests |

---

## Verification

```bash
# Static analysis
flutter analyze --fatal-infos

# Unit tests
flutter test test/question_bank_test.dart --reporter expanded

# Manual checks:
# 1. Select Crocheting + West African History, bias=3, 5 questions
#    → Both topics should appear across multiple playthroughs
# 2. Set bias=1 → questions should feel noticeably easier
# 3. Set bias=5 → questions should feel noticeably harder
# 4. Each question card shows a coloured emoji badge (🕯️/🔥/⚔️)
# 5. Difficulty chips in topic picker highlight the selected value with the correct colour
```

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Single topic selected | All questions from that topic, weighted-shuffled |
| count > total questions | All questions returned (endless mode) |
| Topic file missing | Empty bucket, skipped silently |
| Topic has only easy questions, bias=5 | Weight=0 for easy, weight=2 for medium — no medium questions either → topic skipped in weighted shuffle → filled by other topics |
| bias=3 | Uniform weights → plain shuffle → identical to old algorithm (but topic-fair) |
| All topics same size | Identical fairness to flat shuffle, just interleaved |

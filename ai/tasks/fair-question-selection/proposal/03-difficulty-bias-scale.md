# Proposal 03: Difficulty Bias Scale (1–5)

## Goal
Add a `difficultyBias` setting (1–5) to `QuizConfig` that controls how the question
selection algorithm weights questions by difficulty. 1 = skewed toward easy,
3 = balanced, 5 = skewed toward hard. No hard filter — all difficulties can appear,
just with different probability.

---

## Current difficulty model

`QuestionDifficulty` is an enum in `question.dart`: `easy | medium | hard`.
Questions carry this field in their JSON. The selection layer ignores it entirely.

---

## Weight table

| difficultyBias | easy | medium | hard | Feels like |
|---------------|------|--------|------|-----------|
| 1 | 5 | 2 | 0 | Almost all easy, rare medium, no hard |
| 2 | 3 | 2 | 1 | Mostly easy, some medium, occasional hard |
| 3 | 1 | 1 | 1 | Equal probability — current default behaviour |
| 4 | 1 | 2 | 3 | Mostly hard, some medium, occasional easy |
| 5 | 0 | 2 | 5 | Almost all hard, rare medium, no easy |

Weight `0` means that difficulty is excluded from the pool, not just deprioritised.
Topics with only easy questions still contribute questions at bias=5 (medium weight=2 is their fallback).

---

## Implementation: weighted shuffle within each topic bucket

After each topic bucket is populated (before round-robin), apply a weighted in-place reorder:

```dart
/// Returns the selection weight for [q] given [bias] (1–5).
int _difficultyWeight(Question q, int bias) {
  final weights = switch (bias) {
    1 => (easy: 5, medium: 2, hard: 0),
    2 => (easy: 3, medium: 2, hard: 1),
    4 => (easy: 1, medium: 2, hard: 3),
    5 => (easy: 0, medium: 2, hard: 5),
    _ => (easy: 1, medium: 1, hard: 1), // bias == 3 (default)
  };
  return switch (q.difficulty) {
    QuestionDifficulty.easy   => weights.easy,
    QuestionDifficulty.medium => weights.medium,
    QuestionDifficulty.hard   => weights.hard,
  };
}

/// Weighted shuffle: each question is repeated by its weight, the expanded
/// list is shuffled, then deduplicated. The result is a bucket where
/// high-weight questions are more likely to appear in early positions.
List<Question> _weightedShuffle(List<Question> bucket, int bias, Random rng) {
  if (bias == 3) {
    // Uniform weights — plain shuffle is equivalent and cheaper.
    return bucket..shuffle(rng);
  }
  final expanded = bucket
      .expand((q) => List.filled(_difficultyWeight(q, bias), q))
      .toList()
    ..shuffle(rng);
  final seen = <String>{};
  return [for (final q in expanded) if (seen.add(q.id)) q];
}
```

This approach:
- Requires no change to `Question` or `QuizQuestion` models
- Works cleanly with the round-robin loop — the bucket is just reordered
- Gracefully handles topics with only one or two difficulty levels
- Is O(n × maxWeight) space — worst case O(5n) which is fine for small topic sizes

---

## QuizConfig changes

```dart
class QuizConfig {
  final Set<String> selectedTopicIds;
  final int questionCount;
  final GameMode gameMode;
  final int difficultyBias; // 1–5, default 3

  const QuizConfig({
    required this.selectedTopicIds,
    required this.questionCount,
    this.gameMode = GameMode.standard,
    this.difficultyBias = 3,
  });

  QuizConfig copyWith({
    Set<String>? selectedTopicIds,
    int? questionCount,
    GameMode? gameMode,
    int? difficultyBias,
  }) => QuizConfig(
    selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
    questionCount: questionCount ?? this.questionCount,
    gameMode: gameMode ?? this.gameMode,
    difficultyBias: difficultyBias ?? this.difficultyBias,
  );
}
```

---

## Updated `selectQuestionsFrom` signature

```dart
List<QuizQuestion> selectQuestionsFrom(
  List<Question> allQuestions, {
  required Set<String> topicIds,
  required int count,
  int difficultyBias = 3,   // ← new parameter
  Random? rng,
})
```

The `GameStateNotifier.startGame` call passes `config.difficultyBias`.

---

## Edge cases

| Scenario | Behaviour |
|----------|-----------|
| Topic has only easy questions, bias=5 | easy weight=0, medium weight=2 but none exist → no questions from this topic in that round |
| Topic has only easy questions, bias=4 | easy weight=1, contributes normally just less likely |
| bias=3 | No weighted expansion — plain shuffle, same as before fix |
| All topics have no hard questions, bias=5 | medium fallback (weight=2) provides all questions |
| Endless mode, bias=1 | All questions selected; weighted shuffle still reorders for gameplay variety |

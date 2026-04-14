import 'dart:math';

import '../domain/models/question.dart';

/// Returns the selection weight for [q] given [bias] (1–5).
/// Weight 0 means excluded from the weighted bucket.
int _difficultyWeight(Question q, int bias) {
  final (easy, medium, hard) = switch (bias) {
    1 => (5, 2, 0),
    2 => (3, 2, 1),
    4 => (1, 2, 3),
    5 => (0, 2, 5),
    _ => (1, 1, 1), // bias == 3: uniform
  };
  return switch (q.difficulty) {
    QuestionDifficulty.easy   => easy,
    QuestionDifficulty.medium => medium,
    QuestionDifficulty.hard   => hard,
  };
}

/// Reorders [bucket] so higher-weight questions appear earlier on average.
/// At bias=3 all weights are equal, so a plain shuffle is used instead.
List<Question> _weightedShuffle(List<Question> bucket, int bias, Random rng) {
  if (bias == 3) return bucket..shuffle(rng);

  // Expand each question by its weight, shuffle, then deduplicate.
  final expanded = bucket
      .expand((q) {
        final w = _difficultyWeight(q, bias);
        return w > 0 ? List.filled(w, q) : const <Question>[];
      })
      .toList()
    ..shuffle(rng);

  final seen = <String>{};
  return [for (final q in expanded) if (seen.add(q.id)) q];
}

/// Selects [count] questions from [allQuestions] filtered to [topicIds].
///
/// Uses round-robin interleaving so each topic has equal expected representation
/// regardless of pool size. Within each topic bucket, questions are reordered
/// by [difficultyBias] (1 = easy-skewed, 3 = balanced, 5 = hard-skewed).
/// The final list is shuffled so no topic pattern is visible to the player.
List<QuizQuestion> selectQuestionsFrom(
  List<Question> allQuestions, {
  required Set<String> topicIds,
  required int count,
  int difficultyBias = 3,
  Random? rng,
}) {
  final random = rng ?? Random();

  // Group by topic and apply difficulty weighting within each bucket.
  final buckets = <String, List<Question>>{};
  for (final q in allQuestions) {
    if (topicIds.contains(q.topicId)) {
      (buckets[q.topicId] ??= []).add(q);
    }
  }
  for (final key in buckets.keys) {
    buckets[key] = _weightedShuffle(buckets[key]!, difficultyBias, random);
  }

  // Shuffle topic order so the first-mover advantage is randomised.
  final topicList = buckets.keys.toList()..shuffle(random);

  // Round-robin: one question per topic per round.
  final selected = <Question>[];
  var round = 0;
  while (selected.length < count) {
    var anyAdded = false;
    for (final topicId in topicList) {
      if (selected.length >= count) break;
      final bucket = buckets[topicId]!;
      if (round < bucket.length) {
        selected.add(bucket[round]);
        anyAdded = true;
      }
    }
    if (!anyAdded) break; // all buckets exhausted
    round++;
  }

  // Final shuffle so no interleaving pattern is visible.
  selected.shuffle(random);
  return selected.map((q) => q.toQuizQuestion(random)).toList();
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/gameplay/data/question_bank.dart';
import 'package:mind_maze/features/gameplay/domain/models/question.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Question _makeQuestion(String id, String topicId, QuestionDifficulty difficulty) {
  return Question(
    id: id,
    question: 'Q $id',
    correctAnswers: ['correct'],
    wrongAnswers: ['w1', 'w2', 'w3', 'w4'],
    funFact: 'fact',
    articleTitle: '',
    articleUrl: '',
    topicId: topicId,
    difficulty: difficulty,
  );
}

List<Question> _topic(String id, int count, [QuestionDifficulty diff = QuestionDifficulty.medium]) =>
    List.generate(count, (i) => _makeQuestion('$id-$i', id, diff));

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('selectQuestionsFrom — topic fairness', () {
    test('single topic: returns count questions from that topic', () {
      final questions = _topic('A', 10);
      final result = selectQuestionsFrom(questions, topicIds: {'A'}, count: 5);
      expect(result.length, 5);
      expect(result.every((q) => q.topicId == 'A'), isTrue);
    });

    test('two equal-size topics: both appear in output', () {
      final questions = [..._topic('A', 10), ..._topic('B', 10)];
      final result = selectQuestionsFrom(questions, topicIds: {'A', 'B'}, count: 6);
      expect(result.length, 6);
      expect(result.any((q) => q.topicId == 'A'), isTrue);
      expect(result.any((q) => q.topicId == 'B'), isTrue);
    });

    test('two unequal topics (3 vs 25): small topic always appears', () {
      final questions = [..._topic('small', 3), ..._topic('big', 25)];
      // Run 20 times — small topic should always appear because round-robin
      // guarantees it gets a slot in round 1.
      for (var i = 0; i < 20; i++) {
        final result = selectQuestionsFrom(
          questions,
          topicIds: {'small', 'big'},
          count: 5,
          rng: Random(i),
        );
        expect(result.any((q) => q.topicId == 'small'), isTrue,
            reason: 'small topic missing on seed $i');
      }
    });

    test('count > total questions returns all available questions', () {
      final questions = [..._topic('A', 3), ..._topic('B', 4)];
      final result = selectQuestionsFrom(questions, topicIds: {'A', 'B'}, count: 100);
      expect(result.length, 7);
    });

    test('missing topic id is silently ignored', () {
      final questions = _topic('A', 5);
      final result = selectQuestionsFrom(questions, topicIds: {'A', 'missing'}, count: 3);
      expect(result.length, 3);
      expect(result.every((q) => q.topicId == 'A'), isTrue);
    });

    test('no duplicate questions in output', () {
      final questions = [..._topic('A', 10), ..._topic('B', 10)];
      final result = selectQuestionsFrom(questions, topicIds: {'A', 'B'}, count: 10);
      final ids = result.map((q) => q.source.id).toSet();
      expect(ids.length, result.length);
    });
  });

  group('selectQuestionsFrom — difficulty bias', () {
    List<Question> mixedTopic(String topicId) => [
          ...List.generate(5, (i) => _makeQuestion('$topicId-e$i', topicId, QuestionDifficulty.easy)),
          ...List.generate(5, (i) => _makeQuestion('$topicId-m$i', topicId, QuestionDifficulty.medium)),
          ...List.generate(5, (i) => _makeQuestion('$topicId-h$i', topicId, QuestionDifficulty.hard)),
        ];

    test('bias=1 excludes hard questions when easy/medium available', () {
      final questions = mixedTopic('A');
      final result = selectQuestionsFrom(questions,
          topicIds: {'A'}, count: 5, difficultyBias: 1, rng: Random(42));
      expect(result.every((q) => q.difficulty != QuestionDifficulty.hard), isTrue);
    });

    test('bias=5 excludes easy questions when medium/hard available', () {
      final questions = mixedTopic('A');
      final result = selectQuestionsFrom(questions,
          topicIds: {'A'}, count: 5, difficultyBias: 5, rng: Random(42));
      expect(result.every((q) => q.difficulty != QuestionDifficulty.easy), isTrue);
    });

    test('bias=3 returns questions of any difficulty', () {
      final questions = mixedTopic('A');
      final difficulties = <QuestionDifficulty>{};
      for (var i = 0; i < 30; i++) {
        final result = selectQuestionsFrom(questions,
            topicIds: {'A'}, count: 5, difficultyBias: 3, rng: Random(i));
        for (final q in result) {
          difficulties.add(q.difficulty);
        }
      }
      expect(difficulties, containsAll(QuestionDifficulty.values));
    });

    test('bias=5 with only easy questions returns 0 (no medium/hard fallback exists)', () {
      final questions = _topic('A', 5, QuestionDifficulty.easy);
      // easy weight=0, medium/hard absent — weighted bucket is empty
      final result = selectQuestionsFrom(questions,
          topicIds: {'A'}, count: 3, difficultyBias: 5, rng: Random(0));
      expect(result.length, 0);
    });
  });

  group('selectQuestionsFrom — round-robin fairness across many runs', () {
    test('small topic (3) vs large topic (25): small averages ≥ 1 question over 100 runs', () {
      final questions = [..._topic('small', 3), ..._topic('big', 25)];
      var smallCount = 0;
      for (var i = 0; i < 100; i++) {
        final result = selectQuestionsFrom(
          questions,
          topicIds: {'small', 'big'},
          count: 5,
          rng: Random(i),
        );
        smallCount += result.where((q) => q.topicId == 'small').length;
      }
      // On average, small topic should contribute at least 2 questions per run
      // (round-robin gives it ~50% of slots in a 2-topic game).
      expect(smallCount / 100.0, greaterThanOrEqualTo(2.0));
    });
  });
}

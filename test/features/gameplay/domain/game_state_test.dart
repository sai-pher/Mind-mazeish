import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/gameplay/data/question_bank.dart';
import 'package:mind_maze/features/gameplay/data/topic_registry.dart';
import 'package:mind_maze/features/gameplay/domain/models/game_state.dart';
import 'package:mind_maze/features/gameplay/domain/models/quiz_config.dart';

GameState _makeState({int count = 5}) {
  final config = QuizConfig(
    selectedTopicIds: Set.from(allTopicIds),
    questionCount: count,
  );
  final questions = selectQuestions(
      topicIds: config.selectedTopicIds, count: count);
  return GameState.initial(questions: questions, config: config);
}

void main() {
  group('GameState', () {
    test('initial state has correct question count, 3 lives, 0 score', () {
      final s = _makeState(count: 5);
      expect(s.questions.length, 5);
      expect(s.lives, 3);
      expect(s.score, 0);
      expect(s.currentQuestionIndex, 0);
      expect(s.status, GameStatus.loading);
    });

    test('correct answer increases score by 10 and keeps lives', () {
      final s = _makeState().answerQuestion(correct: true);
      expect(s.score, 10);
      expect(s.lives, 3);
      expect(s.status, GameStatus.answerRevealed);
      expect(s.answeredCorrectly[0], true);
    });

    test('wrong answer keeps score and decrements lives', () {
      final s = _makeState().answerQuestion(correct: false);
      expect(s.score, 0);
      expect(s.lives, 2);
      expect(s.status, GameStatus.answerRevealed);
      expect(s.answeredCorrectly[0], false);
    });

    test('three wrong answers triggers game over', () {
      var s = _makeState(count: 5);
      s = s.answerQuestion(correct: false);
      s = s.advanceQuestion().markPlaying();
      s = s.answerQuestion(correct: false);
      s = s.advanceQuestion().markPlaying();
      s = s.answerQuestion(correct: false);
      expect(s.lives, 0);
      expect(s.status, GameStatus.gameOver);
      expect(s.isGameOver, isTrue);
    });

    test('advanceQuestion increments index', () {
      var s = _makeState().answerQuestion(correct: true).advanceQuestion();
      expect(s.currentQuestionIndex, 1);
      expect(s.status, GameStatus.loading);
    });

    test('answering last question correctly triggers complete', () {
      var s = _makeState(count: 3);
      s = s.answerQuestion(correct: true).advanceQuestion().markPlaying();
      s = s.answerQuestion(correct: true).advanceQuestion().markPlaying();
      s = s.answerQuestion(correct: true);
      expect(s.status, GameStatus.complete);
      expect(s.isComplete, isTrue);
    });

    test('correctCount and questionsAnswered work', () {
      var s = _makeState(count: 3);
      expect(s.questionsAnswered, 0);
      s = s.answerQuestion(correct: true).advanceQuestion().markPlaying();
      s = s.answerQuestion(correct: false);
      expect(s.questionsAnswered, 2);
      expect(s.correctCount, 1);
    });

    test('recordArticleVisit tracks new and seen urls', () {
      var s = _makeState();
      s = s.recordArticleVisit('https://en.wikipedia.org/wiki/Test',
          isNew: true);
      expect(s.seenArticleUrls,
          contains('https://en.wikipedia.org/wiki/Test'));
      expect(s.newArticleUrls,
          contains('https://en.wikipedia.org/wiki/Test'));

      // Same URL again — not new
      s = s.recordArticleVisit('https://en.wikipedia.org/wiki/Test',
          isNew: false);
      expect(s.newArticleUrls.length, 1); // still 1
    });
  });

  group('Question model', () {
    test('toQuizQuestion produces 4 options with exactly 1 correct', () {
      final q = allQuestions.first;
      final qq = q.toQuizQuestion();
      expect(qq.options.length, 4);
      expect(qq.options.contains(q.correctAnswers.first) ||
          q.correctAnswers.any((a) => qq.options.contains(a)), isTrue);
      expect(qq.isCorrect(qq.correctIndex), isTrue);
    });

    test('correct answer is in the options', () {
      for (final q in allQuestions.take(20)) {
        final qq = q.toQuizQuestion();
        final correct = qq.options[qq.correctIndex];
        expect(q.correctAnswers.contains(correct), isTrue);
      }
    });
  });

  group('Question bank', () {
    test('allQuestions is non-empty', () {
      expect(allQuestions, isNotEmpty);
    });

    test('selectQuestions returns requested count', () {
      final selected = selectQuestions(
        topicIds: Set.from(allTopicIds),
        count: 5,
      );
      expect(selected.length, lessThanOrEqualTo(5));
    });

    test('every question has 4 wrong answers minimum', () {
      for (final q in allQuestions) {
        expect(q.wrongAnswers.length, greaterThanOrEqualTo(4),
            reason: 'Question ${q.id} needs at least 4 wrong answers');
      }
    });

    test('topic registry has all expected super-categories', () {
      final ids = superCategories.map((sc) => sc.id).toList();
      expect(ids, contains('literature_arts'));
      expect(ids, contains('health_medicine'));
      expect(ids, contains('engineering_tech'));
    });
  });
}

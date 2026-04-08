import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/gameplay/data/question_bank.dart';
import 'package:mind_maze/features/gameplay/data/topic_registry.dart';
import 'package:mind_maze/features/gameplay/domain/models/game_state.dart';
import 'package:mind_maze/features/gameplay/domain/models/question.dart';
import 'package:mind_maze/features/gameplay/domain/models/quiz_config.dart';
import 'package:mind_maze/features/gameplay/domain/models/topic.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

QuizQuestion _fakeQuizQuestion(String id) {
  final q = Question(
    id: id,
    question: 'Test question $id?',
    correctAnswers: const ['Correct'],
    wrongAnswers: const ['Wrong 1', 'Wrong 2', 'Wrong 3', 'Wrong 4'],
    funFact: 'Fun fact',
    sourceId: '',
    articleTitle: 'Article',
    articleUrl: 'https://example.com',
    topicId: 'test_topic',
    topicCategoryId: '',
    superCategoryId: '',
    difficulty: QuestionDifficulty.easy,
  );
  return q.toQuizQuestion();
}

GameState _makeState({int count = 5}) {
  final questions = List.generate(count, (i) => _fakeQuizQuestion('q_$i'));
  final config = QuizConfig(
    selectedTopicIds: const {'test_topic'},
    questionCount: count,
  );
  return GameState.initial(questions: questions, config: config);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('currentQuestion returns question at current index', () {
      final s = _makeState(count: 3);
      expect(s.currentQuestion, s.questions[0]);
    });

    test('markLoading sets status to loading', () {
      var s = _makeState().answerQuestion(correct: true);
      expect(s.status, GameStatus.answerRevealed);
      s = s.markLoading();
      expect(s.status, GameStatus.loading);
    });
  });

  group('Question model', () {
    test('toQuizQuestion produces 4 options with exactly 1 correct', () {
      final q = _fakeQuizQuestion('q_1').source;
      final qq = q.toQuizQuestion();
      expect(qq.options.length, 4);
      expect(q.correctAnswers.any((a) => qq.options.contains(a)), isTrue);
      expect(qq.isCorrect(qq.correctIndex), isTrue);
    });

    test('correct answer is in the options', () {
      for (var i = 0; i < 20; i++) {
        final q = _fakeQuizQuestion('q_$i').source;
        final qq = q.toQuizQuestion();
        final correct = qq.options[qq.correctIndex];
        expect(q.correctAnswers.contains(correct), isTrue);
      }
    });
  });

  group('Question bank (JSON asset)', () {
    setUpAll(() async {
      // Ensure the asset bundle is available in tests.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('selectQuestionsFrom returns requested count from a pool', () {
      final pool = List.generate(
        20,
        (i) => Question(
          id: 'q_$i',
          question: 'Q $i?',
          correctAnswers: const ['C'],
          wrongAnswers: const ['W1', 'W2', 'W3', 'W4'],
          funFact: '',
          sourceId: '',
          articleTitle: '',
          articleUrl: '',
          topicId: i.isEven ? 'topic_a' : 'topic_b',
          topicCategoryId: '',
          superCategoryId: '',
          difficulty: QuestionDifficulty.easy,
        ),
      );

      final selected = selectQuestionsFrom(
        pool,
        topicIds: {'topic_a'},
        count: 5,
      );
      expect(selected.length, lessThanOrEqualTo(5));
      expect(selected.every((q) => q.topicId == 'topic_a'), isTrue);
    });

    test('topic registry has all expected super-categories', () {
      final ids = superCategories.map((sc) => sc.id).toList();
      expect(ids, contains('literature_arts'));
      expect(ids, contains('health_medicine'));
      expect(ids, contains('engineering_tech'));
    });
  });

  group('QuestionDifficulty', () {
    test('fromString falls back to medium for unknown value', () {
      expect(QuestionDifficulty.fromString('unknown'), QuestionDifficulty.medium);
      expect(QuestionDifficulty.fromString('easy'), QuestionDifficulty.easy);
      expect(QuestionDifficulty.fromString('hard'), QuestionDifficulty.hard);
    });
  });

  group('Question.withSource', () {
    test('returns copy with updated articleTitle and articleUrl', () {
      const q = Question(
        id: 'ws_001',
        question: 'Test?',
        correctAnswers: ['Yes'],
        wrongAnswers: ['No', 'Maybe', 'Never', 'Always'],
        funFact: 'Fact.',
        sourceId: 'src_1',
        articleTitle: '',
        articleUrl: '',
        topicId: 'tests',
        difficulty: QuestionDifficulty.easy,
      );
      final updated = q.withSource(title: 'New Title', url: 'https://wiki.org/New');
      expect(updated.articleTitle, 'New Title');
      expect(updated.articleUrl, 'https://wiki.org/New');
      expect(updated.id, q.id);
      expect(updated.sourceId, q.sourceId);
    });
  });

  group('QuizQuestion getters', () {
    test('delegates all getters to source question', () {
      const q = Question(
        id: 'gq_001',
        question: 'Getter test?',
        correctAnswers: ['Yes'],
        wrongAnswers: ['No', 'Maybe', 'Never', 'Always'],
        funFact: 'Getter fact.',
        sourceId: '',
        articleTitle: 'Getter Article',
        articleUrl: 'https://example.com/getter',
        topicId: 'getter_topic',
        topicCategoryId: 'cat',
        superCategoryId: 'super',
        difficulty: QuestionDifficulty.hard,
      );
      final qq = q.toQuizQuestion();
      expect(qq.question, q.question);
      expect(qq.funFact, q.funFact);
      expect(qq.articleTitle, 'Getter Article');
      expect(qq.articleUrl, 'https://example.com/getter');
      expect(qq.topicId, 'getter_topic');
      expect(qq.difficulty, QuestionDifficulty.hard);
    });
  });

  group('QuizConfig', () {
    test('copyWith replaces specified fields', () {
      const cfg = QuizConfig(
        selectedTopicIds: {'a', 'b'},
        questionCount: 5,
      );
      final updated = cfg.copyWith(questionCount: 10);
      expect(updated.questionCount, 10);
      expect(updated.selectedTopicIds, {'a', 'b'});

      final updated2 = cfg.copyWith(selectedTopicIds: {'c'});
      expect(updated2.selectedTopicIds, {'c'});
      expect(updated2.questionCount, 5);
    });
  });

  group('Topic hierarchy', () {
    test('SuperCategory.allTopics and allTopicIds aggregate leaf topics', () {
      const topic1 = Topic(id: 't1', name: 'Topic 1', categoryId: 'cat1', emoji: '🎯');
      const topic2 = Topic(id: 't2', name: 'Topic 2', categoryId: 'cat1', emoji: '🎮');
      const cat = TopicCategory(
        id: 'cat1',
        name: 'Cat 1',
        superCategoryId: 'sc1',
        topics: [topic1, topic2],
      );
      const sc = SuperCategory(
        id: 'sc1',
        name: 'Super 1',
        emoji: '🌟',
        categories: [cat],
      );
      expect(sc.allTopics, [topic1, topic2]);
      expect(sc.allTopicIds, ['t1', 't2']);
    });

    test('TopicCategory.topicIds returns topic ids', () {
      const topic = Topic(id: 'tx', name: 'TX', categoryId: 'cx', emoji: '❓');
      const cat = TopicCategory(
        id: 'cx',
        name: 'CX',
        superCategoryId: 'sx',
        topics: [topic],
      );
      expect(cat.topicIds, ['tx']);
    });
  });

  group('Question.fromJson', () {
    test('round-trips through JSON correctly', () {
      const q = Question(
        id: 'test_001',
        question: 'Is this a test?',
        correctAnswers: ['Yes'],
        wrongAnswers: ['No', 'Maybe', 'Never', 'Always'],
        funFact: 'It is indeed a test.',
        sourceId: '',
        articleTitle: 'Test',
        articleUrl: 'https://example.com',
        topicId: 'tests',
        topicCategoryId: '',
        superCategoryId: '',
        difficulty: QuestionDifficulty.hard,
      );

      final json = {
        'id': q.id,
        'question': q.question,
        'correctAnswers': q.correctAnswers,
        'wrongAnswers': q.wrongAnswers,
        'funFact': q.funFact,
        'sourceId': q.sourceId,
        'articleTitle': q.articleTitle,
        'articleUrl': q.articleUrl,
        'topicId': q.topicId,
        'topicCategoryId': q.topicCategoryId,
        'superCategoryId': q.superCategoryId,
        'difficulty': q.difficulty.name,
      };

      final restored = Question.fromJson(json);
      expect(restored.id, q.id);
      expect(restored.question, q.question);
      expect(restored.correctAnswers, q.correctAnswers);
      expect(restored.wrongAnswers, q.wrongAnswers);
      expect(restored.difficulty, QuestionDifficulty.hard);
    });
  });
}

import 'dart:math';

enum QuestionDifficulty {
  easy,
  medium,
  hard;

  static QuestionDifficulty fromString(String value) {
    return QuestionDifficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => QuestionDifficulty.medium,
    );
  }
}

/// Source question stored in the question bank.
/// One Question can hold 1–3 correct answers and 4–12 wrong answers.
/// Call [toQuizQuestion] to produce a randomised 4-option quiz round.
class Question {
  final String id;
  final String question;
  final List<String> correctAnswers; // 1–3 correct answers
  final List<String> wrongAnswers;   // 4–12 wrong answers (target 8–12)
  final String funFact;
  final String sourceId;
  final String articleTitle;
  final String articleUrl;
  final String topicId;
  final String topicCategoryId;
  final String superCategoryId;
  final QuestionDifficulty difficulty;

  const Question({
    required this.id,
    required this.question,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.funFact,
    this.sourceId = '',
    required this.articleTitle,
    required this.articleUrl,
    required this.topicId,
    this.topicCategoryId = '',
    this.superCategoryId = '',
    required this.difficulty,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      question: json['question'] as String,
      correctAnswers: List<String>.from(json['correctAnswers'] as List),
      wrongAnswers: List<String>.from(json['wrongAnswers'] as List),
      funFact: json['funFact'] as String,
      sourceId: json['sourceId'] as String? ?? '',
      // backward-compat: may still be present in pre-migration JSON
      articleTitle: json['articleTitle'] as String? ?? '',
      articleUrl: json['articleUrl'] as String? ?? '',
      topicId: json['topicId'] as String,
      topicCategoryId: json['topicCategoryId'] as String? ?? '',
      superCategoryId: json['superCategoryId'] as String? ?? '',
      difficulty: QuestionDifficulty.fromString(json['difficulty'] as String),
    );
  }

  /// Returns a copy with articleTitle and articleUrl resolved from a source.
  Question withSource({required String title, required String url}) => Question(
    id: id,
    question: question,
    correctAnswers: correctAnswers,
    wrongAnswers: wrongAnswers,
    funFact: funFact,
    sourceId: sourceId,
    articleTitle: title,
    articleUrl: url,
    topicId: topicId,
    topicCategoryId: topicCategoryId,
    superCategoryId: superCategoryId,
    difficulty: difficulty,
  );

  /// Pick 1 correct answer + 3 wrong answers, shuffle, return a [QuizQuestion].
  QuizQuestion toQuizQuestion([Random? rng]) {
    final random = rng ?? Random();
    final correct = correctAnswers[random.nextInt(correctAnswers.length)];
    final shuffledWrongs = List<String>.from(wrongAnswers)..shuffle(random);
    final options = [correct, ...shuffledWrongs.take(3)]..shuffle(random);
    return QuizQuestion(
      source: this,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }
}

/// Runtime question with 4 pre-shuffled options and a resolved [correctIndex].
class QuizQuestion {
  final Question source;
  final List<String> options; // exactly 4
  final int correctIndex;

  const QuizQuestion({
    required this.source,
    required this.options,
    required this.correctIndex,
  });

  bool isCorrect(int index) => index == correctIndex;

  String get question => source.question;
  String get funFact => source.funFact;
  String get articleTitle => source.articleTitle;
  String get articleUrl => source.articleUrl;
  String get topicId => source.topicId;
  QuestionDifficulty get difficulty => source.difficulty;
}

import 'dart:math';

enum QuestionDifficulty { easy, medium, hard }

/// Source question stored in the question bank.
/// One Question can hold 1–3 correct answers and 4–10 wrong answers.
/// Call [toQuizQuestion] to produce a randomised 4-option quiz round.
class Question {
  final String id;
  final String question;
  final List<String> correctAnswers; // 1–3 correct answers
  final List<String> wrongAnswers;   // 4–10 wrong answers
  final String funFact;
  final String articleTitle;
  final String articleUrl;
  final String topicId;
  final QuestionDifficulty difficulty;

  const Question({
    required this.id,
    required this.question,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.funFact,
    required this.articleTitle,
    required this.articleUrl,
    required this.topicId,
    required this.difficulty,
  });

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

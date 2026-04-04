import 'question.dart';
import 'quiz_config.dart';

enum GameStatus { idle, loading, playing, answerRevealed, gameOver, complete }

class GameState {
  final List<QuizQuestion> questions;
  final int currentQuestionIndex;
  final int score;
  final int lives;
  final GameStatus status;
  final QuizConfig config;
  final Set<String> seenArticleUrls;
  final Set<String> newArticleUrls;
  final List<bool?> answeredCorrectly;

  const GameState({
    required this.questions,
    required this.currentQuestionIndex,
    required this.score,
    required this.lives,
    required this.status,
    required this.config,
    required this.seenArticleUrls,
    required this.newArticleUrls,
    required this.answeredCorrectly,
  });

  factory GameState.initial({
    required List<QuizQuestion> questions,
    required QuizConfig config,
  }) {
    return GameState(
      questions: questions,
      currentQuestionIndex: 0,
      score: 0,
      lives: 3,
      status: GameStatus.loading,
      config: config,
      seenArticleUrls: const {},
      newArticleUrls: const {},
      answeredCorrectly: List.filled(questions.length, null),
    );
  }

  QuizQuestion get currentQuestion => questions[currentQuestionIndex];
  bool get isGameOver => lives <= 0 || status == GameStatus.gameOver;
  bool get isComplete =>
      currentQuestionIndex >= questions.length || status == GameStatus.complete;
  int get questionsAnswered => answeredCorrectly.where((a) => a != null).length;
  int get correctCount => answeredCorrectly.where((a) => a == true).length;

  GameState copyWith({
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    int? score,
    int? lives,
    GameStatus? status,
    QuizConfig? config,
    Set<String>? seenArticleUrls,
    Set<String>? newArticleUrls,
    List<bool?>? answeredCorrectly,
  }) {
    return GameState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      lives: lives ?? this.lives,
      status: status ?? this.status,
      config: config ?? this.config,
      seenArticleUrls: seenArticleUrls ?? this.seenArticleUrls,
      newArticleUrls: newArticleUrls ?? this.newArticleUrls,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
    );
  }

  GameState answerQuestion({required bool correct}) {
    final updated = List<bool?>.from(answeredCorrectly);
    updated[currentQuestionIndex] = correct;
    final newScore = correct ? score + 10 : score;
    final newLives = correct ? lives : lives - 1;
    final isNowGameOver = newLives <= 0;
    final isNowComplete =
        !isNowGameOver && currentQuestionIndex >= questions.length - 1;
    return copyWith(
      answeredCorrectly: updated,
      score: newScore,
      lives: newLives,
      status: isNowGameOver
          ? GameStatus.gameOver
          : isNowComplete
              ? GameStatus.complete
              : GameStatus.answerRevealed,
    );
  }

  GameState advanceQuestion() {
    if (isGameOver || isComplete) return this;
    final next = currentQuestionIndex + 1;
    if (next >= questions.length) return copyWith(status: GameStatus.complete);
    return copyWith(currentQuestionIndex: next, status: GameStatus.loading);
  }

  GameState markLoading() => copyWith(status: GameStatus.loading);
  GameState markPlaying() => copyWith(status: GameStatus.playing);

  GameState recordArticleVisit(String url, {required bool isNew}) {
    return copyWith(
      seenArticleUrls: {...seenArticleUrls, url},
      newArticleUrls: isNew ? {...newArticleUrls, url} : newArticleUrls,
    );
  }
}

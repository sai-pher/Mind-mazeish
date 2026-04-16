enum GameMode { standard, endless }

/// Configuration for a single game session.
class QuizConfig {
  final Set<String> selectedTopicIds;
  final int questionCount; // 5, 10, or 20 — ignored in endless mode
  final GameMode gameMode;
  /// 1 = skewed easy, 3 = balanced (default), 5 = skewed hard.
  final int difficultyBias;

  const QuizConfig({
    required this.selectedTopicIds,
    required this.questionCount,
    this.gameMode = GameMode.standard,
    this.difficultyBias = 3,
  });

  static const List<int> validCounts = [5, 10, 20];

  /// Consecutive correct answers required to trigger a streak reward in endless mode.
  /// Scales with difficulty: easier → shorter streak required.
  int get streakLimit => switch (difficultyBias) {
        1 => 5,
        2 => 7,
        4 => 13,
        5 => 15,
        _ => 10,
      };

  QuizConfig copyWith({
    Set<String>? selectedTopicIds,
    int? questionCount,
    GameMode? gameMode,
    int? difficultyBias,
  }) {
    return QuizConfig(
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      questionCount: questionCount ?? this.questionCount,
      gameMode: gameMode ?? this.gameMode,
      difficultyBias: difficultyBias ?? this.difficultyBias,
    );
  }
}

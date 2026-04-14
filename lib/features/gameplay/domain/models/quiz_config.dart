enum GameMode { standard, endless }

/// Configuration for a single game session.
class QuizConfig {
  final Set<String> selectedTopicIds;
  final int questionCount; // 5, 10, or 20 — ignored in endless mode
  final GameMode gameMode;

  const QuizConfig({
    required this.selectedTopicIds,
    required this.questionCount,
    this.gameMode = GameMode.standard,
  });

  static const List<int> validCounts = [5, 10, 20];

  QuizConfig copyWith({
    Set<String>? selectedTopicIds,
    int? questionCount,
    GameMode? gameMode,
  }) {
    return QuizConfig(
      selectedTopicIds: selectedTopicIds ?? this.selectedTopicIds,
      questionCount: questionCount ?? this.questionCount,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}

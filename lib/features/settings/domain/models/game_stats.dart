class GameStats {
  final int gamesPlayed;
  final int standardGamesPlayed;
  final int totalWins;
  final int bestScore;
  final int totalScore;
  final int totalCorrect;
  final int totalAnswered;
  final int totalArticlesFound;
  final int endlessHighScore;

  const GameStats({
    this.gamesPlayed = 0,
    this.standardGamesPlayed = 0,
    this.totalWins = 0,
    this.bestScore = 0,
    this.totalScore = 0,
    this.totalCorrect = 0,
    this.totalAnswered = 0,
    this.totalArticlesFound = 0,
    this.endlessHighScore = 0,
  });

  double get accuracy =>
      totalAnswered == 0 ? 0.0 : totalCorrect / totalAnswered;

  /// Win rate is scoped to Standard mode games only.
  /// Endless games are excluded because they end via lives-out (gameOver),
  /// not via completing the question set, so they never produce a "win".
  double get winRate =>
      standardGamesPlayed == 0 ? 0.0 : totalWins / standardGamesPlayed;

  GameStats recordGame({
    required int score,
    required int correct,
    required int answered,
    required int articlesFound,
    required bool won,
    required bool isEndless,
    int? endlessScore,
  }) {
    return GameStats(
      gamesPlayed: gamesPlayed + 1,
      standardGamesPlayed:
          isEndless ? standardGamesPlayed : standardGamesPlayed + 1,
      totalWins: won ? totalWins + 1 : totalWins,
      bestScore: score > bestScore ? score : bestScore,
      totalScore: totalScore + score,
      totalCorrect: totalCorrect + correct,
      totalAnswered: totalAnswered + answered,
      totalArticlesFound: totalArticlesFound + articlesFound,
      endlessHighScore: endlessScore != null && endlessScore > endlessHighScore
          ? endlessScore
          : endlessHighScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'gamesPlayed': gamesPlayed,
        'standardGamesPlayed': standardGamesPlayed,
        'totalWins': totalWins,
        'bestScore': bestScore,
        'totalScore': totalScore,
        'totalCorrect': totalCorrect,
        'totalAnswered': totalAnswered,
        'totalArticlesFound': totalArticlesFound,
        'endlessHighScore': endlessHighScore,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        gamesPlayed: (json['gamesPlayed'] as int?) ?? 0,
        // Existing saved data won't have this field — default to gamesPlayed
        // so returning users keep their historical win rate rather than seeing 0%.
        standardGamesPlayed: (json['standardGamesPlayed'] as int?) ??
            (json['gamesPlayed'] as int?) ??
            0,
        totalWins: (json['totalWins'] as int?) ?? 0,
        bestScore: (json['bestScore'] as int?) ?? 0,
        totalScore: (json['totalScore'] as int?) ?? 0,
        totalCorrect: (json['totalCorrect'] as int?) ?? 0,
        totalAnswered: (json['totalAnswered'] as int?) ?? 0,
        totalArticlesFound: (json['totalArticlesFound'] as int?) ?? 0,
        endlessHighScore: (json['endlessHighScore'] as int?) ?? 0,
      );
}

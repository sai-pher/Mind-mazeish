class GameStats {
  final int gamesPlayed;
  final int totalWins;
  final int bestScore;
  final int totalScore;
  final int totalCorrect;
  final int totalAnswered;
  final int totalArticlesFound;
  final int endlessHighScore;

  const GameStats({
    this.gamesPlayed = 0,
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

  double get winRate =>
      gamesPlayed == 0 ? 0.0 : totalWins / gamesPlayed;

  GameStats recordGame({
    required int score,
    required int correct,
    required int answered,
    required int articlesFound,
    required bool won,
    int? endlessScore,
  }) {
    return GameStats(
      gamesPlayed: gamesPlayed + 1,
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
        totalWins: (json['totalWins'] as int?) ?? 0,
        bestScore: (json['bestScore'] as int?) ?? 0,
        totalScore: (json['totalScore'] as int?) ?? 0,
        totalCorrect: (json['totalCorrect'] as int?) ?? 0,
        totalAnswered: (json['totalAnswered'] as int?) ?? 0,
        totalArticlesFound: (json['totalArticlesFound'] as int?) ?? 0,
        endlessHighScore: (json['endlessHighScore'] as int?) ?? 0,
      );
}

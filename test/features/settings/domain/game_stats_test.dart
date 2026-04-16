import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/settings/domain/models/game_stats.dart';

void main() {
  group('GameStats', () {
    test('defaults are all zero', () {
      const s = GameStats();
      expect(s.gamesPlayed, 0);
      expect(s.totalWins, 0);
      expect(s.bestScore, 0);
      expect(s.totalScore, 0);
      expect(s.totalCorrect, 0);
      expect(s.totalAnswered, 0);
      expect(s.totalArticlesFound, 0);
    });

    test('accuracy is 0 when no answers', () {
      expect(const GameStats().accuracy, 0.0);
    });

    test('winRate is 0 when no games', () {
      expect(const GameStats().winRate, 0.0);
    });

    group('recordGame', () {
      test('increments gamesPlayed', () {
        final s = const GameStats().recordGame(
          score: 10, correct: 1, answered: 2, articlesFound: 0, won: false,
        );
        expect(s.gamesPlayed, 1);
      });

      test('updates bestScore only when higher', () {
        var s = const GameStats().recordGame(
          score: 50, correct: 5, answered: 5, articlesFound: 0, won: true,
        );
        s = s.recordGame(
          score: 30, correct: 3, answered: 5, articlesFound: 0, won: true,
        );
        expect(s.bestScore, 50);

        s = s.recordGame(
          score: 80, correct: 8, answered: 10, articlesFound: 2, won: true,
        );
        expect(s.bestScore, 80);
      });

      test('totalWins increments only on won=true', () {
        var s = const GameStats().recordGame(
          score: 0, correct: 0, answered: 5, articlesFound: 0, won: false,
        );
        expect(s.totalWins, 0);

        s = s.recordGame(
          score: 50, correct: 5, answered: 5, articlesFound: 0, won: true,
        );
        expect(s.totalWins, 1);
      });

      test('accumulates totalScore, totalCorrect, totalAnswered, totalArticlesFound', () {
        var s = const GameStats().recordGame(
          score: 40, correct: 4, answered: 5, articlesFound: 2, won: true,
        );
        s = s.recordGame(
          score: 60, correct: 6, answered: 10, articlesFound: 3, won: true,
        );
        expect(s.totalScore, 100);
        expect(s.totalCorrect, 10);
        expect(s.totalAnswered, 15);
        expect(s.totalArticlesFound, 5);
      });

      test('accuracy computes correctly', () {
        final s = const GameStats().recordGame(
          score: 80, correct: 8, answered: 10, articlesFound: 0, won: true,
        );
        expect(s.accuracy, closeTo(0.8, 0.0001));
      });

      test('winRate computes correctly', () {
        var s = const GameStats().recordGame(
          score: 50, correct: 5, answered: 5, articlesFound: 0, won: true,
        );
        s = s.recordGame(
          score: 0, correct: 0, answered: 5, articlesFound: 0, won: false,
        );
        expect(s.winRate, closeTo(0.5, 0.0001));
      });
    });

    group('JSON serialisation', () {
      test('round-trips through toJson/fromJson', () {
        const original = GameStats(
          gamesPlayed: 5,
          totalWins: 3,
          bestScore: 90,
          totalScore: 350,
          totalCorrect: 35,
          totalAnswered: 50,
          totalArticlesFound: 12,
        );
        final restored = GameStats.fromJson(original.toJson());
        expect(restored.gamesPlayed, original.gamesPlayed);
        expect(restored.totalWins, original.totalWins);
        expect(restored.bestScore, original.bestScore);
        expect(restored.totalScore, original.totalScore);
        expect(restored.totalCorrect, original.totalCorrect);
        expect(restored.totalAnswered, original.totalAnswered);
        expect(restored.totalArticlesFound, original.totalArticlesFound);
      });

      test('fromJson handles missing keys gracefully', () {
        final s = GameStats.fromJson({});
        expect(s.gamesPlayed, 0);
        expect(s.bestScore, 0);
      });
    });
  });
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/game_stats.dart';

class GameStatsRepository {
  static const _key = 'game_stats_v1';

  static Future<GameStats> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const GameStats();
    try {
      return GameStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const GameStats();
    }
  }

  static Future<void> save(GameStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(stats.toJson()));
  }

  static Future<GameStats> recordGame({
    required int score,
    required int correct,
    required int answered,
    required int articlesFound,
    required bool won,
    int? endlessScore,
  }) async {
    final current = await load();
    final updated = current.recordGame(
      score: score,
      correct: correct,
      answered: answered,
      articlesFound: articlesFound,
      won: won,
      endlessScore: endlessScore,
    );
    await save(updated);
    return updated;
  }
}

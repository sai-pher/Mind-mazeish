import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/question.dart';

const _topicsDir = 'assets/questions/topics';
const _sourcesDir = 'assets/questions/sources';

typedef _Source = ({String id, String title, String url});

/// Loads sources for [topicId] and returns a sourceId → Source map.
/// Returns an empty map if the sources file does not exist or cannot be parsed.
Future<Map<String, _Source>> _loadSources(String topicId) async {
  try {
    final raw = await rootBundle.loadString('$_sourcesDir/$topicId.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return {
      for (final e in list.cast<Map<String, dynamic>>())
        if ((e['id'] as String?)?.isNotEmpty == true)
          e['id'] as String: (
            id: e['id'] as String,
            title: e['title'] as String? ?? '',
            url: e['url'] as String? ?? '',
          ),
    };
  } catch (_) {
    return {};
  }
}

/// Loads questions for the given [topicIds] from per-topic JSON asset files.
/// Resolves articleTitle/articleUrl from the corresponding sources file when
/// the question carries a sourceId but no inline articleTitle.
Future<List<Question>> loadQuestionsForTopics(Set<String> topicIds) async {
  final results = <Question>[];
  for (final id in topicIds) {
    final path = '$_topicsDir/$id.json';
    try {
      final sources = await _loadSources(id);
      final raw = await rootBundle.loadString(path);
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list.cast<Map<String, dynamic>>()) {
        final q = Question.fromJson(e);
        if (q.articleTitle.isEmpty && q.sourceId.isNotEmpty) {
          final src = sources[q.sourceId];
          if (src != null) {
            results.add(q.withSource(title: src.title, url: src.url));
            continue;
          }
        }
        results.add(q);
      }
    } catch (_) {
      // Topic file not found — skip silently (topic may have no questions yet).
    }
  }
  return results;
}

/// Loads every topic file and returns the full question pool.
/// Used by the topic picker to show available question counts.
Future<List<Question>> loadAllQuestions() async {
  return loadQuestionsForTopics(_allTopicIds);
}

/// Canonical list of all topic IDs that have asset files.
const _allTopicIds = {
  'adhd',
  'agatha_christie',
  'anatomy',
  'autism',
  'bridges',
  'candy',
  'chemical_engineering',
  'coffee',
  'coffee_brewing',
  'countries',
  'crocheting',
  'deep_sea',
  'dictionaries',
  'footwear',
  'french_literature',
  'handheld_devices',
  'human_geography',
  'lily_mayne',
  'linguistics',
  'mechanical_engineering',
  'medicine',
  'medieval_history',
  'perfumes',
  'pharmaceutical_drugs',
  'physical_geography',
  'plastics',
  'puzzles',
  'recreational_drugs',
  'rocks',
  'socks',
  'tennis',
  'theology',
  'therapy',
  'water_bodies',
  'west_african_history',
};

/// Provider that loads ALL questions once and caches them.
/// Used by the topic picker for question-count display.
final questionsProvider = FutureProvider<List<Question>>(
  (_) => loadAllQuestions(),
);

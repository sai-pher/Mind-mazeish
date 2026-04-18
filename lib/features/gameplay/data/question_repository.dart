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
///
/// All topics are loaded concurrently; within each topic the questions file and
/// sources file are also fetched concurrently.
Future<List<Question>> loadQuestionsForTopics(Set<String> topicIds) async {
  final perTopic = await Future.wait(topicIds.map(_loadTopicQuestions));
  return perTopic.expand((qs) => qs).toList();
}

Future<List<Question>> _loadTopicQuestions(String id) async {
  final path = '$_topicsDir/$id.json';
  try {
    final (sources, raw) =
        await (_loadSources(id), rootBundle.loadString(path)).wait;
    final list = jsonDecode(raw) as List<dynamic>;
    final questions = <Question>[];
    for (final e in list.cast<Map<String, dynamic>>()) {
      final q = Question.fromJson(e);
      if (q.articleTitle.isEmpty && q.sourceId.isNotEmpty) {
        final src = sources[q.sourceId];
        if (src != null) {
          questions.add(q.withSource(title: src.title, url: src.url));
          continue;
        }
      }
      questions.add(q);
    }
    return questions;
  } catch (_) {
    // Topic file not found — skip silently (topic may have no questions yet).
    return [];
  }
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
  'software_architecture',
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

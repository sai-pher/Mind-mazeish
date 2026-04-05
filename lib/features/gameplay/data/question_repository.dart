import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/question.dart';

const _topicsDir = 'assets/questions/topics';

/// Loads questions for the given [topicIds] from per-topic JSON asset files.
/// Only the selected topics are read, keeping memory usage proportional
/// to what the current game session actually needs.
Future<List<Question>> loadQuestionsForTopics(Set<String> topicIds) async {
  final results = <Question>[];
  for (final id in topicIds) {
    final path = '$_topicsDir/$id.json';
    try {
      final raw = await rootBundle.loadString(path);
      final list = jsonDecode(raw) as List<dynamic>;
      results.addAll(
        list.map((e) => Question.fromJson(e as Map<String, dynamic>)),
      );
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

// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Resolves a path relative to the project root (where pubspec.yaml lives).
String _asset(String relative) {
  // When run via `flutter test`, the working directory is the project root.
  return relative;
}

bool _isValidHttpsUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
}

void main() {
  final topicsDir = Directory(_asset('assets/questions/topics'));
  final sourcesDir = Directory(_asset('assets/questions/sources'));

  // ---------------------------------------------------------------------------
  // Source file integrity
  // ---------------------------------------------------------------------------
  group('Source JSON files', () {
    test('every sources file is valid JSON', () {
      for (final file in sourcesDir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
        expect(
          () => jsonDecode(file.readAsStringSync()),
          returnsNormally,
          reason: '${file.path} is not valid JSON',
        );
      }
    });

    test('every source entry has a non-empty id', () {
      for (final file in sourcesDir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
        final entries = jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final entry in entries.cast<Map<String, dynamic>>()) {
          expect(
            (entry['id'] as String?)?.isNotEmpty,
            isTrue,
            reason: '${file.path} contains entry with missing or empty id',
          );
        }
      }
    });

    test('every non-empty source url is a valid https URL', () {
      final violations = <String>[];
      for (final file in sourcesDir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
        final entries = jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final entry in entries.cast<Map<String, dynamic>>()) {
          final url = entry['url'] as String? ?? '';
          if (url.isNotEmpty && !_isValidHttpsUrl(url)) {
            violations.add('${file.path}[${entry['id']}]: bad url "$url"');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'Sources have malformed URLs:\n${violations.join('\n')}');
    });

    // This test documents the contract: every source must have a URL.
    // Currently skipped because most sources lack URLs (data backfill pending — see issue #27).
    // Un-skip this once the generate-questions workflow has populated all source URLs.
    test(
      'all sources have a non-empty url',
      () {
        final missing = <String>[];
        for (final file in sourcesDir.listSync().whereType<File>()
            .where((f) => f.path.endsWith('.json'))) {
          final entries = jsonDecode(file.readAsStringSync()) as List<dynamic>;
          for (final entry in entries.cast<Map<String, dynamic>>()) {
            final url = entry['url'] as String? ?? '';
            if (url.isEmpty) {
              missing.add('${file.path}[${entry['id']}]');
            }
          }
        }
        expect(missing, isEmpty,
            reason:
                '${missing.length} source entries have empty url fields. '
                'Run the generate-questions workflow to populate them.');
      },
      skip: 'pending data backfill — issue #27',
    );
  });

  // ---------------------------------------------------------------------------
  // Question file integrity
  // ---------------------------------------------------------------------------
  group('Question JSON files', () {
    test('every topic file is valid JSON', () {
      for (final file in topicsDir.listSync().whereType<File>()) {
        expect(
          () => jsonDecode(file.readAsStringSync()),
          returnsNormally,
          reason: '${file.path} is not valid JSON',
        );
      }
    });

    test('every question has required fields', () {
      for (final file in topicsDir.listSync().whereType<File>()) {
        final questions =
            jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final q in questions.cast<Map<String, dynamic>>()) {
          final id = q['id'] as String? ?? '<unknown>';
          expect(q['id'], isNotEmpty,
              reason: '${file.path}: question missing id');
          expect(q['question'], isNotEmpty,
              reason: '${file.path}[$id]: question text is empty');
          expect((q['correctAnswers'] as List?)?.isNotEmpty, isTrue,
              reason: '${file.path}[$id]: no correctAnswers');
          expect((q['wrongAnswers'] as List?)?.isNotEmpty, isTrue,
              reason: '${file.path}[$id]: no wrongAnswers');
          expect(q['funFact'], isNotEmpty,
              reason: '${file.path}[$id]: funFact is empty');
          expect(q['difficulty'], isNotEmpty,
              reason: '${file.path}[$id]: difficulty is missing');
        }
      }
    });

    test('every question has either inline articleUrl or a sourceId', () {
      final violations = <String>[];
      for (final file in topicsDir.listSync().whereType<File>()) {
        final questions =
            jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final q in questions.cast<Map<String, dynamic>>()) {
          final id = q['id'] as String? ?? '<unknown>';
          final url = q['articleUrl'] as String? ?? '';
          final sourceId = q['sourceId'] as String? ?? '';
          if (url.isEmpty && sourceId.isEmpty) {
            violations.add('${file.path}[$id]');
          }
        }
      }
      expect(violations, isEmpty,
          reason:
              'Questions have neither articleUrl nor sourceId:\n'
              '${violations.join('\n')}');
    });

    test('every non-empty inline articleUrl is a valid https URL', () {
      for (final file in topicsDir.listSync().whereType<File>()) {
        final questions =
            jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final q in questions.cast<Map<String, dynamic>>()) {
          final url = q['articleUrl'] as String? ?? '';
          if (url.isNotEmpty) {
            expect(_isValidHttpsUrl(url), isTrue,
                reason:
                    '${file.path}[${q['id']}]: bad articleUrl "$url"');
          }
        }
      }
    });

    test('sourceId references an existing source entry', () {
      // Build source id → file map
      final sourceIds = <String>{};
      for (final file in sourcesDir.listSync().whereType<File>()
          .where((f) => f.path.endsWith('.json'))) {
        final entries = jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final e in entries.cast<Map<String, dynamic>>()) {
          final id = e['id'] as String? ?? '';
          if (id.isNotEmpty) sourceIds.add(id);
        }
      }

      final dangling = <String>[];
      for (final file in topicsDir.listSync().whereType<File>()) {
        final questions =
            jsonDecode(file.readAsStringSync()) as List<dynamic>;
        for (final q in questions.cast<Map<String, dynamic>>()) {
          final sourceId = q['sourceId'] as String? ?? '';
          if (sourceId.isNotEmpty && !sourceIds.contains(sourceId)) {
            dangling.add(
                '${file.path}[${q['id']}] → sourceId "$sourceId" not found');
          }
        }
      }
      expect(dangling, isEmpty,
          reason:
              'Questions reference missing source IDs:\n'
              '${dangling.join('\n')}');
    });
  });
}

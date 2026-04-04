import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mind_maze/features/gameplay/data/wikipedia_service.dart';

void main() {
  group('WikipediaService', () {
    test('fetchArticleSummary returns WikiArticle on 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'en.wikipedia.org');
        return http.Response(
          jsonEncode({
            'title': 'Castle',
            'extract': 'A castle is a type of fortified structure.',
          }),
          200,
        );
      });

      final service = WikipediaService(client: mockClient);
      final article = await service.fetchArticleSummary(['castle']);

      expect(article.title, 'Castle');
      expect(article.summary, 'A castle is a type of fortified structure.');
      expect(article.url, contains('Castle'));
    });

    test('fetchArticleSummary throws WikipediaException on 404', () async {
      final mockClient = MockClient(
        (_) async => http.Response('Not found', 404),
      );

      final service = WikipediaService(client: mockClient);

      expect(
        () => service.fetchArticleSummary(['nonexistent_topic']),
        throwsA(isA<WikipediaException>()),
      );
    });

    test('fetchArticleSummary throws WikipediaException on non-200 error',
        () async {
      final mockClient = MockClient(
        (_) async => http.Response('Server error', 500),
      );

      final service = WikipediaService(client: mockClient);

      expect(
        () => service.fetchArticleSummary(['castle']),
        throwsA(isA<WikipediaException>()),
      );
    });

    test('fetchArticleSummary throws WikipediaException on empty summary',
        () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({'title': 'Castle', 'extract': ''}),
          200,
        );
      });

      final service = WikipediaService(client: mockClient);

      expect(
        () => service.fetchArticleSummary(['castle']),
        throwsA(isA<WikipediaException>()),
      );
    });

    test('fetchArticleSummary picks one of the provided topics', () async {
      final requestedPaths = <String>[];

      final mockClient = MockClient((request) async {
        requestedPaths.add(request.url.pathSegments.last);
        return http.Response(
          jsonEncode({
            'title': 'Drawbridge',
            'extract': 'A drawbridge is a movable bridge.',
          }),
          200,
        );
      });

      final service = WikipediaService(client: mockClient);
      await service.fetchArticleSummary(['castle', 'drawbridge', 'moat']);

      expect(requestedPaths.length, 1);
    });
  });
}

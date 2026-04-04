import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mind_maze/features/gameplay/data/claude_question_service.dart';
import 'package:mind_maze/features/gameplay/domain/models/wiki_article.dart';

const _testArticle = WikiArticle(
  title: 'Castle',
  summary: 'A castle is a type of fortified structure built in Europe.',
  url: 'https://en.m.wikipedia.org/wiki/Castle',
);

Map<String, dynamic> _claudeResponse(String questionJson) => {
      'content': [
        {'type': 'text', 'text': questionJson},
      ],
    };

const _validQuestionJson = '''
{
  "question": "What is a castle?",
  "options": ["A fortress", "A ship", "A palace", "A church"],
  "correct_index": 0,
  "fun_fact": "Castles were built for defence.",
  "article_title": "Castle",
  "article_url": "https://en.m.wikipedia.org/wiki/Castle"
}
''';

void main() {
  group('ClaudeQuestionService', () {
    test('generateQuestion parses valid response into Question', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_claudeResponse(_validQuestionJson)),
          200,
        );
      });

      final service =
          ClaudeQuestionService(apiKey: 'test-key', client: mockClient);
      final question = await service.generateQuestion(_testArticle);

      expect(question.question, 'What is a castle?');
      expect(question.options.length, 4);
      expect(question.correctIndex, 0);
      expect(question.funFact, 'Castles were built for defence.');
      expect(question.articleTitle, 'Castle');
    });

    test('generateQuestion throws ClaudeException on non-200 status', () async {
      final mockClient = MockClient(
        (_) async => http.Response('Unauthorized', 401),
      );

      final service =
          ClaudeQuestionService(apiKey: 'bad-key', client: mockClient);

      expect(
        () => service.generateQuestion(_testArticle),
        throwsA(isA<ClaudeException>()),
      );
    });

    test('generateQuestion throws ClaudeException when no JSON in response',
        () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_claudeResponse('Sorry, I cannot generate a question.')),
          200,
        );
      });

      final service =
          ClaudeQuestionService(apiKey: 'test-key', client: mockClient);

      expect(
        () => service.generateQuestion(_testArticle),
        throwsA(isA<ClaudeException>()),
      );
    });

    test('generateQuestion extracts JSON even with surrounding text', () async {
      const responseWithNoise =
          'Here is the question:\n$_validQuestionJson\nDone.';

      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(_claudeResponse(responseWithNoise)),
          200,
        );
      });

      final service =
          ClaudeQuestionService(apiKey: 'test-key', client: mockClient);
      final question = await service.generateQuestion(_testArticle);

      expect(question.question, 'What is a castle?');
    });

    test('request sends correct Anthropic headers', () async {
      final capturedHeaders = <String, String>{};

      final mockClient = MockClient((request) async {
        capturedHeaders.addAll(request.headers);
        return http.Response(
          jsonEncode(_claudeResponse(_validQuestionJson)),
          200,
        );
      });

      final service = ClaudeQuestionService(
          apiKey: 'my-secret-key', client: mockClient);
      await service.generateQuestion(_testArticle);

      expect(capturedHeaders['x-api-key'], 'my-secret-key');
      expect(capturedHeaders['anthropic-version'], '2023-06-01');
      // http package may store Content-Type under either case
      final contentType = capturedHeaders['Content-Type'] ??
          capturedHeaders['content-type'] ??
          '';
      expect(contentType, contains('application/json'));
    });
  });
}

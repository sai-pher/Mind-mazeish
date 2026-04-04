import 'dart:convert';
import 'package:http/http.dart' as http;

import '../domain/models/question.dart';
import '../domain/models/wiki_article.dart';
import '../../../core/constants/app_constants.dart';
import 'question_prompt_template.dart';

class ClaudeQuestionService {
  final http.Client _client;
  final String apiKey;

  ClaudeQuestionService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  Future<Question> generateQuestion(WikiArticle article) async {
    final prompt = buildQuestionPrompt(
      title: article.title,
      summary: article.summary,
      url: article.url,
    );

    final requestBody = jsonEncode({
      'model': AppConstants.claudeModel,
      'max_tokens': 512,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    });

    http.Response response;
    try {
      response = await _client.post(
        Uri.parse(AppConstants.anthropicBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: requestBody,
      );
    } catch (e) {
      throw ClaudeException('Network error: $e');
    }

    if (response.statusCode == 200) {
      return _parseResponse(response.body, article);
    } else if (response.statusCode == 429) {
      // Rate limited — wait briefly and retry once
      await Future.delayed(const Duration(seconds: 2));
      final retry = await _client.post(
        Uri.parse(AppConstants.anthropicBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: requestBody,
      );
      if (retry.statusCode == 200) {
        return _parseResponse(retry.body, article);
      }
      throw ClaudeException('Rate limited after retry (${retry.statusCode})');
    } else {
      throw ClaudeException(
          'Claude API error ${response.statusCode}: ${response.body}');
    }
  }

  Question _parseResponse(String responseBody, WikiArticle article) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final content = decoded['content'] as List;
      final text = (content.first as Map<String, dynamic>)['text'] as String;

      // Extract JSON block — Claude may emit surrounding whitespace
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) {
        throw const ClaudeException('No JSON object found in response');
      }
      final jsonStr = text.substring(jsonStart, jsonEnd + 1);
      final questionJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Question.fromJson(questionJson);
    } catch (e) {
      if (e is ClaudeException) rethrow;
      throw ClaudeException('Failed to parse Claude response: $e');
    }
  }
}

class ClaudeException implements Exception {
  final String message;
  const ClaudeException(this.message);

  @override
  String toString() => 'ClaudeException: $message';
}

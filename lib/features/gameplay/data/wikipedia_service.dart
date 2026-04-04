import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../domain/models/wiki_article.dart';
import '../../../core/constants/app_constants.dart';

class WikipediaService {
  final http.Client _client;
  final Random _random;

  WikipediaService({http.Client? client, Random? random})
      : _client = client ?? http.Client(),
        _random = random ?? Random();

  Future<WikiArticle> fetchArticleSummary(List<String> topics) async {
    final topic = topics[_random.nextInt(topics.length)];
    final encodedTitle = Uri.encodeComponent(topic);
    final url =
        Uri.parse('${AppConstants.wikipediaBaseUrl}/$encodedTitle');

    final response = await _client.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final article = WikiArticle.fromJson(json);
      if (article.summary.isEmpty) {
        throw WikipediaException(
            'Empty summary for topic "$topic"');
      }
      return article;
    } else if (response.statusCode == 404) {
      throw WikipediaException('Article not found for topic "$topic"');
    } else {
      throw WikipediaException(
          'Wikipedia API error ${response.statusCode} for topic "$topic"');
    }
  }
}

class WikipediaException implements Exception {
  final String message;
  const WikipediaException(this.message);

  @override
  String toString() => 'WikipediaException: $message';
}

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/question.dart';

const _questionsAsset = 'assets/questions/questions.json';

/// Loads all questions from the bundled JSON asset.
Future<List<Question>> _loadQuestions() async {
  final raw = await rootBundle.loadString(_questionsAsset);
  final list = jsonDecode(raw) as List<dynamic>;
  return list
      .map((e) => Question.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Riverpod provider — loads once and caches for the lifetime of the app.
final questionsProvider = FutureProvider<List<Question>>(
  (_) => _loadQuestions(),
);

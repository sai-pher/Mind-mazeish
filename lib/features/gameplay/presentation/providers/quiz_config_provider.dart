import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/quiz_config.dart';
import '../../data/topic_registry.dart';

final quizConfigProvider = StateProvider<QuizConfig>((ref) {
  // Default: all topics, 10 questions
  return QuizConfig(
    selectedTopicIds: Set.from(allTopicIds),
    questionCount: 10,
  );
});

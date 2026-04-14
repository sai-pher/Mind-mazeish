import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/quiz_config.dart';
import '../../data/topic_registry.dart';

class _QuizConfigNotifier extends Notifier<QuizConfig> {
  @override
  QuizConfig build() => QuizConfig(
        selectedTopicIds: Set.from(allTopicIds),
        questionCount: 10,
      );

  void setConfig(QuizConfig config) => state = config;
}

final quizConfigProvider =
    NotifierProvider<_QuizConfigNotifier, QuizConfig>(_QuizConfigNotifier.new);

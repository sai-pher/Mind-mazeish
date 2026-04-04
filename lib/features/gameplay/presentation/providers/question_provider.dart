import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/claude_question_service.dart';
import '../../data/wikipedia_service.dart';
import '../../domain/models/question.dart';
import '../../domain/models/room.dart';
import 'game_state_provider.dart';

// Service providers — can be overridden in tests
final wikipediaServiceProvider = Provider<WikipediaService>(
  (ref) => WikipediaService(),
);

final claudeQuestionServiceProvider = Provider<ClaudeQuestionService>(
  (ref) => ClaudeQuestionService(
    apiKey: dotenv.env['ANTHROPIC_API_KEY'] ?? '',
  ),
);

// Async provider that fetches a question for the given room theme
final questionProvider =
    AsyncNotifierProvider<QuestionNotifier, Question?>(QuestionNotifier.new);

class QuestionNotifier extends AsyncNotifier<Question?> {
  @override
  Future<Question?> build() async => null;

  Future<void> fetchQuestion(RoomTheme theme) async {
    state = const AsyncValue.loading();

    final wikipedia = ref.read(wikipediaServiceProvider);
    final claude = ref.read(claudeQuestionServiceProvider);
    final usedTitles =
        ref.read(gameStateProvider).usedArticleTitles;

    try {
      // Filter out topics whose articles we've already used this session
      final availableTopics = theme.wikiTopics
          .where((t) => !usedTitles.contains(t))
          .toList();
      final topics =
          availableTopics.isNotEmpty ? availableTopics : theme.wikiTopics;

      final article = await wikipedia.fetchArticleSummary(topics);

      // Track used article to avoid repetition
      ref.read(gameStateProvider.notifier).addUsedArticle(article.title);

      final question = await claude.generateQuestion(article);
      state = AsyncValue.data(question);

      // Transition game state to playing now that question is ready
      ref.read(gameStateProvider.notifier).markPlaying();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

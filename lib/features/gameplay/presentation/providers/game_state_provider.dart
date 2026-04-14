import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/question_bank.dart';
import '../../data/question_repository.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/quiz_config.dart';

class GameStateNotifier extends Notifier<GameState?> {
  @override
  GameState? build() => null;

  Future<void> startGame(QuizConfig config) async {
    // Load only the selected topics — avoids pulling all 10K questions into RAM.
    final pool = await loadQuestionsForTopics(config.selectedTopicIds);
    // Endless mode: use all available questions; standard: respect questionCount.
    final count = config.gameMode == GameMode.endless
        ? pool.length
        : config.questionCount;
    final questions = selectQuestionsFrom(
      pool,
      topicIds: config.selectedTopicIds,
      count: count,
    );
    state = GameState.initial(questions: questions, config: config);
  }

  void answerQuestion({required bool correct}) {
    if (state == null) return;
    state = state!.answerQuestion(correct: correct);
  }

  void advanceQuestion() {
    if (state == null) return;
    state = state!.advanceQuestion();
  }

  void markLoading() {
    if (state == null) return;
    state = state!.markLoading();
  }

  void markPlaying() {
    if (state == null) return;
    state = state!.markPlaying();
  }

  void recordArticleVisit(String url, {required bool isNew}) {
    if (state == null) return;
    state = state!.recordArticleVisit(url, isNew: isNew);
  }

  void restart() {
    state = null;
  }
}

final gameStateProvider =
    NotifierProvider<GameStateNotifier, GameState?>(GameStateNotifier.new);

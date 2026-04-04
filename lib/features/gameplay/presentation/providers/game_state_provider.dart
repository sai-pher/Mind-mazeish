import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/question_bank.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/quiz_config.dart';

class GameStateNotifier extends Notifier<GameState?> {
  @override
  GameState? build() => null;

  void startGame(QuizConfig config) {
    final questions = selectQuestions(
      topicIds: config.selectedTopicIds,
      count: config.questionCount,
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

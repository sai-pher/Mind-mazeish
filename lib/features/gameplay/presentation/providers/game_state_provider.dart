import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/room_data.dart';
import '../../domain/models/game_state.dart';

class GameStateNotifier extends Notifier<GameState> {
  @override
  GameState build() => buildInitialGameState();

  void answerQuestion({required bool correct}) {
    state = state.answerQuestion(correct: correct);
  }

  void advanceRoom() {
    state = state.advanceRoom();
  }

  void markLoading() {
    state = state.markLoading();
  }

  void markPlaying() {
    state = state.markPlaying();
  }

  void restart() {
    state = buildInitialGameState();
  }

  void addUsedArticle(String title) {
    state = state.copyWith(
      usedArticleTitles: {...state.usedArticleTitles, title},
    );
  }
}

final gameStateProvider =
    NotifierProvider<GameStateNotifier, GameState>(GameStateNotifier.new);

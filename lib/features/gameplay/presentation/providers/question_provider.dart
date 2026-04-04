import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/seeded_questions.dart';
import '../../domain/models/question.dart';
import '../../domain/models/room.dart';
import 'game_state_provider.dart';

final questionProvider =
    AsyncNotifierProvider<QuestionNotifier, Question?>(QuestionNotifier.new);

class QuestionNotifier extends AsyncNotifier<Question?> {
  @override
  Future<Question?> build() async => null;

  Future<void> fetchQuestion(RoomTheme theme) async {
    state = const AsyncValue.loading();

    // Small delay so the loading skeleton is briefly visible
    await Future.delayed(const Duration(milliseconds: 600));

    final question = seededQuestions[theme.id];
    if (question == null) {
      state = AsyncValue.error(
        Exception('No question found for room "${theme.id}"'),
        StackTrace.current,
      );
      return;
    }

    state = AsyncValue.data(question);
    ref.read(gameStateProvider.notifier).markPlaying();
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

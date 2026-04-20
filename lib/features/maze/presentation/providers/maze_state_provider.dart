import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../gameplay/data/question_repository.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import '../../data/maze_generator.dart';
import '../../domain/models/door_state.dart';
import '../../domain/models/maze_position.dart';
import '../../domain/models/maze_state.dart';
import '../../domain/models/maze_status.dart';

enum Direction { north, south, east, west }

extension DirectionOffset on Direction {
  MazePosition get offset => switch (this) {
        Direction.north => const MazePosition(0, -1),
        Direction.south => const MazePosition(0, 1),
        Direction.west => const MazePosition(-1, 0),
        Direction.east => const MazePosition(1, 0),
      };
}

class MazeStateNotifier extends Notifier<MazeState?> {
  @override
  MazeState? build() => null;

  Future<void> startMaze(QuizConfig config) async {
    state = null;
    final pool = await loadQuestionsForTopics(config.selectedTopicIds);
    state = MazeGenerator.generate(config: config, questionPool: pool);
  }

  void movePlayer(Direction direction) {
    final s = state;
    if (s == null || s.status != MazeStatus.navigating) return;

    final offset = direction.offset;
    final target = MazePosition(
      s.playerPosition.x + offset.x,
      s.playerPosition.y + offset.y,
    );

    if (target.x < 0 || target.y < 0 || target.x >= 10 || target.y >= 10) {
      return;
    }

    final door = s.doorBetween(s.playerPosition, target);
    if (door == DoorState.wall) return;

    state = s.enterRoom(target, from: s.playerPosition);
  }

  void submitAnswer(int selectedIndex) {
    final s = state;
    if (s == null || s.status != MazeStatus.questionActive) return;

    final q = s.activeQuestion;
    if (q == null) return;

    final correct = q.isCorrect(selectedIndex);
    state = correct ? s.answerCorrect() : s.answerWrong();
  }

  void skipRoom() {
    final s = state;
    if (s == null || s.status != MazeStatus.questionActive) return;
    state = s.skipRoom();
  }

  void dismissFunFact() {
    final s = state;
    if (s == null || s.status != MazeStatus.answerRevealed) return;
    if (s.isGameOver) return;
    state = s.dismissFunFact();
  }

  void restart() {
    state = null;
  }
}

final mazeStateProvider =
    NotifierProvider<MazeStateNotifier, MazeState?>(MazeStateNotifier.new);

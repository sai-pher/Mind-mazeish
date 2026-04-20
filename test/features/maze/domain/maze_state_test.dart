import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/gameplay/domain/models/quiz_config.dart';
import 'package:mind_maze/features/maze/domain/models/door_state.dart';
import 'package:mind_maze/features/maze/domain/models/maze_position.dart';
import 'package:mind_maze/features/maze/domain/models/maze_room.dart';
import 'package:mind_maze/features/maze/domain/models/maze_state.dart';
import 'package:mind_maze/features/maze/domain/models/maze_status.dart';
import 'package:mind_maze/features/maze/domain/models/room_status.dart';

const _dummyConfig = QuizConfig(
  selectedTopicIds: {'coffee'},
  questionCount: 10,
);

MazeState _tenByTenState({
  MazePosition player = const MazePosition(0, 0),
  MazePosition? entryFrom,
  int lives = 3,
  MazeStatus status = MazeStatus.navigating,
  Map<String, DoorState>? connections,
}) {
  final grid = List.generate(
    10,
    (y) => List.generate(
      10,
      (x) => MazeRoom(
        position: MazePosition(x, y),
        questionId: (x == 0 && y == 0) ? null : 'q_${y}_$x',
        isThroneRoom: x == 9 && y == 9,
        status: (x == 0 && y == 0) ? RoomStatus.visited : RoomStatus.hidden,
      ),
      growable: false,
    ),
    growable: false,
  );

  return MazeState(
    grid: grid,
    connections: connections ?? {},
    playerPosition: player,
    entryFrom: entryFrom,
    thronePosition: const MazePosition(9, 9),
    questions: {},
    lives: lives,
    status: status,
    config: _dummyConfig,
  );
}

void main() {
  group('connectionKey', () {
    test('is order-independent', () {
      final a = const MazePosition(1, 0);
      final b = const MazePosition(0, 0);
      expect(connectionKey(a, b), equals(connectionKey(b, a)));
    });

    test('smaller y,x comes first', () {
      final key =
          connectionKey(const MazePosition(1, 0), const MazePosition(0, 0));
      expect(key, equals('0,0-0,1'));
    });
  });

  group('MazePosition', () {
    test('equality', () {
      expect(const MazePosition(2, 3), equals(const MazePosition(2, 3)));
      expect(
        const MazePosition(1, 2),
        isNot(equals(const MazePosition(2, 1))),
      );
    });
  });

  group('MazeState.copyWith', () {
    test('clearActiveQuestion nulls it', () {
      final s = _tenByTenState().copyWith(clearActiveQuestion: true);
      expect(s.activeQuestion, isNull);
    });

    test('clearLastAnswer nulls it', () {
      final s = _tenByTenState(status: MazeStatus.answerRevealed)
          .copyWith(lives: 2, lastAnswerCorrect: false)
          .copyWith(clearLastAnswer: true);
      expect(s.lastAnswerCorrect, isNull);
    });
  });

  group('MazeState lives', () {
    test('answerWrong decrements life', () {
      final s =
          _tenByTenState(status: MazeStatus.questionActive, lives: 3)
              .answerWrong();
      expect(s.lives, equals(2));
      expect(s.status, equals(MazeStatus.answerRevealed));
    });

    test('answerWrong triggers gameOver when lives reach 0', () {
      final s =
          _tenByTenState(status: MazeStatus.questionActive, lives: 1)
              .answerWrong();
      expect(s.lives, equals(0));
      expect(s.status, equals(MazeStatus.gameOver));
      expect(s.isGameOver, isTrue);
    });

    test('answerCorrect does not change lives', () {
      final base = _tenByTenState(
        player: const MazePosition(1, 0),
        entryFrom: const MazePosition(0, 0),
        lives: 2,
        status: MazeStatus.questionActive,
        connections: {
          connectionKey(
            const MazePosition(0, 0),
            const MazePosition(1, 0),
          ): DoorState.locked,
        },
      );
      final s = base.answerCorrect();
      expect(s.lives, equals(2));
      expect(s.status, equals(MazeStatus.answerRevealed));
      expect(s.lastAnswerCorrect, isTrue);
    });
  });

  group('MazeState.skipRoom', () {
    test('sets room to skipped and status to navigating', () {
      final base = _tenByTenState(
        player: const MazePosition(1, 0),
        entryFrom: const MazePosition(0, 0),
        status: MazeStatus.questionActive,
        connections: {
          connectionKey(
            const MazePosition(0, 0),
            const MazePosition(1, 0),
          ): DoorState.locked,
        },
      );
      final s = base.skipRoom();
      expect(s.status, equals(MazeStatus.navigating));
      expect(
        s.roomAt(const MazePosition(1, 0)).status,
        equals(RoomStatus.skipped),
      );
    });
  });

  group('MazeState.enterRoom', () {
    test('throne room triggers complete', () {
      final base = _tenByTenState(
        player: const MazePosition(8, 9),
        status: MazeStatus.navigating,
      );
      final s = base.enterRoom(
        const MazePosition(9, 9),
        from: const MazePosition(8, 9),
      );
      expect(s.status, equals(MazeStatus.complete));
      expect(s.isComplete, isTrue);
    });

    test('room with no question goes to navigating', () {
      final noQGrid = List.generate(
        10,
        (y) => List.generate(
          10,
          (x) => MazeRoom(
            position: MazePosition(x, y),
            questionId: null,
            isThroneRoom: x == 9 && y == 9,
            status:
                (x == 0 && y == 0) ? RoomStatus.visited : RoomStatus.hidden,
          ),
          growable: false,
        ),
        growable: false,
      );
      final s = MazeState(
        grid: noQGrid,
        connections: {},
        playerPosition: const MazePosition(0, 0),
        thronePosition: const MazePosition(9, 9),
        questions: {},
        lives: 3,
        status: MazeStatus.navigating,
        config: _dummyConfig,
      ).enterRoom(
        const MazePosition(1, 0),
        from: const MazePosition(0, 0),
      );
      expect(s.status, equals(MazeStatus.navigating));
    });
  });

  group('MazeState.dismissFunFact', () {
    test('transitions answerRevealed → navigating', () {
      final s = _tenByTenState(status: MazeStatus.answerRevealed)
          .dismissFunFact();
      expect(s.status, equals(MazeStatus.navigating));
      expect(s.activeQuestion, isNull);
    });
  });

  group('MazeState metrics', () {
    test('correctCount counts answered rooms', () {
      final base = _tenByTenState(
        player: const MazePosition(1, 0),
        entryFrom: const MazePosition(0, 0),
        status: MazeStatus.questionActive,
        connections: {
          connectionKey(
            const MazePosition(0, 0),
            const MazePosition(1, 0),
          ): DoorState.locked,
        },
      );
      final answered = base.answerCorrect();
      expect(answered.correctCount, equals(1));
    });
  });
}

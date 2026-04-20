import '../../../gameplay/domain/models/question.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import 'door_state.dart';
import 'maze_position.dart';
import 'maze_room.dart';
import 'maze_status.dart';
import 'room_status.dart';

/// Canonical key for the edge between two adjacent cells.
/// Always puts the cell with smaller (y, x) first.
String connectionKey(MazePosition a, MazePosition b) {
  final first = (a.y < b.y || (a.y == b.y && a.x < b.x)) ? a : b;
  final second = first == a ? b : a;
  return '${first.y},${first.x}-${second.y},${second.x}';
}

const _kDirections = [
  MazePosition(0, -1),
  MazePosition(0, 1),
  MazePosition(-1, 0),
  MazePosition(1, 0),
];

class MazeState {
  /// Row-major: grid[y][x]
  final List<List<MazeRoom>> grid;

  /// Edge map: connectionKey → DoorState
  final Map<String, DoorState> connections;

  final MazePosition playerPosition;

  /// Position from which the player entered the current room (null at start).
  final MazePosition? entryFrom;

  final MazePosition thronePosition;
  final bool throneDiscovered;

  /// questionId → QuizQuestion
  final Map<String, QuizQuestion> questions;

  final int lives;
  final MazeStatus status;
  final QuizConfig config;
  final QuizQuestion? activeQuestion;
  final bool? lastAnswerCorrect;
  final int seed;

  const MazeState({
    required this.grid,
    required this.connections,
    required this.playerPosition,
    this.entryFrom,
    required this.thronePosition,
    this.throneDiscovered = false,
    required this.questions,
    required this.lives,
    required this.status,
    required this.config,
    this.activeQuestion,
    this.lastAnswerCorrect,
    this.seed = 0,
  });

  MazeRoom roomAt(MazePosition pos) => grid[pos.y][pos.x];

  DoorState doorBetween(MazePosition a, MazePosition b) =>
      connections[connectionKey(a, b)] ?? DoorState.wall;

  bool get isGameOver => status == MazeStatus.gameOver;
  bool get isComplete => status == MazeStatus.complete;

  int get roomsVisited => grid
      .expand((row) => row)
      .where((r) =>
          r.status == RoomStatus.visited ||
          r.status == RoomStatus.answered ||
          r.status == RoomStatus.skipped)
      .length;

  int get questionsAnswered =>
      grid.expand((row) => row).where((r) => r.answeredCorrectly != null).length;

  int get correctCount =>
      grid.expand((row) => row).where((r) => r.answeredCorrectly == true).length;

  MazeState copyWith({
    List<List<MazeRoom>>? grid,
    Map<String, DoorState>? connections,
    MazePosition? playerPosition,
    MazePosition? entryFrom,
    MazePosition? thronePosition,
    bool? throneDiscovered,
    Map<String, QuizQuestion>? questions,
    int? lives,
    MazeStatus? status,
    QuizConfig? config,
    QuizQuestion? activeQuestion,
    bool? lastAnswerCorrect,
    int? seed,
    bool clearEntryFrom = false,
    bool clearActiveQuestion = false,
    bool clearLastAnswer = false,
  }) {
    return MazeState(
      grid: grid ?? this.grid,
      connections: connections ?? this.connections,
      playerPosition: playerPosition ?? this.playerPosition,
      entryFrom: clearEntryFrom ? null : (entryFrom ?? this.entryFrom),
      thronePosition: thronePosition ?? this.thronePosition,
      throneDiscovered: throneDiscovered ?? this.throneDiscovered,
      questions: questions ?? this.questions,
      lives: lives ?? this.lives,
      status: status ?? this.status,
      config: config ?? this.config,
      activeQuestion:
          clearActiveQuestion ? null : (activeQuestion ?? this.activeQuestion),
      lastAnswerCorrect:
          clearLastAnswer ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      seed: seed ?? this.seed,
    );
  }

  MazeState _updateRoom(MazePosition pos, MazeRoom updated) {
    final newGrid = [
      for (int y = 0; y < grid.length; y++)
        [
          for (int x = 0; x < grid[y].length; x++)
            (x == pos.x && y == pos.y) ? updated : grid[y][x],
        ],
    ];
    return copyWith(grid: newGrid);
  }

  /// Reveal hidden cells adjacent to [pos].
  MazeState _revealNeighbours(MazePosition pos) {
    var s = this;
    for (final d in _kDirections) {
      final nx = pos.x + d.x;
      final ny = pos.y + d.y;
      if (nx < 0 || ny < 0 || nx >= 10 || ny >= 10) continue;
      final n = s.grid[ny][nx];
      if (n.status == RoomStatus.hidden) {
        s = s._updateRoom(
          MazePosition(nx, ny),
          n.copyWith(status: RoomStatus.visible),
        );
      }
    }
    return s;
  }

  /// Move the player to [target] (coming from [from]).
  /// Handles throne win, fog reveal, question activation.
  MazeState enterRoom(MazePosition target, {required MazePosition from}) {
    final room = roomAt(target);

    var s = _updateRoom(
      target,
      room.status == RoomStatus.hidden || room.status == RoomStatus.visible
          ? room.copyWith(status: RoomStatus.visited)
          : room,
    );
    s = s._revealNeighbours(target);

    final throneAdjacent =
        (thronePosition.x - target.x).abs() + (thronePosition.y - target.y).abs() == 1;

    s = s.copyWith(
      playerPosition: target,
      entryFrom: from,
      throneDiscovered: throneDiscovered || throneAdjacent,
    );

    if (room.isThroneRoom) {
      return s.copyWith(status: MazeStatus.complete);
    }

    final qId = s.roomAt(target).questionId;
    final needsQuestion = qId != null &&
        room.status != RoomStatus.answered &&
        room.status != RoomStatus.skipped;

    if (needsQuestion) {
      return s.copyWith(
        status: MazeStatus.questionActive,
        activeQuestion: s.questions[qId],
        clearLastAnswer: true,
      );
    }

    return s.copyWith(status: MazeStatus.navigating);
  }

  /// Record a correct answer and open the entry door.
  MazeState answerCorrect() {
    final room = roomAt(playerPosition);
    var s = _updateRoom(
      playerPosition,
      room.copyWith(status: RoomStatus.answered, answeredCorrectly: true),
    );
    s = s._setEntryDoor(DoorState.open);
    return s.copyWith(
      status: MazeStatus.answerRevealed,
      lastAnswerCorrect: true,
    );
  }

  /// Deduct a life for a wrong answer; optionally trigger game over.
  MazeState answerWrong() {
    final newLives = lives - 1;
    return copyWith(
      lives: newLives,
      status: newLives <= 0 ? MazeStatus.gameOver : MazeStatus.answerRevealed,
      lastAnswerCorrect: false,
    );
  }

  /// Skip this room's question.
  MazeState skipRoom() {
    final room = roomAt(playerPosition);
    var s = _updateRoom(
      playerPosition,
      room.copyWith(status: RoomStatus.skipped, answeredCorrectly: false),
    );
    s = s._setEntryDoor(DoorState.skipped);
    return s.copyWith(
      status: MazeStatus.navigating,
      clearActiveQuestion: true,
      clearLastAnswer: true,
    );
  }

  MazeState _setEntryDoor(DoorState doorState) {
    if (entryFrom == null) return this;
    final key = connectionKey(entryFrom!, playerPosition);
    if (!connections.containsKey(key)) return this;
    final newConnections = Map<String, DoorState>.from(connections)
      ..[key] = doorState;
    return copyWith(connections: newConnections);
  }

  /// Transition from answerRevealed → navigating.
  MazeState dismissFunFact() => copyWith(
        status: MazeStatus.navigating,
        clearActiveQuestion: true,
        clearLastAnswer: true,
      );
}

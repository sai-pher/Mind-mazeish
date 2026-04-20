import 'dart:collection';
import 'dart:math';

import '../../gameplay/data/question_bank.dart';
import '../../gameplay/domain/models/question.dart';
import '../../gameplay/domain/models/quiz_config.dart';
import '../domain/models/door_state.dart';
import '../domain/models/maze_position.dart';
import '../domain/models/maze_room.dart';
import '../domain/models/maze_state.dart';
import '../domain/models/maze_status.dart';
import '../domain/models/room_status.dart';

const _kSize = 10;

const _kDirections = [
  MazePosition(0, -1),
  MazePosition(0, 1),
  MazePosition(-1, 0),
  MazePosition(1, 0),
];

class MazeGenerator {
  /// Returns a fully initialised [MazeState] ready to play.
  static MazeState generate({
    required QuizConfig config,
    required List<Question> questionPool,
    int? seed,
  }) {
    final effectiveSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    final rng = Random(effectiveSeed);

    final connections = _carveMaze(rng);
    final thronePos = _findThronePosition(connections);
    final (grid, questionMap) = _buildGrid(
      thronePos: thronePos,
      questionPool: questionPool,
      config: config,
      rng: rng,
    );

    return MazeState(
      grid: grid,
      connections: connections,
      playerPosition: const MazePosition(0, 0),
      thronePosition: thronePos,
      questions: questionMap,
      lives: 3,
      status: MazeStatus.navigating,
      config: config,
      seed: effectiveSeed,
    );
  }

  /// Recursive backtracker DFS — carves a perfect maze and returns the
  /// connection map (`connectionKey → DoorState.locked`).
  static Map<String, DoorState> _carveMaze(Random rng) {
    final connections = <String, DoorState>{};
    final visited = List.generate(_kSize, (_) => List.filled(_kSize, false));

    void dfs(int x, int y) {
      visited[y][x] = true;
      final dirs = List<MazePosition>.from(_kDirections)..shuffle(rng);
      for (final d in dirs) {
        final nx = x + d.x;
        final ny = y + d.y;
        if (nx < 0 || ny < 0 || nx >= _kSize || ny >= _kSize) continue;
        if (visited[ny][nx]) continue;
        connections[connectionKey(MazePosition(x, y), MazePosition(nx, ny))] =
            DoorState.locked;
        dfs(nx, ny);
      }
    }

    dfs(0, 0);
    return connections;
  }

  /// BFS from (0,0) — returns the cell at maximum graph distance (throne).
  static MazePosition _findThronePosition(Map<String, DoorState> connections) {
    final dist = List.generate(_kSize, (_) => List.filled(_kSize, -1));
    dist[0][0] = 0;
    final queue = Queue<MazePosition>()..add(const MazePosition(0, 0));

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      for (final n in _passableNeighbours(cur, connections)) {
        if (dist[n.y][n.x] == -1) {
          dist[n.y][n.x] = dist[cur.y][cur.x] + 1;
          queue.add(n);
        }
      }
    }

    int maxDist = 0;
    MazePosition throne = const MazePosition(_kSize - 1, _kSize - 1);
    for (int y = 0; y < _kSize; y++) {
      for (int x = 0; x < _kSize; x++) {
        if (dist[y][x] > maxDist) {
          maxDist = dist[y][x];
          throne = MazePosition(x, y);
        }
      }
    }
    return throne;
  }

  /// Builds the 10×10 room grid and question map.
  /// Start cell and throne room have no question; all other cells get one.
  static (List<List<MazeRoom>>, Map<String, QuizQuestion>) _buildGrid({
    required MazePosition thronePos,
    required List<Question> questionPool,
    required QuizConfig config,
    required Random rng,
  }) {
    const startPos = MazePosition(0, 0);

    final questionCells = [
      for (int y = 0; y < _kSize; y++)
        for (int x = 0; x < _kSize; x++)
          if (MazePosition(x, y) != startPos && MazePosition(x, y) != thronePos)
            MazePosition(x, y),
    ];

    final quizQuestions = _selectQuestions(
      questionPool,
      config: config,
      count: questionCells.length,
      rng: rng,
    );

    final questionMap = <String, QuizQuestion>{};
    final grid = List.generate(
      _kSize,
      (y) => List.generate(
        _kSize,
        (x) => MazeRoom(position: MazePosition(x, y)),
        growable: false,
      ),
      growable: false,
    );

    _assignQuestions(grid, questionCells, quizQuestions, questionMap);
    _markThroneRoom(grid, thronePos);
    _initFogOfWar(grid, startPos);

    return (grid, questionMap);
  }

  static void _assignQuestions(
    List<List<MazeRoom>> grid,
    List<MazePosition> cells,
    List<QuizQuestion> questions,
    Map<String, QuizQuestion> questionMap,
  ) {
    if (questions.isEmpty) return;
    for (int i = 0; i < cells.length; i++) {
      final pos = cells[i];
      final q = questions[i % questions.length];
      final qId = '${pos.y}_${pos.x}';
      questionMap[qId] = q;
      grid[pos.y][pos.x] = MazeRoom(
        position: pos,
        questionId: qId,
        status: RoomStatus.hidden,
      );
    }
  }

  static void _markThroneRoom(List<List<MazeRoom>> grid, MazePosition pos) {
    grid[pos.y][pos.x] = MazeRoom(
      position: pos,
      isThroneRoom: true,
      status: RoomStatus.hidden,
    );
  }

  static void _initFogOfWar(List<List<MazeRoom>> grid, MazePosition start) {
    grid[start.y][start.x] = MazeRoom(
      position: start,
      status: RoomStatus.visited,
    );
    for (final d in _kDirections) {
      final nx = start.x + d.x;
      final ny = start.y + d.y;
      if (nx < 0 || ny < 0 || nx >= _kSize || ny >= _kSize) continue;
      if (grid[ny][nx].status == RoomStatus.hidden) {
        grid[ny][nx] = grid[ny][nx].copyWith(status: RoomStatus.visible);
      }
    }
  }

  static List<MazePosition> _passableNeighbours(
    MazePosition pos,
    Map<String, DoorState> connections,
  ) {
    final result = <MazePosition>[];
    for (final d in _kDirections) {
      final nx = pos.x + d.x;
      final ny = pos.y + d.y;
      if (nx < 0 || ny < 0 || nx >= _kSize || ny >= _kSize) continue;
      final neighbour = MazePosition(nx, ny);
      if (connections.containsKey(connectionKey(pos, neighbour))) {
        result.add(neighbour);
      }
    }
    return result;
  }

  /// Select [count] questions from [pool], cycling if pool is too small.
  static List<QuizQuestion> _selectQuestions(
    List<Question> pool, {
    required QuizConfig config,
    required int count,
    required Random rng,
  }) {
    if (pool.isEmpty) return [];

    final result = <QuizQuestion>[];
    while (result.length < count) {
      final batch = selectQuestionsFrom(
        pool,
        topicIds: config.selectedTopicIds,
        count: min(count - result.length, pool.length),
        difficultyBias: config.difficultyBias,
        rng: rng,
      );
      if (batch.isEmpty) break;
      result.addAll(batch);
    }
    return result.take(count).toList();
  }
}

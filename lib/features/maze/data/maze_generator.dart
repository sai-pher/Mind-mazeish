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

class MazeGenerator {
  /// Returns a fully initialised [MazeState] ready to play.
  static MazeState generate({
    required QuizConfig config,
    required List<Question> questionPool,
    int? seed,
  }) {
    final effectiveSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
    final rng = Random(effectiveSeed);

    // ── 1. Build grid of rooms (all hidden, no questions yet) ──────────────
    final grid = List.generate(
      _kSize,
      (y) => List.generate(
        _kSize,
        (x) => MazeRoom(position: MazePosition(x, y)),
        growable: false,
      ),
      growable: false,
    );

    // ── 2. Recursive backtracker DFS to carve passages ────────────────────
    final connections = <String, DoorState>{};
    final visited = List.generate(_kSize, (_) => List.filled(_kSize, false));

    void dfs(int x, int y) {
      visited[y][x] = true;
      final dirs = [
        MazePosition(0, -1),
        MazePosition(0, 1),
        MazePosition(-1, 0),
        MazePosition(1, 0),
      ]..shuffle(rng);

      for (final d in dirs) {
        final nx = x + d.x;
        final ny = y + d.y;
        if (nx < 0 || ny < 0 || nx >= _kSize || ny >= _kSize) continue;
        if (visited[ny][nx]) continue;
        final key = connectionKey(MazePosition(x, y), MazePosition(nx, ny));
        connections[key] = DoorState.locked;
        dfs(nx, ny);
      }
    }

    dfs(0, 0);

    // ── 3. BFS from (0,0) to find throne position (max distance) ──────────
    final dist = List.generate(_kSize, (_) => List.filled(_kSize, -1));
    dist[0][0] = 0;
    final queue = Queue<MazePosition>();
    queue.add(const MazePosition(0, 0));

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      for (final neighbour in _neighbours(cur, connections)) {
        if (dist[neighbour.y][neighbour.x] == -1) {
          dist[neighbour.y][neighbour.x] = dist[cur.y][cur.x] + 1;
          queue.add(neighbour);
        }
      }
    }

    int maxDist = 0;
    MazePosition thronePos = const MazePosition(_kSize - 1, _kSize - 1);
    for (int y = 0; y < _kSize; y++) {
      for (int x = 0; x < _kSize; x++) {
        if (dist[y][x] > maxDist) {
          maxDist = dist[y][x];
          thronePos = MazePosition(x, y);
        }
      }
    }

    // ── 4. Assign questions to all cells except start and throne ──────────
    final questionCells = <MazePosition>[];
    for (int y = 0; y < _kSize; y++) {
      for (int x = 0; x < _kSize; x++) {
        final pos = MazePosition(x, y);
        if (pos == const MazePosition(0, 0)) continue;
        if (pos == thronePos) continue;
        questionCells.add(pos);
      }
    }

    final quizQuestions = _selectQuestions(
      questionPool,
      config: config,
      count: questionCells.length,
      rng: rng,
    );

    final questionMap = <String, QuizQuestion>{};
    final updatedGrid = List.generate(
      _kSize,
      (y) => List.generate(_kSize, (x) => grid[y][x], growable: false),
      growable: false,
    );

    if (quizQuestions.isNotEmpty) {
      for (int i = 0; i < questionCells.length; i++) {
        final pos = questionCells[i];
        final q = quizQuestions[i % quizQuestions.length];
        final qId = '${pos.y}_${pos.x}';
        questionMap[qId] = q;
        updatedGrid[pos.y][pos.x] = MazeRoom(
          position: pos,
          questionId: qId,
          status: RoomStatus.hidden,
        );
      }
    }

    // Mark throne room
    updatedGrid[thronePos.y][thronePos.x] = MazeRoom(
      position: thronePos,
      isThroneRoom: true,
      status: RoomStatus.hidden,
    );

    // ── 5. Reveal start cell and its neighbours ────────────────────────────
    updatedGrid[0][0] = MazeRoom(
      position: const MazePosition(0, 0),
      status: RoomStatus.visited,
    );

    const startPos = MazePosition(0, 0);
    const neighbourOffsets = [
      MazePosition(0, -1),
      MazePosition(0, 1),
      MazePosition(-1, 0),
      MazePosition(1, 0),
    ];
    for (final d in neighbourOffsets) {
      final nx = startPos.x + d.x;
      final ny = startPos.y + d.y;
      if (nx < 0 || ny < 0 || nx >= _kSize || ny >= _kSize) continue;
      if (updatedGrid[ny][nx].status == RoomStatus.hidden) {
        updatedGrid[ny][nx] = updatedGrid[ny][nx].copyWith(
          status: RoomStatus.visible,
        );
      }
    }

    return MazeState(
      grid: updatedGrid,
      connections: connections,
      playerPosition: startPos,
      thronePosition: thronePos,
      questions: questionMap,
      lives: 3,
      status: MazeStatus.navigating,
      config: config,
      seed: effectiveSeed,
    );
  }

  static List<MazePosition> _neighbours(
    MazePosition pos,
    Map<String, DoorState> connections,
  ) {
    const offsets = [
      MazePosition(0, -1),
      MazePosition(0, 1),
      MazePosition(-1, 0),
      MazePosition(1, 0),
    ];
    final result = <MazePosition>[];
    for (final d in offsets) {
      final nx = pos.x + d.x;
      final ny = pos.y + d.y;
      if (nx < 0 || ny < 0 || nx >= _kSize || ny >= _kSize) continue;
      final neighbour = MazePosition(nx, ny);
      final key = connectionKey(pos, neighbour);
      if (connections.containsKey(key)) result.add(neighbour);
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
    if (pool.isEmpty) {
      // Fallback: return empty — MazeState will handle rooms with no question
      return [];
    }

    // Use selectQuestionsFrom for proper difficulty weighting.
    // If the pool is smaller than count, cycle by requesting from multiple rounds.
    final List<QuizQuestion> result = [];
    while (result.length < count) {
      final need = count - result.length;
      final batch = selectQuestionsFrom(
        pool,
        topicIds: config.selectedTopicIds,
        count: min(need, pool.length),
        difficultyBias: config.difficultyBias,
        rng: rng,
      );
      if (batch.isEmpty) break;
      result.addAll(batch);
    }
    return result.take(count).toList();
  }
}

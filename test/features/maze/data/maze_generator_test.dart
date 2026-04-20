import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/gameplay/domain/models/quiz_config.dart';
import 'package:mind_maze/features/maze/data/maze_generator.dart';
import 'package:mind_maze/features/maze/domain/models/door_state.dart';
import 'package:mind_maze/features/maze/domain/models/maze_position.dart';
import 'package:mind_maze/features/maze/domain/models/maze_status.dart';
import 'package:mind_maze/features/maze/domain/models/room_status.dart';

const _config = QuizConfig(
  selectedTopicIds: {'coffee'},
  questionCount: 10,
);

void main() {
  late final maze = MazeGenerator.generate(
    config: _config,
    questionPool: [],
    seed: 42,
  );

  group('MazeGenerator — structure', () {
    test('grid is 10×10', () {
      expect(maze.grid.length, equals(10));
      for (final row in maze.grid) {
        expect(row.length, equals(10));
      }
    });

    test('exactly 99 connections (spanning tree: n-1 for n=100)', () {
      expect(maze.connections.length, equals(99));
    });

    test('all connection values are locked at generation time', () {
      for (final v in maze.connections.values) {
        expect(v, equals(DoorState.locked));
      }
    });

    test('exactly one throne room', () {
      final throneCount = maze.grid
          .expand((row) => row)
          .where((r) => r.isThroneRoom)
          .length;
      expect(throneCount, equals(1));
    });

    test('throne room has no question', () {
      final throne =
          maze.grid.expand((row) => row).firstWhere((r) => r.isThroneRoom);
      expect(throne.questionId, isNull);
    });

    test('start cell (0,0) has no question', () {
      expect(maze.grid[0][0].questionId, isNull);
    });

    test('start cell is visited', () {
      expect(maze.grid[0][0].status, equals(RoomStatus.visited));
    });

    test('initial status is navigating', () {
      expect(maze.status, equals(MazeStatus.navigating));
    });

    test('initial lives are 3', () {
      expect(maze.lives, equals(3));
    });

    test('player starts at (0,0)', () {
      expect(maze.playerPosition, equals(const MazePosition(0, 0)));
    });
  });

  group('MazeGenerator — connectivity', () {
    test('all 100 cells reachable from (0,0) via BFS', () {
      final visited = <MazePosition>{};
      final queue = Queue<MazePosition>();
      queue.add(const MazePosition(0, 0));
      visited.add(const MazePosition(0, 0));

      while (queue.isNotEmpty) {
        final cur = queue.removeFirst();
        const offsets = [
          MazePosition(0, -1),
          MazePosition(0, 1),
          MazePosition(-1, 0),
          MazePosition(1, 0),
        ];
        for (final d in offsets) {
          final nx = cur.x + d.x;
          final ny = cur.y + d.y;
          if (nx < 0 || ny < 0 || nx >= 10 || ny >= 10) continue;
          final neighbour = MazePosition(nx, ny);
          if (visited.contains(neighbour)) continue;
          if (maze.connections.containsKey(
            maze.connections.keys.firstWhere(
              (k) => k == _key(cur, neighbour),
              orElse: () => '',
            ),
          )) {
            visited.add(neighbour);
            queue.add(neighbour);
          }
        }
      }

      expect(visited.length, equals(100));
    });

    test('all 100 cells reachable using doorBetween', () {
      final visited = <MazePosition>{};
      final queue = Queue<MazePosition>();
      queue.add(const MazePosition(0, 0));
      visited.add(const MazePosition(0, 0));

      while (queue.isNotEmpty) {
        final cur = queue.removeFirst();
        const offsets = [
          MazePosition(0, -1),
          MazePosition(0, 1),
          MazePosition(-1, 0),
          MazePosition(1, 0),
        ];
        for (final d in offsets) {
          final nx = cur.x + d.x;
          final ny = cur.y + d.y;
          if (nx < 0 || ny < 0 || nx >= 10 || ny >= 10) continue;
          final neighbour = MazePosition(nx, ny);
          if (visited.contains(neighbour)) continue;
          if (maze.doorBetween(cur, neighbour) != DoorState.wall) {
            visited.add(neighbour);
            queue.add(neighbour);
          }
        }
      }

      expect(visited.length, equals(100));
    });
  });

  group('MazeGenerator — throne placement', () {
    test('throne is not at (0,0)', () {
      expect(maze.thronePosition, isNot(equals(const MazePosition(0, 0))));
    });

    test('throne grid cell matches thronePosition', () {
      final tp = maze.thronePosition;
      expect(maze.grid[tp.y][tp.x].isThroneRoom, isTrue);
    });

    test('different seeds produce different mazes', () {
      final m1 = MazeGenerator.generate(
        config: _config,
        questionPool: [],
        seed: 1,
      );
      final m2 = MazeGenerator.generate(
        config: _config,
        questionPool: [],
        seed: 2,
      );
      // Very unlikely to be identical
      expect(m1.thronePosition == m2.thronePosition, isFalse);
    });
  });

  group('MazeGenerator — fog of war', () {
    test('neighbours of start are visible', () {
      const offsets = [
        MazePosition(0, -1),
        MazePosition(0, 1),
        MazePosition(-1, 0),
        MazePosition(1, 0),
      ];
      for (final d in offsets) {
        final nx = d.x;
        final ny = d.y;
        if (nx < 0 || ny < 0 || nx >= 10 || ny >= 10) continue;
        final room = maze.grid[ny][nx];
        expect(room.status, equals(RoomStatus.visible));
      }
    });

    test('cells further away are hidden', () {
      // (5,5) should be hidden in an unstarted maze
      expect(maze.grid[5][5].status, equals(RoomStatus.hidden));
    });
  });
}

String _key(MazePosition a, MazePosition b) {
  final first = (a.y < b.y || (a.y == b.y && a.x < b.x)) ? a : b;
  final second = first == a ? b : a;
  return '${first.y},${first.x}-${second.y},${second.x}';
}

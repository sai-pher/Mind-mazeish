import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/door_state.dart';
import '../../domain/models/maze_position.dart';
import '../../domain/models/maze_room.dart';
import '../../domain/models/maze_state.dart';
import '../../domain/models/room_status.dart';

class MazeCellWidget extends StatelessWidget {
  final MazeRoom room;
  final MazeState mazeState;
  final bool isPlayer;
  final bool throneDiscovered;

  const MazeCellWidget({
    super.key,
    required this.room,
    required this.mazeState,
    required this.isPlayer,
    required this.throneDiscovered,
  });

  @override
  Widget build(BuildContext context) {
    final status = room.status;
    final pos = room.position;

    if (status == RoomStatus.hidden) {
      return _HiddenCell(pos: pos, mazeState: mazeState);
    }

    return _VisibleCell(
      room: room,
      mazeState: mazeState,
      isPlayer: isPlayer,
      throneDiscovered: throneDiscovered,
    );
  }
}

class _HiddenCell extends StatelessWidget {
  final MazePosition pos;
  final MazeState mazeState;

  const _HiddenCell({required this.pos, required this.mazeState});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: _borderFor(pos, mazeState, hidden: true),
      ),
    );
  }
}

class _VisibleCell extends StatelessWidget {
  final MazeRoom room;
  final MazeState mazeState;
  final bool isPlayer;
  final bool throneDiscovered;

  const _VisibleCell({
    required this.room,
    required this.mazeState,
    required this.isPlayer,
    required this.throneDiscovered,
  });

  Color get _bgColor {
    if (room.isThroneRoom && throneDiscovered) {
      return AppColors.torchGold.withValues(alpha: 0.25);
    }
    return switch (room.status) {
      RoomStatus.answered => AppColors.torchGold.withValues(alpha: 0.2),
      RoomStatus.skipped => AppColors.torchAmber.withValues(alpha: 0.1),
      RoomStatus.visible => AppColors.stone.withValues(alpha: 0.4),
      _ => AppColors.stone,
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget cell = Container(
      decoration: BoxDecoration(
        color: _bgColor,
        border: _borderFor(room.position, mazeState),
      ),
      child: Center(child: _icon),
    );

    if (room.status == RoomStatus.answered) {
      cell = cell
          .animate(key: ValueKey('answered_${room.position}'))
          .shimmer(duration: 800.ms, color: AppColors.torchGold);
    } else if (room.status == RoomStatus.visible) {
      cell = cell
          .animate(key: ValueKey('reveal_${room.position}'))
          .fadeIn(duration: 200.ms)
          .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1));
    }

    return cell;
  }

  Widget? get _icon {
    if (isPlayer) {
      return const Icon(Icons.person, color: AppColors.parchment, size: 14);
    }
    if (room.isThroneRoom && throneDiscovered) {
      return const Icon(Icons.castle, color: AppColors.torchGold, size: 14)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .custom(
            duration: 1200.ms,
            builder: (_, v, child) =>
                Opacity(opacity: 0.6 + v * 0.4, child: child),
          );
    }
    return switch (room.status) {
      RoomStatus.answered =>
        const Icon(Icons.check, color: AppColors.torchGold, size: 10),
      RoomStatus.skipped =>
        const Icon(Icons.fast_forward, color: AppColors.torchAmber, size: 10),
      _ => null,
    };
  }
}

Border _borderFor(
  MazePosition pos,
  MazeState mazeState, {
  bool hidden = false,
}) {
  if (hidden) {
    return Border.all(
        color: AppColors.background.withValues(alpha: 0.3), width: 0.5);
  }

  BorderSide wall =
      const BorderSide(color: AppColors.stoneMid, width: 1.5);
  BorderSide open =
      BorderSide(color: AppColors.stone.withValues(alpha: 0.3), width: 0.5);
  BorderSide wallHeavy =
      const BorderSide(color: AppColors.stoneDark, width: 2.5);

  BorderSide sideFor(MazePosition neighbour) {
    if (neighbour.x < 0 ||
        neighbour.y < 0 ||
        neighbour.x >= 10 ||
        neighbour.y >= 10) {
      return wallHeavy;
    }
    final door = mazeState.doorBetween(pos, neighbour);
    return switch (door) {
      DoorState.wall => wall,
      _ => open,
    };
  }

  return Border(
    top: sideFor(MazePosition(pos.x, pos.y - 1)),
    bottom: sideFor(MazePosition(pos.x, pos.y + 1)),
    left: sideFor(MazePosition(pos.x - 1, pos.y)),
    right: sideFor(MazePosition(pos.x + 1, pos.y)),
  );
}

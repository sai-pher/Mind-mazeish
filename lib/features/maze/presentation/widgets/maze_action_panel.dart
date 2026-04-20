import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/door_state.dart';
import '../../domain/models/maze_position.dart';
import '../../domain/models/maze_state.dart';
import '../../domain/models/maze_status.dart';
import '../providers/maze_state_provider.dart';

class MazeActionPanel extends StatelessWidget {
  final MazeState mazeState;
  final void Function(Direction) onMove;

  const MazeActionPanel({
    super.key,
    required this.mazeState,
    required this.onMove,
  });

  bool _canMove(Direction d) {
    final (dx, dy) = switch (d) {
      Direction.north => (0, -1),
      Direction.south => (0, 1),
      Direction.west => (-1, 0),
      Direction.east => (1, 0),
    };
    final pos = mazeState.playerPosition;
    final nx = pos.x + dx;
    final ny = pos.y + dy;
    if (nx < 0 || ny < 0 || nx >= 10 || ny >= 10) return false;
    final target = MazePosition(nx, ny);
    return mazeState.doorBetween(pos, target) != DoorState.wall;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isNavigating = mazeState.status == MazeStatus.navigating;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.stoneDark,
        border: Border(top: BorderSide(color: AppColors.stoneMid)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lives row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lives  ', style: tt.labelMedium),
              ...List.generate(
                3,
                (i) => Icon(
                  Icons.favorite,
                  size: 20,
                  color: i < mazeState.lives
                      ? AppColors.dangerRed
                      : AppColors.stoneMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Direction arrows
          Column(
            children: [
              _ArrowButton(
                icon: Icons.keyboard_arrow_up,
                enabled: isNavigating && _canMove(Direction.north),
                onTap: () => onMove(Direction.north),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ArrowButton(
                    icon: Icons.keyboard_arrow_left,
                    enabled: isNavigating && _canMove(Direction.west),
                    onTap: () => onMove(Direction.west),
                  ),
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(Icons.explore_outlined,
                          color: AppColors.stoneMid, size: 20),
                    ),
                  ),
                  _ArrowButton(
                    icon: Icons.keyboard_arrow_right,
                    enabled: isNavigating && _canMove(Direction.east),
                    onTap: () => onMove(Direction.east),
                  ),
                ],
              ),
              _ArrowButton(
                icon: Icons.keyboard_arrow_down,
                enabled: isNavigating && _canMove(Direction.south),
                onTap: () => onMove(Direction.south),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: enabled
            ? AppColors.stone
            : AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            color: enabled ? AppColors.torchAmber : AppColors.stoneMid,
            size: 28,
          ),
        ),
      ),
    );
  }
}

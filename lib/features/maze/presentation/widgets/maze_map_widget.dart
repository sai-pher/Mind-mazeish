import 'package:flutter/material.dart';

import '../../domain/models/maze_state.dart';
import 'maze_cell_widget.dart';

class MazeMapWidget extends StatelessWidget {
  final MazeState mazeState;

  const MazeMapWidget({super.key, required this.mazeState});

  @override
  Widget build(BuildContext context) {
    const cellSize = 32.0;
    const gridSize = cellSize * 10;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Center(
        child: SizedBox(
          width: gridSize,
          height: gridSize,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              childAspectRatio: 1,
            ),
            itemCount: 100,
            itemBuilder: (context, index) {
              final x = index % 10;
              final y = index ~/ 10;
              final room = mazeState.grid[y][x];
              final isPlayer = mazeState.playerPosition.x == x &&
                  mazeState.playerPosition.y == y;
              return MazeCellWidget(
                room: room,
                mazeState: mazeState,
                isPlayer: isPlayer,
                throneDiscovered: mazeState.throneDiscovered,
              );
            },
          ),
        ),
      ),
    );
  }
}

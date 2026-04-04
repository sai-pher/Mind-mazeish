import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/domain/models/game_state.dart';
import '../../../gameplay/presentation/providers/game_state_provider.dart';
import '../../../gameplay/presentation/providers/question_provider.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final textTheme = Theme.of(context).textTheme;

    final isGameOver = gameState.status == GameStatus.gameOver;
    final roomsCompleted = gameState.roomsCompleted;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isGameOver ? 'Game Over' : 'Quest Complete!',
                style: textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isGameOver
                    ? 'The dungeon has claimed you…'
                    : 'You have conquered the castle!',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _StatRow(label: 'Final Score', value: '${gameState.score}'),
              const SizedBox(height: 12),
              _StatRow(label: 'Rooms Explored', value: '$roomsCompleted / 10'),
              const SizedBox(height: 12),
              _StatRow(
                  label: 'Lives Remaining', value: '${gameState.lives} / 3'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(gameStateProvider.notifier).restart();
                    ref.read(questionProvider.notifier).reset();
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.torchAmber,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Enter the Castle Again',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stoneMid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.labelLarge),
          Text(
            value,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.torchAmber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

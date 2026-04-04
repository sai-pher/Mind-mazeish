import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/domain/models/game_state.dart';
import '../../../gameplay/presentation/providers/game_state_provider.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gs = ref.watch(gameStateProvider);
    final textTheme = Theme.of(context).textTheme;

    if (gs == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Start'),
          ),
        ),
      );
    }

    final isGameOver = gs.status == GameStatus.gameOver;
    final answered = gs.questionsAnswered;
    final correct = gs.correctCount;
    final stars = _starCount(gs.score, answered, gs.questions.length);
    final newArticles = gs.newArticleUrls.length;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ResultsBackgroundPainter(isGameOver: isGameOver),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    isGameOver
                        ? Icons.sentiment_very_dissatisfied
                        : Icons.emoji_events,
                    size: 72,
                    color: isGameOver ? AppColors.dangerRed : AppColors.torchGold,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.4, 0.4),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    isGameOver ? 'Game Over' : 'Quest Complete!',
                    style: textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: -0.1, end: 0, duration: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    isGameOver
                        ? 'The dungeon has claimed you…'
                        : 'You have mastered the challenge!',
                    style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.65),
                        fontSize: 14),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
                  const SizedBox(height: 24),

                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        color: AppColors.torchGold,
                        size: 36,
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0, 0),
                            end: const Offset(1, 1),
                            duration: 400.ms,
                            delay: Duration(milliseconds: 500 + i * 150),
                            curve: Curves.elasticOut,
                          );
                    }),
                  ),
                  const SizedBox(height: 28),
                  Container(height: 1, color: AppColors.stoneMid)
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 600.ms),
                  const SizedBox(height: 20),

                  // Stats
                  ...[
                    _StatRow(
                        icon: Icons.military_tech,
                        label: 'Final Score',
                        value: '${gs.score}',
                        delay: 650),
                    _StatRow(
                        icon: Icons.check_circle,
                        label: 'Accuracy',
                        value: answered > 0
                            ? '$correct/$answered (${(correct / answered * 100).round()}%)'
                            : '—',
                        delay: 750),
                    _StatRow(
                        icon: Icons.favorite,
                        label: 'Lives Remaining',
                        value: '${gs.lives} / 3',
                        delay: 850,
                        valueColor: gs.lives > 0
                            ? AppColors.dangerRed
                            : AppColors.stoneMid),
                    if (newArticles > 0)
                      _StatRow(
                          icon: Icons.menu_book,
                          label: 'New Articles Found',
                          value: '$newArticles',
                          delay: 950,
                          valueColor: AppColors.torchGold),
                  ].expand((w) => [w, const SizedBox(height: 10)]).toList()
                    ..removeLast(),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(gameStateProvider.notifier).restart();
                        context.go('/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isGameOver ? AppColors.torchAmber : AppColors.torchGold,
                        foregroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text('Play Again',
                          style: textTheme.displaySmall
                              ?.copyWith(color: AppColors.textDark, fontSize: 17)),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 1000.ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _starCount(int score, int answered, int total) {
    if (answered == total && score >= total * 8) return 3;
    if (answered >= total * 0.6 && score >= total * 4) return 2;
    if (score >= 10) return 1;
    return 0;
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int delay;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.delay,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stoneMid),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.torchAmber, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: textTheme.labelLarge)),
          Text(value,
              style: textTheme.labelLarge?.copyWith(
                  color: valueColor ?? AppColors.torchAmber,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: delay))
        .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }
}

class _ResultsBackgroundPainter extends CustomPainter {
  final bool isGameOver;
  const _ResultsBackgroundPainter({required this.isGameOver});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = AppColors.background);
    final stonePaint = Paint()
      ..color = AppColors.stone.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * 0.06, size.height), stonePaint);
    canvas.drawRect(
        Rect.fromLTWH(
            size.width * 0.94, 0, size.width * 0.06, size.height),
        stonePaint);
    final glowColor =
        isGameOver ? AppColors.dangerRed : AppColors.torchGold;
    final glow = Paint()
      ..color = glowColor.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.25), 180, glow);
  }

  @override
  bool shouldRepaint(_ResultsBackgroundPainter old) =>
      old.isGameOver != isGameOver;
}

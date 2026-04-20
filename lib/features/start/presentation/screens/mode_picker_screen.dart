import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import '../../../settings/data/game_stats_repository.dart';

class ModePickerScreen extends StatefulWidget {
  const ModePickerScreen({super.key});

  @override
  State<ModePickerScreen> createState() => _ModePickerScreenState();
}

class _ModePickerScreenState extends State<ModePickerScreen> {
  int _endlessHighScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final stats = await GameStatsRepository.load();
    if (mounted) setState(() => _endlessHighScore = stats.endlessHighScore);
  }

  void _selectMode(GameMode mode) {
    context.push(
      '/game-settings',
      extra: {'mode': mode},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.stoneDark,
        title: const Text('Select Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  Expanded(
                    child: _ModeCard(
                      title: 'Standard',
                      subtitle: '3 lives · fixed question count · earn stars',
                      painter: const _DoorPainter(),
                      highlightColor: AppColors.torchAmber,
                      extraBadge: null,
                      onSelect: () => _selectMode(GameMode.standard),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _ModeCard(
                      title: 'Endless',
                      subtitle: 'No finish line · streak rewards · life recovery',
                      painter: const _CorridorPainter(),
                      highlightColor: AppColors.torchGold,
                      extraBadge: _endlessHighScore > 0
                          ? 'Best: $_endlessHighScore pts'
                          : null,
                      onSelect: () => _selectMode(GameMode.endless),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 150.ms)
                        .slideY(begin: 0.08, end: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode card
// ---------------------------------------------------------------------------

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final CustomPainter painter;
  final Color highlightColor;
  final String? extraBadge;
  final VoidCallback onSelect;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.painter,
    required this.highlightColor,
    required this.extraBadge,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: painter)),
          InkWell(
            onTap: onSelect,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Illustration area
                const Expanded(flex: 3, child: SizedBox.shrink()),
                // Bottom info + select button
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  color: AppColors.stoneDark.withValues(alpha: 0.88),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: tt.titleLarge?.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (extraBadge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.torchGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.torchGold, width: 1),
                              ),
                              child: Text(
                                extraBadge!,
                                style: tt.labelSmall?.copyWith(
                                  color: AppColors.torchGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.textLight.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onSelect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: highlightColor,
                            foregroundColor: AppColors.textDark,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text(
                            'Select',
                            style: tt.labelLarge?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Stone arch door — Standard mode illustration.
class _DoorPainter extends CustomPainter {
  const _DoorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.stone.withValues(alpha: 0.35),
    );

    final cx = size.width / 2;
    final archW = size.width * 0.48;
    final pillarW = archW * 0.16;
    final archTop = size.height * 0.08;
    final archBodyH = size.height * 0.54;

    final stonePaint = Paint()
      ..color = AppColors.stoneDark.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    // Left pillar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - archW / 2, archTop, pillarW, archBodyH),
        const Radius.circular(3),
      ),
      stonePaint,
    );
    // Right pillar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + archW / 2 - pillarW, archTop, pillarW, archBodyH),
        const Radius.circular(3),
      ),
      stonePaint,
    );
    // Arch top
    final innerW = archW - pillarW;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, archTop + innerW * 0.22),
        width: innerW,
        height: innerW * 0.44,
      ),
      3.14159,
      3.14159,
      true,
      stonePaint,
    );

    // Warm torch glow from below
    final glowPaint = Paint()
      ..color = AppColors.torchAmber.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
    canvas.drawCircle(Offset(cx, size.height * 0.9), size.width * 0.45, glowPaint);
  }

  @override
  bool shouldRepaint(_DoorPainter old) => false;
}

/// Receding dark corridor — Endless mode illustration.
class _CorridorPainter extends CustomPainter {
  const _CorridorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    final cx = size.width / 2;
    final cy = size.height * 0.38;
    final vp = Offset(cx, cy); // vanishing point

    final linePaint = Paint()
      ..color = AppColors.stoneMid.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    // Draw perspective lines from four corners + midpoints toward vanishing point
    final edgePoints = [
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
    ];
    for (final pt in edgePoints) {
      canvas.drawLine(pt, vp, linePaint);
    }

    // Concentric rectangles (floor/wall tiles)
    for (int i = 1; i <= 3; i++) {
      final t = i * 0.18;
      final r = Rect.fromCenter(
        center: vp,
        width: size.width * t,
        height: size.height * t,
      );
      canvas.drawRect(r, linePaint);
    }

    // Gold glow at vanishing point
    final glowPaint = Paint()
      ..color = AppColors.torchGold.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    canvas.drawCircle(vp, size.width * 0.28, glowPaint);
  }

  @override
  bool shouldRepaint(_CorridorPainter old) => false;
}

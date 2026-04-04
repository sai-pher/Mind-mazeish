import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background arch painting
          Positioned.fill(
            child: CustomPaint(painter: _StartBackgroundPainter()),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Torch glow icon
                    const Icon(
                      Icons.local_fire_department,
                      size: 72,
                      color: AppColors.torchAmber,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .custom(
                          duration: 1800.ms,
                          builder: (_, value, child) => Opacity(
                            opacity: 0.7 + (value * 0.3),
                            child: child,
                          ),
                        ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'MIND',
                      style: textTheme.displayLarge?.copyWith(fontSize: 52),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: -0.2, end: 0, duration: 700.ms),

                    Text(
                      'MAZEISH',
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 42,
                        color: AppColors.torchGold,
                        letterSpacing: 6,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 700.ms, delay: 150.ms)
                        .slideY(begin: 0.2, end: 0, duration: 700.ms),

                    const SizedBox(height: 12),

                    Container(
                      height: 1.5,
                      width: size.width * 0.5,
                      color: AppColors.torchAmber.withValues(alpha: 0.4),
                    ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                    const SizedBox(height: 16),

                    Text(
                      'A medieval castle awaits.\nAre you wise enough to conquer it?',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.75),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 500.ms),

                    const SizedBox(height: 48),

                    // Enter button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/game'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.torchAmber,
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 8,
                          shadowColor:
                              AppColors.torchAmber.withValues(alpha: 0.4),
                        ),
                        child: Text(
                          'Enter the Castle',
                          style: textTheme.displaySmall?.copyWith(
                            color: AppColors.textDark,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 700.ms)
                        .slideY(begin: 0.3, end: 0, duration: 500.ms),

                    const SizedBox(height: 24),

                    Text(
                      '10 rooms  •  3 lives  •  Wikipedia-powered',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 900.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deep dungeon gradient-like blocks
    final bgPaint = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final stonePaint = Paint()
      ..color = AppColors.stone.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final archW = size.width * 0.8;
    final path = Path();

    // Left pillar
    path.addRect(
        Rect.fromLTWH(cx - archW / 2, 0, archW * 0.12, size.height));
    // Right pillar
    path.addRect(Rect.fromLTWH(
        cx + archW / 2 - archW * 0.12, 0, archW * 0.12, size.height));
    // Arch at top
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.18),
          width: archW,
          height: archW * 0.55),
      3.14159,
      3.14159,
    );
    canvas.drawPath(path, stonePaint);

    // Ambient torch glow at bottom corners
    final glowPaint = Paint()
      ..color = AppColors.torchAmber.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(0, size.height), 120, glowPaint);
    canvas.drawCircle(Offset(size.width, size.height), 120, glowPaint);

    // Top glow behind title
    final topGlow = Paint()
      ..color = AppColors.torchAmber.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    canvas.drawCircle(Offset(cx, size.height * 0.35), 160, topGlow);
  }

  @override
  bool shouldRepaint(_StartBackgroundPainter old) => false;
}

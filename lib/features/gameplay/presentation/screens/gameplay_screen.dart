import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class GameplayScreen extends StatelessWidget {
  const GameplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Castle Entrance'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Score: 0',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.torchAmber,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Room illustration area
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            color: AppColors.stoneDark,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Arch silhouette placeholder
                CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: _CastleArchPainter(),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.castle,
                      size: 80,
                      color: AppColors.torchAmber.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Castle Entrance',
                      style: textTheme.displaySmall?.copyWith(
                        color: AppColors.torchAmber.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Question card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Parchment question card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What was the primary purpose of a medieval castle drawbridge?',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 16,
                                color: AppColors.torchAmber.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Source: Drawbridge — Wikipedia',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.torchAmber,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.torchAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2x2 Answer grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: const [
                      _AnswerButton(label: 'A', text: 'Control river flooding'),
                      _AnswerButton(label: 'B', text: 'Control castle entry'),
                      _AnswerButton(label: 'C', text: 'Decoration only'),
                      _AnswerButton(label: 'D', text: 'Catapult platform'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1 / 10 rooms',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textLight.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 0.1,
                          minHeight: 10,
                          backgroundColor: AppColors.stoneDark,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.torchAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final String text;

  const _AnswerButton({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.stone,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        splashColor: AppColors.torchAmber.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.stoneMid),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.torchAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.torchAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: textTheme.labelMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CastleArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.stone.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final archWidth = size.width * 0.5;
    final archHeight = size.height * 0.85;

    // Left pillar
    path.addRect(Rect.fromLTWH(
      centerX - archWidth / 2,
      size.height * 0.3,
      archWidth * 0.15,
      archHeight,
    ));
    // Right pillar
    path.addRect(Rect.fromLTWH(
      centerX + archWidth / 2 - archWidth * 0.15,
      size.height * 0.3,
      archWidth * 0.15,
      archHeight,
    ));
    // Arch top
    final archRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.45),
      width: archWidth,
      height: archWidth * 0.7,
    );
    path.addArc(archRect, 3.14159, 3.14159);

    canvas.drawPath(path, paint);

    // Torch glow hints
    final glowPaint = Paint()
      ..color = AppColors.torchAmber.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(
      Offset(centerX - archWidth / 2 - 10, size.height * 0.4),
      40,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(centerX + archWidth / 2 + 10, size.height * 0.4),
      40,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_CastleArchPainter oldDelegate) => false;
}

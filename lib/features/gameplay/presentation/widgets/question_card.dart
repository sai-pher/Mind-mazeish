import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onArticleTap;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onArticleTap,
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book,
                    size: 15,
                    color: AppColors.torchAmber,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Source: ${question.articleTitle}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.torchAmber,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.torchAmber,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new,
                    size: 12,
                    color: AppColors.torchAmber,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

class QuestionCardSkeleton extends StatelessWidget {
  const QuestionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonLine(width: double.infinity, height: 14),
            SizedBox(height: 8),
            _SkeletonLine(width: double.infinity, height: 14),
            SizedBox(height: 8),
            _SkeletonLine(width: 200, height: 14),
            SizedBox(height: 16),
            _SkeletonLine(width: 160, height: 12),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: AppColors.torchAmber.withValues(alpha: 0.15),
        );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.stoneMid.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

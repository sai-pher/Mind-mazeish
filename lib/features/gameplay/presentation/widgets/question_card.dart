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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question text
            Expanded(
              child: Text(
                question.question,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Embedded Wikipedia icon button
            Tooltip(
              message: question.articleTitle,
              child: GestureDetector(
                onTap: onArticleTap,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.torchAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.torchAmber.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 18,
                    color: AppColors.torchAmber,
                  ),
                ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  _SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  _SkeletonLine(width: 200, height: 14),
                ],
              ),
            ),
            SizedBox(width: 10),
            _SkeletonLine(width: 34, height: 34),
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

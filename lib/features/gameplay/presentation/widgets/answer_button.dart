import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

enum AnswerState { idle, correct, wrong }

class AnswerButton extends StatelessWidget {
  final String label;
  final String text;
  final AnswerState state;
  final VoidCallback? onTap;

  const AnswerButton({
    super.key,
    required this.label,
    required this.text,
    this.state = AnswerState.idle,
    this.onTap,
  });

  Color get _backgroundColor {
    return switch (state) {
      AnswerState.correct => AppColors.torchGold.withValues(alpha: 0.3),
      AnswerState.wrong => AppColors.dangerRed.withValues(alpha: 0.3),
      AnswerState.idle => AppColors.stone,
    };
  }

  Color get _borderColor {
    return switch (state) {
      AnswerState.correct => AppColors.torchGold,
      AnswerState.wrong => AppColors.dangerRed,
      AnswerState.idle => AppColors.stoneMid,
    };
  }

  Color get _labelColor {
    return switch (state) {
      AnswerState.correct => AppColors.torchGold,
      AnswerState.wrong => AppColors.dangerRed,
      AnswerState.idle => AppColors.torchAmber,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget button = Material(
      color: _backgroundColor,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: state == AnswerState.idle ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        splashColor: AppColors.torchAmber.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _labelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: _labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: textTheme.labelMedium?.copyWith(fontSize: 13),
                ),
              ),
              if (state == AnswerState.correct)
                const Icon(Icons.check_circle,
                    color: AppColors.torchGold, size: 18),
              if (state == AnswerState.wrong)
                const Icon(Icons.cancel, color: AppColors.dangerRed, size: 18),
            ],
          ),
        ),
      ),
    );

    if (state == AnswerState.correct) {
      button = button
          .animate()
          .shimmer(duration: 600.ms, color: AppColors.torchGold);
    } else if (state == AnswerState.wrong) {
      button = button.animate().shake(duration: 400.ms, hz: 4);
    }

    return button;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/domain/models/question.dart';
import '../../../gameplay/presentation/widgets/answer_button.dart';
import '../../../gameplay/presentation/widgets/question_card.dart';
import '../../domain/models/maze_state.dart';
import '../../domain/models/maze_status.dart';
import '../providers/maze_state_provider.dart';
import '../widgets/maze_action_panel.dart';
import '../widgets/maze_map_widget.dart';

class MazeScreen extends ConsumerStatefulWidget {
  const MazeScreen({super.key});

  @override
  ConsumerState<MazeScreen> createState() => _MazeScreenState();
}

class _MazeScreenState extends ConsumerState<MazeScreen> {
  bool _sheetOpen = false;
  bool _endShown = false;

  @override
  Widget build(BuildContext context) {
    final mazeState = ref.watch(mazeStateProvider);

    ref.listen<MazeState?>(mazeStateProvider, (prev, next) {
      if (next == null) return;

      if (next.status == MazeStatus.questionActive && !_sheetOpen) {
        _openQuestionSheet(next);
      }

      if ((next.isComplete || next.isGameOver) && !_endShown) {
        _endShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showEndSheet(next);
        });
      }
    });

    if (mazeState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.stoneDark,
        title: const Text('The Maze'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${mazeState.roomsVisited}/100',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textLight.withValues(alpha: 0.6),
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: MazeMapWidget(mazeState: mazeState)),
          MazeActionPanel(
            mazeState: mazeState,
            onMove: (d) =>
                ref.read(mazeStateProvider.notifier).movePlayer(d),
          ),
        ],
      ),
    );
  }

  Future<void> _openQuestionSheet(MazeState mazeState) async {
    _sheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionSheet(mazeState: mazeState),
    );
    _sheetOpen = false;
  }

  void _showEndSheet(MazeState maze) {
    final isComplete = maze.isComplete;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.stoneDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EndSheet(maze: maze, isComplete: isComplete),
    );
  }

  void _confirmExit() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.stoneDark,
        title: const Text('Abandon Maze?',
            style: TextStyle(color: AppColors.textLight)),
        content: const Text(
          'Your progress will be lost.',
          style: TextStyle(color: AppColors.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Stay',
                style: TextStyle(color: AppColors.torchAmber)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(mazeStateProvider.notifier).restart();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: AppColors.textLight,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

// ── Question bottom sheet ──────────────────────────────────────────────────

class _QuestionSheet extends ConsumerStatefulWidget {
  final MazeState mazeState;

  const _QuestionSheet({required this.mazeState});

  @override
  ConsumerState<_QuestionSheet> createState() => _QuestionSheetState();
}

class _QuestionSheetState extends ConsumerState<_QuestionSheet> {
  int? _selectedIndex;
  bool _locked = false;

  @override
  Widget build(BuildContext context) {
    final mazeState = ref.watch(mazeStateProvider) ?? widget.mazeState;
    final q = mazeState.activeQuestion ?? widget.mazeState.activeQuestion;
    if (q == null) return const SizedBox.shrink();

    final isRevealed = mazeState.status == MazeStatus.answerRevealed;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.stoneDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stoneMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              QuestionCard(question: q, onArticleTap: null),
              const SizedBox(height: 12),
              ...List.generate(q.options.length, (i) {
                AnswerState state = AnswerState.idle;
                if (isRevealed) {
                  if (i == q.correctIndex) {
                    state = AnswerState.correct;
                  } else if (i == _selectedIndex) {
                    state = AnswerState.wrong;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnswerButton(
                    label: String.fromCharCode(65 + i),
                    text: q.options[i],
                    state: state,
                    onTap: _locked ? null : () => _handleAnswer(i, q),
                  ),
                );
              }),
              if (isRevealed) ...[
                const SizedBox(height: 8),
                _FunFactTile(
                  funFact: q.funFact,
                  correct: mazeState.lastAnswerCorrect ?? false,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (mazeState.isGameOver) {
                        // Don't dismiss — let the end sheet handle it.
                        Navigator.of(context).pop();
                      } else {
                        ref
                            .read(mazeStateProvider.notifier)
                            .dismissFunFact();
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.torchAmber,
                      foregroundColor: AppColors.textDark,
                    ),
                    child: Text(
                        mazeState.isGameOver ? 'See Results' : 'Onward!'),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _locked
                      ? null
                      : () {
                          ref.read(mazeStateProvider.notifier).skipRoom();
                          Navigator.of(context).pop();
                        },
                  child: const Text(
                    'Skip this room',
                    style: TextStyle(color: AppColors.stoneMid, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAnswer(int index, QuizQuestion q) async {
    if (_locked) return;
    setState(() {
      _selectedIndex = index;
      _locked = true;
    });
    HapticFeedback.mediumImpact();
    ref.read(mazeStateProvider.notifier).submitAnswer(index);
  }
}

// ── End sheet ──────────────────────────────────────────────────────────────

class _EndSheet extends ConsumerWidget {
  final MazeState maze;
  final bool isComplete;

  const _EndSheet({required this.maze, required this.isComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete
                ? Icons.castle
                : Icons.sentiment_very_dissatisfied,
            size: 56,
            color: isComplete ? AppColors.torchGold : AppColors.dangerRed,
          )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),
          Text(
            isComplete ? 'Throne Room Reached!' : 'The Maze Claims You…',
            style: tt.displaySmall?.copyWith(
              color:
                  isComplete ? AppColors.torchGold : AppColors.dangerRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _StatLine(label: 'Rooms Visited', value: '${maze.roomsVisited}'),
          const SizedBox(height: 4),
          _StatLine(
            label: 'Questions Correct',
            value: '${maze.correctCount} / ${maze.questionsAnswered}',
          ),
          const SizedBox(height: 4),
          _StatLine(
            label: 'Lives Remaining',
            value: '${maze.lives} / 3',
            valueColor:
                maze.lives > 0 ? AppColors.dangerRed : AppColors.stoneMid,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(mazeStateProvider.notifier).restart();
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isComplete
                    ? AppColors.torchGold
                    : AppColors.torchAmber,
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Back to Start',
                style: tt.displaySmall
                    ?.copyWith(color: AppColors.textDark, fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: tt.bodySmall?.copyWith(color: AppColors.textLight)),
        Text(
          value,
          style: tt.labelMedium?.copyWith(
            color: valueColor ?? AppColors.torchAmber,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Fun fact tile ──────────────────────────────────────────────────────────

class _FunFactTile extends StatelessWidget {
  final String funFact;
  final bool correct;

  const _FunFactTile({required this.funFact, required this.correct});

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.torchGold : AppColors.dangerRed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? '✓ Correct!' : '✗ Wrong',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            funFact,
            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

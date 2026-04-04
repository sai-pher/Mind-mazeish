import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/question.dart';
import '../providers/game_state_provider.dart';
import '../providers/question_provider.dart';
import '../widgets/answer_button.dart';
import '../widgets/question_card.dart';
import '../widgets/room_header.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key});

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  int? _selectedIndex;
  bool _answerLocked = false;

  @override
  void initState() {
    super.initState();
    // Kick off the first question fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestionForCurrentRoom();
    });
  }

  void _fetchQuestionForCurrentRoom() {
    final gameState = ref.read(gameStateProvider);
    if (gameState.status == GameStatus.loading ||
        gameState.status == GameStatus.idle) {
      ref
          .read(questionProvider.notifier)
          .fetchQuestion(gameState.currentRoom.theme);
    }
  }

  Future<void> _handleAnswer(int index, Question question) async {
    if (_answerLocked) return;
    setState(() {
      _selectedIndex = index;
      _answerLocked = true;
    });

    final correct = question.isCorrect(index);
    HapticFeedback.mediumImpact();

    ref.read(gameStateProvider.notifier).answerQuestion(correct: correct);

    // Show fun fact bottom sheet
    if (mounted) {
      await _showFunFact(question.funFact, correct);
    }

    final gameState = ref.read(gameStateProvider);
    if (gameState.isGameOver) {
      if (mounted) context.go('/results');
      return;
    }
    if (gameState.isComplete) {
      if (mounted) context.go('/results');
      return;
    }

    // Advance to next room
    await Future.delayed(const Duration(milliseconds: 200));
    ref.read(gameStateProvider.notifier).advanceRoom();
    ref.read(questionProvider.notifier).reset();

    setState(() {
      _selectedIndex = null;
      _answerLocked = false;
    });

    // Fetch question for new room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestionForCurrentRoom();
    });
  }

  Future<void> _showFunFact(String funFact, bool correct) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.stoneDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.stoneMid),
      ),
      builder: (ctx) => _FunFactSheet(funFact: funFact, correct: correct),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final questionAsync = ref.watch(questionProvider);
    final room = gameState.currentRoom;

    return Scaffold(
      appBar: RoomHeader(
        roomName: room.name,
        score: gameState.score,
        lives: gameState.lives,
      ),
      body: Column(
        children: [
          // Room illustration
          _RoomIllustration(roomId: room.id),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  // Question area
                  questionAsync.when(
                    loading: () => const QuestionCardSkeleton(),
                    error: (e, _) => _ErrorCard(
                      onRetry: _fetchQuestionForCurrentRoom,
                    ),
                    data: (question) {
                      if (question == null) {
                        return const QuestionCardSkeleton();
                      }
                      return Column(
                        children: [
                          QuestionCard(
                            question: question,
                            onArticleTap: () => context.go(
                              '/article',
                              extra: {
                                'url': question.articleUrl,
                                'title': question.articleTitle,
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          _AnswerGrid(
                            question: question,
                            selectedIndex: _selectedIndex,
                            onAnswer: (i) => _handleAnswer(i, question),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  _ProgressBar(
                    current: gameState.currentRoomIndex + 1,
                    total: gameState.rooms.length,
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

// ---------------------------------------------------------------------------
// Room illustration
// ---------------------------------------------------------------------------

class _RoomIllustration extends StatelessWidget {
  final String roomId;

  const _RoomIllustration({required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.30,
      width: double.infinity,
      color: AppColors.stoneDark,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _CastleArchPainter(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _roomIcon(roomId),
                size: 64,
                color: AppColors.torchAmber.withValues(alpha: 0.7),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .custom(
                    duration: 3000.ms,
                    builder: (context, value, child) => Opacity(
                      opacity: 0.6 + (value * 0.15),
                      child: child,
                    ),
                  ),
              const SizedBox(height: 6),
            ],
          ),
        ],
      ),
    );
  }

  IconData _roomIcon(String id) {
    return switch (id) {
      'entrance' => Icons.castle,
      'throne' => Icons.chair,
      'library' => Icons.library_books,
      'dungeon' => Icons.lock,
      'chapel' => Icons.church,
      'armory' => Icons.shield,
      'kitchen' => Icons.restaurant,
      'observatory' => Icons.nights_stay,
      'garden' => Icons.local_florist,
      'tower' => Icons.location_city,
      _ => Icons.castle,
    };
  }
}

// ---------------------------------------------------------------------------
// Answer grid
// ---------------------------------------------------------------------------

class _AnswerGrid extends StatelessWidget {
  final Question question;
  final int? selectedIndex;
  final void Function(int) onAnswer;

  const _AnswerGrid({
    required this.question,
    required this.selectedIndex,
    required this.onAnswer,
  });

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: List.generate(question.options.length, (i) {
        AnswerState state = AnswerState.idle;
        if (selectedIndex != null) {
          if (i == question.correctIndex) {
            state = AnswerState.correct;
          } else if (i == selectedIndex && i != question.correctIndex) {
            state = AnswerState.wrong;
          }
        }

        return AnswerButton(
          label: _labels[i],
          text: question.options[i],
          state: state,
          onTap: () => onAnswer(i),
        );
      }),
    ).animate().fadeIn(duration: 300.ms, delay: 150.ms);
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = current / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$current / $total rooms',
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.textLight.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.stoneDark,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.torchAmber,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error card
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.dangerRed, size: 36),
            const SizedBox(height: 10),
            Text(
              'The oracle is silent…',
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Could not fetch a question. Check your connection and try again.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.torchAmber,
                foregroundColor: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fun fact bottom sheet
// ---------------------------------------------------------------------------

class _FunFactSheet extends StatelessWidget {
  final String funFact;
  final bool correct;

  const _FunFactSheet({required this.funFact, required this.correct});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.star : Icons.info_outline,
                  color: correct ? AppColors.torchGold : AppColors.torchAmber,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    correct ? 'Correct!' : 'Not quite…',
                    style: textTheme.displaySmall?.copyWith(
                      color: correct
                          ? AppColors.torchGold
                          : AppColors.textLight,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.stone,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.stoneMid),
              ),
              child: Text(
                funFact,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      correct ? AppColors.torchGold : AppColors.torchAmber,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  correct ? 'Onward!' : 'Continue',
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
    );
  }
}

// ---------------------------------------------------------------------------
// Castle arch background painter
// ---------------------------------------------------------------------------

class _CastleArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stonePaint = Paint()
      ..color = AppColors.stone.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final w = size.width * 0.55;
    final path = Path();

    // Left pillar
    path.addRect(Rect.fromLTWH(cx - w / 2, size.height * 0.25, w * 0.14,
        size.height));
    // Right pillar
    path.addRect(Rect.fromLTWH(cx + w / 2 - w * 0.14, size.height * 0.25,
        w * 0.14, size.height));
    // Arch
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.42),
          width: w,
          height: w * 0.65),
      3.14159,
      3.14159,
    );
    canvas.drawPath(path, stonePaint);

    // Torch glow spots
    final glowPaint = Paint()
      ..color = AppColors.torchAmber.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
        Offset(cx - w / 2 - 12, size.height * 0.38), 38, glowPaint);
    canvas.drawCircle(
        Offset(cx + w / 2 + 12, size.height * 0.38), 38, glowPaint);
  }

  @override
  bool shouldRepaint(_CastleArchPainter old) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/topic_registry.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/quiz_config.dart';
import '../../domain/models/question.dart';
import '../providers/game_state_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markPlaying();
    });
  }

  void _markPlaying() {
    final gs = ref.read(gameStateProvider);
    if (gs != null && gs.status == GameStatus.loading) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) ref.read(gameStateProvider.notifier).markPlaying();
      });
    }
  }

  Future<void> _handleAnswer(int index, QuizQuestion question) async {
    if (_answerLocked) return;
    setState(() {
      _selectedIndex = index;
      _answerLocked = true;
    });

    final correct = question.isCorrect(index);
    HapticFeedback.mediumImpact();
    final reward =
        ref.read(gameStateProvider)?.pendingStreakReward(correct: correct);
    ref.read(gameStateProvider.notifier).answerQuestion(correct: correct);
    final streakLimit =
        ref.read(gameStateProvider)?.config.streakLimit ?? 10;

    if (mounted) await _showFunFact(question.funFact, correct, reward: reward, streakLimit: streakLimit);

    final gs = ref.read(gameStateProvider);
    if (gs == null) return;
    if (gs.isGameOver || gs.isComplete) {
      if (mounted) context.go('/results');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 200));
    ref.read(gameStateProvider.notifier).advanceQuestion();

    setState(() {
      _selectedIndex = null;
      _answerLocked = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _markPlaying());
  }

  Future<void> _showFunFact(
    String funFact,
    bool correct, {
    StreakReward? reward,
    int streakLimit = 10,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.stoneDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.stoneMid),
      ),
      builder: (ctx) => _FunFactSheet(
        funFact: funFact,
        correct: correct,
        reward: reward,
        streakLimit: streakLimit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = ref.watch(gameStateProvider);

    if (gs == null) {
      // Shouldn't happen — go back to start
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppColors.torchAmber)));
    }

    final question = gs.currentQuestion;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.stoneDark,
            title: Text('Abandon the Quest?',
                style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    color: AppColors.torchAmber)),
            content: Text('Your progress will be lost.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Stay',
                      style: TextStyle(color: AppColors.torchAmber))),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Leave',
                      style: TextStyle(color: AppColors.dangerRed))),
            ],
          ),
        );
        if (leave == true && context.mounted) {
          ref.read(gameStateProvider.notifier).restart();
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: RoomHeader(
          roomName: topicName(question.topicId),
          score: gs.score,
          lives: gs.lives,
          streak: gs.streak,
          isEndless: gs.config.gameMode == GameMode.endless,
        ),
        body: Column(
          children: [
            _TopicIllustration(topicId: question.topicId),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    if (gs.status == GameStatus.loading)
                      const QuestionCardSkeleton()
                    else ...[
                      QuestionCard(
                        question: question,
                        onArticleTap: question.articleUrl.isEmpty
                            ? null
                            : () => context.push('/article', extra: {
                                  'url': question.articleUrl,
                                  'title': question.articleTitle,
                                  'topicId': question.topicId,
                                }),
                      ),
                      const SizedBox(height: 14),
                      _AnswerGrid(
                        question: question,
                        selectedIndex: _selectedIndex,
                        onAnswer: (i) => _handleAnswer(i, question),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _ProgressBar(
                      current: gs.currentQuestionIndex + 1,
                      total: gs.questions.length,
                    ),
                  ],
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
// Topic illustration
// ---------------------------------------------------------------------------

class _TopicIllustration extends StatelessWidget {
  final String topicId;

  const _TopicIllustration({required this.topicId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.22,
      width: double.infinity,
      color: AppColors.stoneDark,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _ArchPainter()),
          Text(
            topicEmoji(topicId),
            style: const TextStyle(fontSize: 58),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .custom(
                duration: 3000.ms,
                builder: (_, v, child) =>
                    Opacity(opacity: 0.75 + v * 0.25, child: child),
              ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Answer grid
// ---------------------------------------------------------------------------

class _AnswerGrid extends StatelessWidget {
  final QuizQuestion question;
  final int? selectedIndex;
  final void Function(int) onAnswer;

  const _AnswerGrid(
      {required this.question,
      required this.selectedIndex,
      required this.onAnswer});

  static const _labels = ['A', 'B', 'C', 'D'];

  AnswerState _stateFor(int i) {
    if (selectedIndex == null) return AnswerState.idle;
    if (i == question.correctIndex) return AnswerState.correct;
    if (i == selectedIndex) return AnswerState.wrong;
    return AnswerState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final buttons = List.generate(question.options.length, (i) {
      return Expanded(
        child: AnswerButton(
          label: _labels[i],
          text: question.options[i],
          state: _stateFor(i),
          onTap: () => onAnswer(i),
        ),
      );
    });

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buttons[0], const SizedBox(width: 10), buttons[1]],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buttons[2], const SizedBox(width: 10), buttons[3]],
          ),
        ),
      ],
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
        Text('$current / $total questions',
            style: textTheme.labelMedium?.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.6),
                fontSize: 12)),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: AppColors.stoneDark,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.torchAmber),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fun fact sheet
// ---------------------------------------------------------------------------

class _FunFactSheet extends StatelessWidget {
  final String funFact;
  final bool correct;
  final StreakReward? reward;
  final int streakLimit;

  const _FunFactSheet({
    required this.funFact,
    required this.correct,
    this.reward,
    this.streakLimit = 10,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(correct ? Icons.star : Icons.info_outline,
                  color: correct ? AppColors.torchGold : AppColors.torchAmber,
                  size: 24),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(correct ? 'Correct!' : 'Not quite…',
                      style: textTheme.displaySmall?.copyWith(
                          color: correct
                              ? AppColors.torchGold
                              : AppColors.textLight,
                          fontSize: 18))),
            ]),
            if (reward != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: reward == StreakReward.lifeRestored
                      ? AppColors.dangerRed.withValues(alpha: 0.15)
                      : AppColors.torchGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: reward == StreakReward.lifeRestored
                        ? AppColors.dangerRed
                        : AppColors.torchGold,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      reward == StreakReward.lifeRestored
                          ? Icons.favorite
                          : Icons.bolt,
                      size: 16,
                      color: reward == StreakReward.lifeRestored
                          ? AppColors.dangerRed
                          : AppColors.torchGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reward == StreakReward.lifeRestored
                          ? 'Streak! Life restored ❤️'
                          : 'Streak! +${streakLimit * 10} bonus points ⚡',
                      style: textTheme.labelMedium?.copyWith(
                        color: reward == StreakReward.lifeRestored
                            ? AppColors.dangerRed
                            : AppColors.torchGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.stone,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.stoneMid)),
              child: Text(funFact,
                  style: textTheme.labelMedium
                      ?.copyWith(color: AppColors.textLight, height: 1.5)),
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
                child: Text(correct ? 'Onward!' : 'Continue',
                    style: textTheme.labelLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arch painter
// ---------------------------------------------------------------------------

class _ArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stonePaint = Paint()
      ..color = AppColors.stone.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final w = size.width * 0.55;
    final path = Path();
    path.addRect(
        Rect.fromLTWH(cx - w / 2, size.height * 0.25, w * 0.14, size.height));
    path.addRect(Rect.fromLTWH(cx + w / 2 - w * 0.14, size.height * 0.25,
        w * 0.14, size.height));
    path.addArc(
        Rect.fromCenter(
            center: Offset(cx, size.height * 0.42),
            width: w,
            height: w * 0.65),
        3.14159, 3.14159);
    canvas.drawPath(path, stonePaint);
    final glow = Paint()
      ..color = AppColors.torchAmber.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(Offset(cx - w / 2 - 12, size.height * 0.38), 38, glow);
    canvas.drawCircle(Offset(cx + w / 2 + 12, size.height * 0.38), 38, glow);
  }

  @override
  bool shouldRepaint(_ArchPainter old) => false;
}

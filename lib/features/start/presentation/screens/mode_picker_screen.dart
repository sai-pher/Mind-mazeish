import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/data/topic_registry.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import '../../../gameplay/presentation/providers/game_state_provider.dart';
import '../../../gameplay/presentation/providers/quiz_config_provider.dart';
import '../../../settings/data/game_stats_repository.dart';

class ModePickerScreen extends ConsumerStatefulWidget {
  const ModePickerScreen({super.key});

  @override
  ConsumerState<ModePickerScreen> createState() => _ModePickerScreenState();
}

class _ModePickerScreenState extends ConsumerState<ModePickerScreen> {
  int _difficultyBias = 3;
  int _questionCount = 10;
  int _endlessHighScore = 0;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(quizConfigProvider);
    _difficultyBias = config.difficultyBias;
    _questionCount = config.questionCount;
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final stats = await GameStatsRepository.load();
    if (mounted) setState(() => _endlessHighScore = stats.endlessHighScore);
  }

  Future<void> _startGame(GameMode mode) async {
    if (_starting) return;
    setState(() => _starting = true);
    final currentConfig = ref.read(quizConfigProvider);
    final topicIds = currentConfig.selectedTopicIds.isEmpty
        ? Set<String>.from(allTopicIds)
        : currentConfig.selectedTopicIds;
    final config = QuizConfig(
      selectedTopicIds: topicIds,
      questionCount: _questionCount,
      gameMode: mode,
      difficultyBias: _difficultyBias,
    );
    ref.read(quizConfigProvider.notifier).setConfig(config);
    await ref.read(gameStateProvider.notifier).startGame(config);
    if (mounted) context.go('/game');
  }

  void _openTopics(GameMode mode) {
    final currentConfig = ref.read(quizConfigProvider);
    ref.read(quizConfigProvider.notifier).setConfig(
      currentConfig.copyWith(
        gameMode: mode,
        difficultyBias: _difficultyBias,
        questionCount: _questionCount,
      ),
    );
    context.push('/topics');
  }

  void _openSettings(GameMode mode) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.stoneDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => _ModeSettingsSheet(
        mode: mode,
        initialDifficultyBias: _difficultyBias,
        initialQuestionCount: _questionCount,
        onDifficultyChanged: (b) => setState(() => _difficultyBias = b),
        onQuestionCountChanged: (c) => setState(() => _questionCount = c),
        onChooseTopics: () {
          Navigator.of(sheetCtx).pop();
          _openTopics(mode);
        },
      ),
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
                      loading: _starting,
                      onPlay: () => _startGame(GameMode.standard),
                      onSettings: () => _openSettings(GameMode.standard),
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
                      loading: _starting,
                      onPlay: () => _startGame(GameMode.endless),
                      onSettings: () => _openSettings(GameMode.endless),
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
  final bool loading;
  final VoidCallback onPlay;
  final VoidCallback onSettings;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.painter,
    required this.highlightColor,
    required this.extraBadge,
    required this.loading,
    required this.onPlay,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: painter)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Illustration area
              Expanded(
                flex: 3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Settings gear (top-right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: onSettings,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.stoneDark.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings_outlined,
                              size: 20,
                              color: AppColors.textLight.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom info + play button
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
                              color: AppColors.torchGold.withValues(alpha: 0.15),
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
                        onPressed: loading ? null : onPlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: highlightColor,
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.textDark,
                                ),
                              )
                            : Text(
                                'Play',
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
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings bottom sheet
// ---------------------------------------------------------------------------

class _ModeSettingsSheet extends StatefulWidget {
  final GameMode mode;
  final int initialDifficultyBias;
  final int initialQuestionCount;
  final void Function(int) onDifficultyChanged;
  final void Function(int) onQuestionCountChanged;
  final VoidCallback onChooseTopics;

  const _ModeSettingsSheet({
    required this.mode,
    required this.initialDifficultyBias,
    required this.initialQuestionCount,
    required this.onDifficultyChanged,
    required this.onQuestionCountChanged,
    required this.onChooseTopics,
  });

  @override
  State<_ModeSettingsSheet> createState() => _ModeSettingsSheetState();
}

class _ModeSettingsSheetState extends State<_ModeSettingsSheet> {
  late int _difficultyBias;
  late int _questionCount;

  @override
  void initState() {
    super.initState();
    _difficultyBias = widget.initialDifficultyBias;
    _questionCount = widget.initialQuestionCount;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isStandard = widget.mode == GameMode.standard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isStandard ? "Standard" : "Endless"} Settings',
            style: tt.titleMedium?.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 20),

          // Difficulty
          Text('Difficulty',
              style: tt.labelMedium?.copyWith(color: AppColors.parchment)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('🕯️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              ...List.generate(5, (i) {
                final value = i + 1;
                final active = value == _difficultyBias;
                final color = _biasColor(value);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _difficultyBias = value);
                      widget.onDifficultyChanged(value);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? color : AppColors.stone,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: active ? color : AppColors.stoneMid),
                      ),
                      child: Text(
                        '$value',
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.textLight,
                          fontWeight:
                              active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 4),
              const Text('⚔️', style: TextStyle(fontSize: 14)),
            ],
          ),

          // Question count (Standard only)
          if (isStandard) ...[
            const SizedBox(height: 20),
            Text('Questions',
                style: tt.labelMedium?.copyWith(color: AppColors.parchment)),
            const SizedBox(height: 8),
            Row(
              children: [5, 10, 20].map((n) {
                final active = n == _questionCount;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _questionCount = n);
                      widget.onQuestionCountChanged(n);
                    },
                    child: Container(
                      width: 52,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppColors.torchAmber : AppColors.stone,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: active
                              ? AppColors.torchAmber
                              : AppColors.stoneMid,
                        ),
                      ),
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color: active
                              ? AppColors.textDark
                              : AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // Choose Topics
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune, color: AppColors.torchAmber),
            title: const Text('Choose Topics',
                style: TextStyle(color: AppColors.textLight)),
            subtitle: Text(
              'Select which topics to include',
              style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.5)),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.stoneMid),
            onTap: widget.onChooseTopics,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

Color _biasColor(int bias) => switch (bias) {
      1 || 2 => AppColors.torchGold,
      4 || 5 => AppColors.dangerRed,
      _ => AppColors.torchAmber,
    };

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

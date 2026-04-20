import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/data/topic_registry.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import '../../../gameplay/presentation/providers/game_state_provider.dart';
import '../../../gameplay/presentation/providers/quiz_config_provider.dart';

const _kDifficultyLabels = [
  'Very Easy',
  'Easy',
  'Medium',
  'Hard',
  'Very Hard',
];

String _difficultyDescription(int bias, GameMode mode) {
  final base = switch (bias) {
    1 => 'Only the easiest questions — perfect for newcomers.',
    2 => 'Mostly easy questions with a few harder ones.',
    4 => 'Mostly challenging questions with fewer easy ones.',
    5 => 'Only the toughest questions — for true masters.',
    _ => 'A balanced mix across all difficulty levels.',
  };
  if (mode == GameMode.endless) {
    final streakLimit = QuizConfig(
      selectedTopicIds: const {},
      questionCount: 10,
      gameMode: GameMode.endless,
      difficultyBias: bias,
    ).streakLimit;
    return '$base Get $streakLimit right in a row to earn hearts or bonus points.';
  }
  return base;
}

Color _biasColor(int bias) => switch (bias) {
      1 || 2 => AppColors.torchGold,
      4 || 5 => AppColors.dangerRed,
      _ => AppColors.torchAmber,
    };

class GameSettingsScreen extends ConsumerStatefulWidget {
  final GameMode mode;

  const GameSettingsScreen({super.key, required this.mode});

  @override
  ConsumerState<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends ConsumerState<GameSettingsScreen> {
  late int _difficultyBias;
  late int _questionCount;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(quizConfigProvider);
    _difficultyBias = config.difficultyBias;
    _questionCount = config.questionCount;
  }

  bool get _isStandard => widget.mode == GameMode.standard;

  int get _topicCount =>
      ref.watch(quizConfigProvider).selectedTopicIds.length;

  bool get _allTopicsSelected => _topicCount == allTopicIds.length;

  Future<void> _startGame() async {
    if (_starting) return;
    setState(() => _starting = true);
    final currentTopics = ref.read(quizConfigProvider).selectedTopicIds;
    final topicIds =
        currentTopics.isEmpty ? Set<String>.from(allTopicIds) : currentTopics;
    final config = QuizConfig(
      selectedTopicIds: topicIds,
      questionCount: _questionCount,
      gameMode: widget.mode,
      difficultyBias: _difficultyBias,
    );
    ref.read(quizConfigProvider.notifier).setConfig(config);
    await ref.read(gameStateProvider.notifier).startGame(config);
    if (mounted) context.go('/game');
  }

  void _openTopics() {
    final currentConfig = ref.read(quizConfigProvider);
    ref.read(quizConfigProvider.notifier).setConfig(
      currentConfig.copyWith(
        gameMode: widget.mode,
        difficultyBias: _difficultyBias,
        questionCount: _questionCount,
      ),
    );
    context.push('/topics', extra: {'fromSettings': true});
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final difficultyLabel = _kDifficultyLabels[_difficultyBias - 1];
    final difficultyColor = _biasColor(_difficultyBias);
    final description = _difficultyDescription(_difficultyBias, widget.mode);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.stoneDark,
        title: Text(_isStandard ? 'Standard' : 'Endless'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mode description banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.stone.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.stoneMid),
                          ),
                          child: Text(
                            _isStandard
                                ? '3 lives · fixed question count · earn stars'
                                : 'No finish line · streak rewards · life recovery',
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.textLight.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Difficulty ──────────────────────────────────────
                        Text('Difficulty',
                            style: tt.labelLarge
                                ?.copyWith(color: AppColors.parchment)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('🕯️',
                                style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Slider(
                                value: _difficultyBias.toDouble(),
                                min: 1,
                                max: 5,
                                divisions: 4,
                                activeColor: difficultyColor,
                                inactiveColor:
                                    AppColors.stoneMid.withValues(alpha: 0.5),
                                onChanged: (v) => setState(
                                    () => _difficultyBias = v.round()),
                              ),
                            ),
                            const Text('⚔️',
                                style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: difficultyColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: difficultyColor),
                            ),
                            child: Text(
                              difficultyLabel,
                              style: tt.labelMedium?.copyWith(
                                  color: difficultyColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: tt.bodySmall?.copyWith(
                              color:
                                  AppColors.textLight.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center,
                        ),

                        // ── Question count (Standard only) ──────────────────
                        if (_isStandard) ...[
                          const SizedBox(height: 28),
                          Text('Questions',
                              style: tt.labelLarge
                                  ?.copyWith(color: AppColors.parchment)),
                          const SizedBox(height: 10),
                          Row(
                            children: QuizConfig.validCounts.map((n) {
                              final active = n == _questionCount;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _questionCount = n),
                                  child: Container(
                                    width: 64,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.torchAmber
                                          : AppColors.stone,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: active
                                              ? AppColors.torchAmber
                                              : AppColors.stoneMid),
                                    ),
                                    child: Text(
                                      '$n',
                                      style: TextStyle(
                                        color: active
                                            ? AppColors.textDark
                                            : AppColors.textLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Topics ──────────────────────────────────────────
                        Text('Topics',
                            style: tt.labelLarge
                                ?.copyWith(color: AppColors.parchment)),
                        const SizedBox(height: 8),
                        Material(
                          color: AppColors.stone,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _openTopics,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  const Icon(Icons.tune,
                                      color: AppColors.torchAmber, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _allTopicsSelected
                                              ? 'All topics'
                                              : '$_topicCount of ${allTopicIds.length} topics',
                                          style: const TextStyle(
                                              color: AppColors.textLight),
                                        ),
                                        Text(
                                          'Tap to customise',
                                          style: tt.bodySmall?.copyWith(
                                              color: AppColors.textLight
                                                  .withValues(alpha: 0.5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.stoneMid),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Bottom action bar ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.stoneDark,
                    border:
                        Border(top: BorderSide(color: AppColors.stoneMid)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textLight,
                            side: const BorderSide(color: AppColors.stoneMid),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _starting ? null : _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isStandard
                                ? AppColors.torchAmber
                                : AppColors.torchGold,
                            foregroundColor: AppColors.textDark,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _starting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textDark))
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            _starting ? 'Loading…' : 'Play',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

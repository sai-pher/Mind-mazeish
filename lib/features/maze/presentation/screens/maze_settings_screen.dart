import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/data/topic_registry.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import '../../../gameplay/presentation/providers/quiz_config_provider.dart';
import '../providers/maze_state_provider.dart';

const _kDifficultyLabels = [
  'Very Easy',
  'Easy',
  'Medium',
  'Hard',
  'Very Hard',
];

Color _biasColor(int bias) => switch (bias) {
      1 || 2 => AppColors.torchGold,
      4 || 5 => AppColors.dangerRed,
      _ => AppColors.torchAmber,
    };

class MazeSettingsScreen extends ConsumerStatefulWidget {
  const MazeSettingsScreen({super.key});

  @override
  ConsumerState<MazeSettingsScreen> createState() => _MazeSettingsScreenState();
}

class _MazeSettingsScreenState extends ConsumerState<MazeSettingsScreen> {
  late int _difficultyBias;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _difficultyBias = ref.read(quizConfigProvider).difficultyBias;
  }

  int get _topicCount =>
      ref.watch(quizConfigProvider).selectedTopicIds.length;

  bool get _allTopicsSelected => _topicCount == allTopicIds.length;

  Future<void> _enterMaze() async {
    if (_starting) return;
    setState(() => _starting = true);

    final currentTopics = ref.read(quizConfigProvider).selectedTopicIds;
    final topicIds =
        currentTopics.isEmpty ? Set<String>.from(allTopicIds) : currentTopics;

    final config = QuizConfig(
      selectedTopicIds: topicIds,
      questionCount: 10,
      difficultyBias: _difficultyBias,
    );
    ref.read(quizConfigProvider.notifier).setConfig(config);
    await ref.read(mazeStateProvider.notifier).startMaze(config);
    if (mounted) context.go('/maze');
  }

  void _openTopics() {
    final currentConfig = ref.read(quizConfigProvider);
    ref.read(quizConfigProvider.notifier).setConfig(
          currentConfig.copyWith(difficultyBias: _difficultyBias),
        );
    context.push('/topics', extra: {'fromSettings': true});
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final difficultyLabel = _kDifficultyLabels[_difficultyBias - 1];
    final difficultyColor = _biasColor(_difficultyBias);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.stoneDark,
        title: const Text('Maze Mode'),
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
                            '10×10 maze · fog of war · answer to unlock doors · find the Throne Room',
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.textLight.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Difficulty
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
                                onChanged: (v) =>
                                    setState(() => _difficultyBias = v.round()),
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
                        const SizedBox(height: 28),

                        // Topics
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

                // Bottom action bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.stoneDark,
                    border: Border(top: BorderSide(color: AppColors.stoneMid)),
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
                          onPressed: _starting ? null : _enterMaze,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.torchAmber,
                            foregroundColor: AppColors.textDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _starting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textDark))
                              : const Icon(Icons.explore),
                          label: Text(
                            _starting ? 'Generating…' : 'Enter the Maze',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

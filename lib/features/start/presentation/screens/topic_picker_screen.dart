import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/data/question_bank.dart';
import '../../../gameplay/data/topic_registry.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import '../../../gameplay/domain/models/topic.dart';
import '../../../gameplay/presentation/providers/game_state_provider.dart';
import '../../../gameplay/presentation/providers/quiz_config_provider.dart';

class TopicPickerScreen extends ConsumerStatefulWidget {
  const TopicPickerScreen({super.key});

  @override
  ConsumerState<TopicPickerScreen> createState() => _TopicPickerScreenState();
}

class _TopicPickerScreenState extends ConsumerState<TopicPickerScreen> {
  late Set<String> _selected;
  int _questionCount = 10;

  @override
  void initState() {
    super.initState();
    final config = ref.read(quizConfigProvider);
    _selected = Set.from(config.selectedTopicIds);
    _questionCount = config.questionCount;
  }

  bool get _canStart => _selected.isNotEmpty;

  int get _availableQuestions =>
      allQuestions.where((q) => _selected.contains(q.topicId)).length;

  void _toggleTopic(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleSuper(SuperCategory sc) {
    final ids = sc.allTopicIds;
    final allSelected = ids.every(_selected.contains);
    setState(() {
      if (allSelected) {
        _selected.removeAll(ids);
      } else {
        _selected.addAll(ids);
      }
    });
  }

  void _toggleCategory(TopicCategory cat) {
    final ids = cat.topicIds;
    final allSelected = ids.every(_selected.contains);
    setState(() {
      if (allSelected) {
        _selected.removeAll(ids);
      } else {
        _selected.addAll(ids);
      }
    });
  }

  void _selectAll() => setState(() => _selected = Set.from(allTopicIds));
  void _clearAll() => setState(() => _selected.clear());

  void _startGame() {
    final config = QuizConfig(
      selectedTopicIds: Set.from(_selected),
      questionCount: _questionCount,
    );
    ref.read(quizConfigProvider.notifier).state = config;
    ref.read(gameStateProvider.notifier).startGame(config);
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Topics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: const Text('All',
                style: TextStyle(color: AppColors.torchAmber)),
          ),
          TextButton(
            onPressed: _clearAll,
            child: const Text('None',
                style: TextStyle(color: AppColors.stoneMid)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: superCategories.map((sc) {
                return _SuperCategoryTile(
                  sc: sc,
                  selected: _selected,
                  onToggleSuper: () => _toggleSuper(sc),
                  onToggleCategory: _toggleCategory,
                  onToggleTopic: _toggleTopic,
                ).animate().fadeIn(duration: 300.ms);
              }).toList(),
            ),
          ),

          // Bottom bar
          _BottomBar(
            questionCount: _questionCount,
            availableQuestions: _availableQuestions,
            canStart: _canStart,
            onCountChanged: (c) => setState(() => _questionCount = c),
            onStart: _startGame,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _SuperCategoryTile extends StatefulWidget {
  final SuperCategory sc;
  final Set<String> selected;
  final VoidCallback onToggleSuper;
  final void Function(TopicCategory) onToggleCategory;
  final void Function(String) onToggleTopic;

  const _SuperCategoryTile({
    required this.sc,
    required this.selected,
    required this.onToggleSuper,
    required this.onToggleCategory,
    required this.onToggleTopic,
  });

  @override
  State<_SuperCategoryTile> createState() => _SuperCategoryTileState();
}

class _SuperCategoryTileState extends State<_SuperCategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allIds = widget.sc.allTopicIds;
    final allSelected = allIds.every(widget.selected.contains);
    final someSelected = allIds.any(widget.selected.contains);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.stone.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stoneMid),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onToggleSuper,
                    child: Icon(
                      allSelected
                          ? Icons.check_box
                          : someSelected
                              ? Icons.indeterminate_check_box
                              : Icons.check_box_outline_blank,
                      color: allSelected || someSelected
                          ? AppColors.torchAmber
                          : AppColors.stoneMid,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(widget.sc.emoji,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.sc.name,
                      style: textTheme.titleLarge
                          ?.copyWith(color: AppColors.textLight),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.stoneMid,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                children: widget.sc.categories.map((cat) {
                  return _CategoryTile(
                    cat: cat,
                    selected: widget.selected,
                    onToggleCategory: () => widget.onToggleCategory(cat),
                    onToggleTopic: widget.onToggleTopic,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final TopicCategory cat;
  final Set<String> selected;
  final VoidCallback onToggleCategory;
  final void Function(String) onToggleTopic;

  const _CategoryTile({
    required this.cat,
    required this.selected,
    required this.onToggleCategory,
    required this.onToggleTopic,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allSelected = cat.topicIds.every(selected.contains);
    final someSelected = cat.topicIds.any(selected.contains);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        InkWell(
          onTap: onToggleCategory,
          child: Row(
            children: [
              Icon(
                allSelected
                    ? Icons.check_box
                    : someSelected
                        ? Icons.indeterminate_check_box
                        : Icons.check_box_outline_blank,
                color: allSelected || someSelected
                    ? AppColors.torchAmber
                    : AppColors.stoneMid,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                cat.name,
                style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textLight.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: cat.topics.map((topic) {
            final isSelected = selected.contains(topic.id);
            return GestureDetector(
              onTap: () => onToggleTopic(topic.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.torchAmber.withValues(alpha: 0.2)
                      : AppColors.stoneDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.torchAmber
                        : AppColors.stoneMid,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(topic.emoji,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      topic.name,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.torchAmber
                            : AppColors.textLight,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int questionCount;
  final int availableQuestions;
  final bool canStart;
  final void Function(int) onCountChanged;
  final VoidCallback onStart;

  const _BottomBar({
    required this.questionCount,
    required this.availableQuestions,
    required this.canStart,
    required this.onCountChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tooFew = availableQuestions < questionCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.stoneDark,
        border: Border(top: BorderSide(color: AppColors.stoneMid)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Questions: ',
                  style: textTheme.labelMedium
                      ?.copyWith(color: AppColors.textLight)),
              const SizedBox(width: 8),
              ...[5, 10, 20].map((n) {
                final active = n == questionCount;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onCountChanged(n),
                    child: Container(
                      width: 44,
                      height: 36,
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
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          if (tooFew && canStart)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Only $availableQuestions questions in selected topics.',
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.dangerRed),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  canStart && !tooFew ? onStart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.torchAmber,
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                canStart
                    ? 'Start — $questionCount questions'
                    : 'Select at least one topic',
                style: textTheme.labelLarge
                    ?.copyWith(color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

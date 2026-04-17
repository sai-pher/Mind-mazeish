import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../feedback/data/github_issue_service.dart';
import '../../../gameplay/data/topic_registry.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _TopicStats {
  final String topicId;
  final String topicName;
  final String topicEmoji;
  final int questionCount;
  final int sourceCount;
  final int questionsWithUrl;

  const _TopicStats({
    required this.topicId,
    required this.topicName,
    required this.topicEmoji,
    required this.questionCount,
    required this.sourceCount,
    required this.questionsWithUrl,
  });

  int get questionsWithoutUrl => questionCount - questionsWithUrl;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _statsProvider = FutureProvider<List<_TopicStats>>((ref) async {
  final stats = <_TopicStats>[];

  for (final topicId in allTopicIds) {
    // --- questions ---
    int questionCount = 0;
    int questionsWithInlineUrl = 0;
    final questionSourceIdList = <String>[];

    try {
      final raw =
          await rootBundle.loadString('assets/questions/topics/$topicId.json');
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list.cast<Map<String, dynamic>>()) {
        questionCount++;
        final url = e['articleUrl'] as String? ?? '';
        if (url.isNotEmpty) questionsWithInlineUrl++;
        final sourceId = e['sourceId'] as String? ?? '';
        questionSourceIdList.add(sourceId);
      }
    } catch (_) {
      // No topic file yet — counts stay 0.
    }

    // --- sources ---
    int sourceCount = 0;
    final sourceUrlsBySourceId = <String, bool>{};

    try {
      final raw = await rootBundle
          .loadString('assets/questions/sources/$topicId.json');
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list.cast<Map<String, dynamic>>()) {
        final id = e['id'] as String? ?? '';
        final url = e['url'] as String? ?? '';
        if (id.isNotEmpty) {
          sourceCount++;
          sourceUrlsBySourceId[id] = url.isNotEmpty;
        }
      }
    } catch (_) {
      // No sources file — count stays 0.
    }

    // Questions with URL = inline URL OR sourceId pointing to a source with URL.
    // Count per-question (not per unique sourceId) to avoid undercounting when
    // multiple questions share the same sourceId.
    int questionsWithSourceUrl = 0;
    for (final sid in questionSourceIdList) {
      if (sid.isNotEmpty && sourceUrlsBySourceId[sid] == true) {
        questionsWithSourceUrl++;
      }
    }
    final questionsWithUrl = questionsWithInlineUrl + questionsWithSourceUrl;

    stats.add(_TopicStats(
      topicId: topicId,
      topicName: topicName(topicId),
      topicEmoji: topicEmoji(topicId),
      questionCount: questionCount,
      sourceCount: sourceCount,
      questionsWithUrl: questionsWithUrl.clamp(0, questionCount),
    ));
  }

  stats.sort((a, b) => a.topicName.compareTo(b.topicName));
  return stats;
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class QuestionStatsScreen extends ConsumerWidget {
  const QuestionStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Bank Stats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.torchAmber),
        ),
        error: (e, _) => Center(
          child: Text('Error loading stats: $e',
              style: const TextStyle(color: AppColors.dangerRed)),
        ),
        data: (stats) => _StatsBody(stats: stats),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _StatsBody extends StatelessWidget {
  final List<_TopicStats> stats;

  const _StatsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalQuestions = stats.fold(0, (s, t) => s + t.questionCount);
    final totalSources = stats.fold(0, (s, t) => s + t.sourceCount);
    final totalWithUrl = stats.fold(0, (s, t) => s + t.questionsWithUrl);
    final totalMissing = totalQuestions - totalWithUrl;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SummaryCard(
          topicCount: stats.length,
          totalQuestions: totalQuestions,
          totalSources: totalSources,
          totalMissing: totalMissing,
        ),
        const SizedBox(height: 12),
        const _ColumnHeader(),
        const SizedBox(height: 4),
        ...stats.map((t) => _TopicRow(stats: t)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final int topicCount;
  final int totalQuestions;
  final int totalSources;
  final int totalMissing;

  const _SummaryCard({
    required this.topicCount,
    required this.totalQuestions,
    required this.totalSources,
    required this.totalMissing,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.stone.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stoneMid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Summary',
              style: textTheme.titleMedium
                  ?.copyWith(color: AppColors.torchAmber)),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(label: 'Topics', value: '$topicCount'),
              const SizedBox(width: 8),
              _StatChip(label: 'Questions', value: '$totalQuestions'),
              const SizedBox(width: 8),
              _StatChip(label: 'Sources', value: '$totalSources'),
            ],
          ),
          if (totalMissing > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.dangerRed),
                const SizedBox(width: 4),
                Text(
                  '$totalMissing questions missing article URL',
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.dangerRed),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.stoneDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.stoneMid),
        ),
        child: Column(
          children: [
            Text(value,
                style: textTheme.titleLarge
                    ?.copyWith(color: AppColors.torchGold)),
            const SizedBox(height: 2),
            Text(label,
                style: textTheme.labelSmall
                    ?.copyWith(color: AppColors.textLight.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Column header
// ---------------------------------------------------------------------------

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textLight.withValues(alpha: 0.5),
        letterSpacing: 0.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          SizedBox(
              width: 52,
              child:
                  Text('Q', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 52,
              child:
                  Text('SRC', style: style, textAlign: TextAlign.center)),
          SizedBox(
              width: 52,
              child:
                  Text('URL', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-topic row
// ---------------------------------------------------------------------------

class _TopicRow extends StatelessWidget {
  final _TopicStats stats;

  const _TopicRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final qCount = stats.questionCount;
    final Color qColor;
    if (qCount == 0) {
      qColor = AppColors.dangerRed;
    } else if (qCount < 10) {
      qColor = AppColors.torchAmber;
    } else {
      qColor = AppColors.torchGold;
    }

    final withUrl = stats.questionsWithUrl;
    final urlLabel = withUrl == qCount ? '✓' : '$withUrl/$qCount';
    final urlColor = withUrl == qCount
        ? AppColors.torchGold
        : withUrl > 0
            ? AppColors.torchAmber
            : AppColors.dangerRed;

    return InkWell(
      onTap: () => _showContentRequestDialog(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.stone.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.stoneMid.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Text(stats.topicEmoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                stats.topicName,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textLight),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '$qCount',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                    color: qColor, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${stats.sourceCount}',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textLight.withValues(alpha: 0.7)),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                urlLabel,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: urlColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContentRequestDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ContentRequestDialog(stats: stats),
    );
  }
}

// ---------------------------------------------------------------------------
// Content request dialog
// ---------------------------------------------------------------------------

class _ContentRequestDialog extends StatefulWidget {
  final _TopicStats stats;

  const _ContentRequestDialog({required this.stats});

  @override
  State<_ContentRequestDialog> createState() => _ContentRequestDialogState();
}

class _ContentRequestDialogState extends State<_ContentRequestDialog> {
  int _sourcesRequested = 1;
  int _questionsRequested = 10;
  bool _submitting = false;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.stoneDark,
      title: Text(
        'Request Content',
        style: textTheme.displaySmall?.copyWith(
            color: AppColors.torchAmber, fontSize: 18),
      ),
      content: _submitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.torchGold, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Request submitted for ${widget.stats.topicName}!',
                  style: textTheme.labelMedium
                      ?.copyWith(color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.stats.topicEmoji} ${widget.stats.topicName}',
                  style: textTheme.labelLarge
                      ?.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                _CounterRow(
                  label: 'New sources',
                  value: _sourcesRequested,
                  min: 1,
                  max: 20,
                  onChanged: (v) => setState(() => _sourcesRequested = v),
                ),
                const SizedBox(height: 12),
                _CounterRow(
                  label: 'New questions',
                  value: _questionsRequested,
                  min: 5,
                  max: 100,
                  step: 5,
                  onChanged: (v) => setState(() => _questionsRequested = v),
                ),
              ],
            ),
      actions: _submitted
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close',
                    style: TextStyle(color: AppColors.torchAmber)),
              ),
            ]
          : [
              TextButton(
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.torchAmber)),
              ),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.torchAmber,
                  foregroundColor: AppColors.textDark,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textDark),
                      )
                    : const Text('Submit'),
              ),
            ],
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await GithubIssueService.submitContentRequest(
      type: ContentRequestType.moreQuestions,
      title: 'More content for ${widget.stats.topicName}',
      body: 'Please add more content for the **${widget.stats.topicName}** topic.\n\n'
          '- Requested new sources: **$_sourcesRequested**\n'
          '- Requested new questions: **$_questionsRequested**\n\n'
          'Current stats: ${widget.stats.questionCount} questions, '
          '${widget.stats.sourceCount} sources, '
          '${widget.stats.questionsWithUrl}/${widget.stats.questionCount} with article URLs.',
      topicId: widget.stats.topicId,
    );
    if (mounted) setState(() => _submitted = true);
  }
}

// ---------------------------------------------------------------------------
// Counter row widget
// ---------------------------------------------------------------------------

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: textTheme.labelMedium
                  ?.copyWith(color: AppColors.textLight)),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove_circle_outline,
              color: AppColors.torchAmber, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: textTheme.labelLarge?.copyWith(
                color: AppColors.torchGold, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_circle_outline,
              color: AppColors.torchAmber, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

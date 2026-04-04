import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../gameplay/data/topic_registry.dart';
import '../../domain/models/notebook_entry.dart';
import '../providers/notebook_provider.dart';

class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebookAsync = ref.watch(notebookProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notebook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: notebookAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.torchAmber)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book,
                      size: 64,
                      color: AppColors.torchAmber),
                  const SizedBox(height: 16),
                  Text(
                    'Your notebook is empty.',
                    style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open Wikipedia articles during a game\nto collect them here.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textLight.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            );
          }

          // Group by topicId
          final grouped = <String, List<NotebookEntry>>{};
          for (final e in entries) {
            grouped.putIfAbsent(e.topicId, () => []).add(e);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: grouped.entries.map((entry) {
              final tid = entry.key;
              final articles = entry.value;
              return _TopicSection(
                topicId: tid,
                articles: articles,
              ).animate().fadeIn(duration: 300.ms);
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TopicSection extends ConsumerWidget {
  final String topicId;
  final List<NotebookEntry> articles;

  const _TopicSection({required this.topicId, required this.articles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final emoji = topicEmoji(topicId);
    final name = topicName(topicId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              name,
              style: textTheme.titleLarge?.copyWith(color: AppColors.torchAmber),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...articles.map((a) => _ArticleCard(entry: a)),
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final NotebookEntry entry;

  const _ArticleCard({required this.entry});

  @override
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(
          '/article',
          extra: {'url': entry.articleUrl, 'title': entry.articleTitle},
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.menu_book, size: 18, color: AppColors.torchAmber),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.articleTitle,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(entry.visitedAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new,
                  size: 14, color: AppColors.torchAmber),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

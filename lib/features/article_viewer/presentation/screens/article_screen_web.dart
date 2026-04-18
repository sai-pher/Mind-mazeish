import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../notebook/domain/models/notebook_entry.dart';
import '../../../notebook/presentation/providers/notebook_provider.dart';
import '../../../gameplay/presentation/providers/game_state_provider.dart';

class ArticleScreen extends ConsumerStatefulWidget {
  final String url;
  final String title;
  final String? topicId;

  const ArticleScreen({
    super.key,
    required this.url,
    required this.title,
    this.topicId,
  });

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  bool _notebookSaved = false;

  @override
  void initState() {
    super.initState();
    _tryOpen();
  }

  Future<void> _tryOpen() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    await _saveToNotebook();
  }

  Future<void> _manualOpen() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    await _saveToNotebook();
  }

  Future<void> _saveToNotebook() async {
    if (_notebookSaved) return;
    final topicId = widget.topicId ??
        ref.read(gameStateProvider)?.currentQuestion.topicId ??
        'unknown';
    final isNew = await ref.read(notebookProvider.notifier).addEntry(
          NotebookEntry(
            articleTitle: widget.title,
            articleUrl: widget.url,
            topicId: topicId,
            visitedAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    ref.read(gameStateProvider.notifier).recordArticleVisit(
          widget.url,
          isNew: isNew,
        );
    setState(() => _notebookSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                color: AppColors.torchAmber,
                size: 52,
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                style: tt.titleMedium?.copyWith(color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open Wikipedia article'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.torchAmber,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _manualOpen,
              ),
              const SizedBox(height: 16),
              Text(
                'Opens in a new tab.\nIf nothing opens, allow pop-ups for this site in your browser settings.',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Go back to game',
                  style: TextStyle(color: AppColors.stoneMid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

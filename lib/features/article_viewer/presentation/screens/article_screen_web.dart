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
  @override
  void initState() {
    super.initState();
    _openAndRecord();
  }

  Future<void> _openAndRecord() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening article in browser…')),
      );
      await _saveToNotebook();
      if (mounted) context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Pop-ups are blocked — allow pop-ups for this site in your browser settings.'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _openAndRecord,
          ),
        ),
      );
    }
  }

  Future<void> _saveToNotebook() async {
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

    ref.read(gameStateProvider.notifier).recordArticleVisit(
          widget.url,
          isNew: isNew,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.torchAmber),
            SizedBox(height: 16),
            Text(
              'Opening article in browser…',
              style: TextStyle(color: AppColors.textLight, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? _controller;
  bool _isLoading = true;
  bool _saved = false;

  static bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
  }

  @override
  void initState() {
    super.initState();
    if (!_isValidUrl(widget.url)) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _maybeSaveToNotebook();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _maybeSaveToNotebook() async {
    if (_saved) return;
    _saved = true;

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

    // Record the visit in the current game session if active.
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
      body: _controller == null
          ? const _NoArticlePlaceholder()
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.torchAmber),
                  ),
              ],
            ),
    );
  }
}

class _NoArticlePlaceholder extends StatelessWidget {
  const _NoArticlePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 48, color: AppColors.torchAmber),
          SizedBox(height: 16),
          Text(
            'No article available',
            style: TextStyle(color: AppColors.textLight, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'This question has no linked Wikipedia article yet.',
            style: TextStyle(color: AppColors.textLight, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

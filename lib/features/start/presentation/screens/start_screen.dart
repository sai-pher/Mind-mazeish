import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../services/update_service.dart';
import '../../../gameplay/domain/models/quiz_config.dart';
import '../../../gameplay/presentation/providers/game_state_provider.dart';
import '../../../gameplay/presentation/providers/quiz_config_provider.dart';
import '../../../gameplay/data/topic_registry.dart';

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StartBackgroundPainter())),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department,
                            size: 72, color: AppColors.torchAmber)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .custom(
                          duration: 1800.ms,
                          builder: (_, v, child) =>
                              Opacity(opacity: 0.7 + v * 0.3, child: child),
                        ),
                    const SizedBox(height: 24),
                    Text('MIND',
                            style: textTheme.displayLarge?.copyWith(fontSize: 52),
                            textAlign: TextAlign.center)
                        .animate()
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: -0.2, end: 0, duration: 700.ms),
                    Text('MAZEISH',
                            style: textTheme.displayLarge?.copyWith(
                                fontSize: 42,
                                color: AppColors.torchGold,
                                letterSpacing: 6),
                            textAlign: TextAlign.center)
                        .animate()
                        .fadeIn(duration: 700.ms, delay: 150.ms)
                        .slideY(begin: 0.2, end: 0, duration: 700.ms),
                    const SizedBox(height: 12),
                    Container(
                            height: 1.5,
                            width: size.width * 0.5,
                            color: AppColors.torchAmber.withValues(alpha: 0.4))
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 400.ms),
                    const SizedBox(height: 36),

                    // Quick Play button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startQuickPlay(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.torchAmber,
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.bolt, size: 20),
                        label: Text('Quick Play',
                            style: textTheme.displaySmall?.copyWith(
                                color: AppColors.textDark, fontSize: 18)),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 600.ms),

                    const SizedBox(height: 12),

                    // Choose Topics button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/topics'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.torchAmber,
                          side: const BorderSide(
                              color: AppColors.torchAmber, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text('Choose Topics',
                            style: textTheme.labelLarge?.copyWith(
                                color: AppColors.torchAmber, fontSize: 16)),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 700.ms),

                    const SizedBox(height: 24),

                    // Notebook button
                    TextButton.icon(
                      onPressed: () => context.push('/notebook'),
                      icon: const Icon(Icons.menu_book,
                          size: 18, color: AppColors.torchAmber),
                      label: Text('Notebook',
                          style: textTheme.labelMedium?.copyWith(
                              color: AppColors.torchAmber)),
                    ).animate().fadeIn(duration: 400.ms, delay: 800.ms),

                    const SizedBox(height: 4),

                    // Settings button (feedback + issues accessible from there)
                    TextButton.icon(
                      onPressed: () => context.push('/settings'),
                      icon: Icon(Icons.settings_outlined,
                          size: 18,
                          color: AppColors.textLight.withValues(alpha: 0.55)),
                      label: Text('Settings',
                          style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textLight
                                  .withValues(alpha: 0.55))),
                    ).animate().fadeIn(duration: 400.ms, delay: 900.ms),

                    const SizedBox(height: 8),
                    _VersionBadge()
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 1000.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuickPlay(BuildContext context, WidgetRef ref) async {
    final config = QuizConfig(
      selectedTopicIds: Set.from(allTopicIds),
      questionCount: 10,
    );
    ref.read(quizConfigProvider.notifier).setConfig(config);
    await ref.read(gameStateProvider.notifier).startGame(config);
    if (context.mounted) context.go('/game');
  }
}

// ---------------------------------------------------------------------------
// Version badge with update check
// ---------------------------------------------------------------------------

class _VersionBadge extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VersionBadge> createState() => _VersionBadgeState();
}

class _VersionBadgeState extends ConsumerState<_VersionBadge> {
  String _version = '';
  int _buildNumber = 0;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = int.tryParse(info.buildNumber) ?? 0;
    });
    _autoCheckUpdate();
  }

  /// Silently checks for updates on app open — shows dialog only if available.
  Future<void> _autoCheckUpdate() async {
    final info = await UpdateService.check(_buildNumber);
    if (!mounted || info == null || !info.updateAvailable) return;
    _showUpdateDialog(info);
  }

  /// Manual tap path — also shows snackbar when up to date or on error.
  Future<void> _checkUpdates() async {
    final info = await UpdateService.check(_buildNumber);
    if (!mounted) return;
    if (info == null) {
      _showSnack('Could not check for updates. Check your connection.');
      return;
    }
    if (!info.updateAvailable) {
      _showSnack('You\'re on the latest version ($_version).');
      return;
    }
    _showUpdateDialog(info);
  }

  void _showUpdateDialog(UpdateInfo info) {
    final textTheme = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.stoneDark,
        title: Text(
          'Update Available — ${info.latestVersion}',
          style: textTheme.displaySmall?.copyWith(color: AppColors.torchGold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: MarkdownBody(
              data: info.releaseNotes.isNotEmpty
                  ? info.releaseNotes
                  : 'A new version is available.',
              styleSheet: MarkdownStyleSheet(
                p: textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                h2: textTheme.labelLarge
                    ?.copyWith(color: AppColors.torchGold, fontSize: 14),
                h3: textTheme.labelMedium
                    ?.copyWith(color: AppColors.torchAmber),
                listBullet:
                    textTheme.bodySmall?.copyWith(color: AppColors.textLight),
                code: const TextStyle(
                  color: AppColors.torchAmber,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
                blockquote:
                    textTheme.bodySmall?.copyWith(color: AppColors.textLight),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later',
                style: TextStyle(color: AppColors.torchAmber)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (UpdateService.isDirectApkUrl(info.downloadUrl)) {
                _downloadAndInstall(info);
              } else {
                launchUrl(Uri.parse(info.downloadUrl),
                    mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.torchGold,
              foregroundColor: AppColors.textDark,
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(UpdateInfo info) async {
    if (!mounted) return;

    final progressNotifier = ValueNotifier<double?>(null);
    var cancelled = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppColors.stoneDark,
          title: const Text('Downloading update…',
              style: TextStyle(color: AppColors.textLight)),
          content: ValueListenableBuilder<double?>(
            valueListenable: progressNotifier,
            builder: (_, v, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: v,
                  backgroundColor: AppColors.stone,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.torchGold),
                ),
                if (v != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${(v * 100).round()}%',
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.torchAmber)),
            ),
          ],
        ),
      ),
    ).whenComplete(progressNotifier.dispose);

    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/mind_mazeish_update.apk';

      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(info.downloadUrl));
        final response = await client.send(request);
        final total = response.contentLength ?? 0;
        var received = 0;

        final file = File(savePath);
        final sink = file.openWrite();
        await for (final chunk in response.stream) {
          if (cancelled) {
            await sink.close();
            return;
          }
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) progressNotifier.value = received / total;
        }
        await sink.flush();
        await sink.close();
      } finally {
        client.close();
      }

      if (cancelled || !mounted) return;
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();

      await OpenFilex.open(savePath);
    } catch (_) {
      if (mounted) {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
        _showSnack('Download failed. Please try again.');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_version.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _checkUpdates,
      child: Text(
        'v$_version  •  tap to check for updates',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textLight.withValues(alpha: 0.35), fontSize: 11),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background painter (unchanged)
// ---------------------------------------------------------------------------

class _StartBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.background);
    final stonePaint = Paint()
      ..color = AppColors.stone.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final archW = size.width * 0.8;
    final path = Path();
    path.addRect(Rect.fromLTWH(cx - archW / 2, 0, archW * 0.12, size.height));
    path.addRect(Rect.fromLTWH(
        cx + archW / 2 - archW * 0.12, 0, archW * 0.12, size.height));
    path.addArc(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.18),
          width: archW,
          height: archW * 0.55),
      3.14159, 3.14159,
    );
    canvas.drawPath(path, stonePaint);
    final glowPaint = Paint()
      ..color = AppColors.torchAmber.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(0, size.height), 120, glowPaint);
    canvas.drawCircle(Offset(size.width, size.height), 120, glowPaint);
  }

  @override
  bool shouldRepaint(_StartBackgroundPainter old) => false;
}

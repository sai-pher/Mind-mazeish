import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

                    // Feedback button
                    TextButton.icon(
                      onPressed: () => context.push('/feedback'),
                      icon: Icon(Icons.feedback_outlined,
                          size: 18,
                          color: AppColors.textLight.withValues(alpha: 0.55)),
                      label: Text('Feedback',
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
    ref.read(quizConfigProvider.notifier).state = config;
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
  }

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
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.stoneDark,
        title: Text('Update Available',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: AppColors.torchGold)),
        content: Text(
          'Version ${info.latestVersion} is available.\n\n${info.releaseNotes}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textLight),
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
              // URL opened via update service — requires url_launcher on device
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

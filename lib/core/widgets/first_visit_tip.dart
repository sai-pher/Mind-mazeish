import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/settings/presentation/providers/app_preferences_provider.dart';

/// Shows a dismissable tip card anchored to the bottom of its parent on the
/// first time a user visits the screen identified by [screenId], provided that
/// the global "tips" preference is enabled.
///
/// Wrap the screen's [Scaffold] body (or use it as an overlay sibling) and
/// supply a unique [screenId], an icon, a short [title], and a [message].
class FirstVisitTip extends ConsumerStatefulWidget {
  final String screenId;
  final IconData icon;
  final String title;
  final String message;

  const FirstVisitTip({
    super.key,
    required this.screenId,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  ConsumerState<FirstVisitTip> createState() => _FirstVisitTipState();
}

class _FirstVisitTipState extends ConsumerState<FirstVisitTip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    // Delay slightly so the screen renders first.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    if (mounted) setState(() => _dismissed = true);
    await ref.read(appPreferencesProvider.notifier).markScreenSeen(widget.screenId);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final prefsAsync = ref.watch(appPreferencesProvider);
    return prefsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (prefs) {
        if (!prefs.tipsEnabled || prefs.hasSeenScreen(widget.screenId)) {
          return const SizedBox.shrink();
        }
        final tt = Theme.of(context).textTheme;
        return SlideTransition(
          position: _slide,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.stone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.torchAmber.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: AppColors.torchAmber, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.title,
                              style: tt.labelLarge?.copyWith(
                                  color: AppColors.torchAmber,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.message,
                              style: tt.labelMedium?.copyWith(
                                  color: AppColors.textLight.withValues(alpha: 0.85),
                                  height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.torchAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.torchAmber.withValues(alpha: 0.4)),
                        ),
                        child: Text('Got it',
                            style: tt.labelSmall?.copyWith(
                                color: AppColors.torchAmber,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/user_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userId;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      UserProfileService.getUserId(),
      PackageInfo.fromPlatform().then((i) => '${i.version}+${i.buildNumber}'),
    ]);
    if (!mounted) return;
    setState(() {
      _userId     = results[0];
      _appVersion = results[1];
    });
  }

  void _copyUserId() {
    if (_userId == null) return;
    Clipboard.setData(ClipboardData(text: _userId!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User ID copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.stoneDark,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Profile ──────────────────────────────────────────────────────
          const _SectionHeader('Profile'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              color: AppColors.stone,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anonymous tester ID',
                      style: tt.labelMedium?.copyWith(color: AppColors.parchment),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _userId ?? '…',
                            style: tt.bodyMedium?.copyWith(
                              color: AppColors.torchAmber,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined,
                              size: 18, color: AppColors.torchAmber),
                          tooltip: 'Copy ID',
                          onPressed: _copyUserId,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This ID is stored only on your device and is attached '
                      'to all feedback you submit.',
                      style: tt.bodySmall?.copyWith(
                          color: AppColors.textLight.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Feedback ─────────────────────────────────────────────────────
          const _SectionHeader('Feedback'),
          ListTile(
            leading: const Icon(Icons.feedback_outlined,
                color: AppColors.torchAmber),
            title: const Text('Give Feedback',
                style: TextStyle(color: AppColors.textLight)),
            subtitle: Text(
              'Report a bug, request a feature, suggest content, or view open issues',
              style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.5)),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.stoneMid),
            onTap: () => context.push('/feedback'),
          ),

          // ── App ──────────────────────────────────────────────────────────
          const _SectionHeader('App'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.stoneMid),
            title: const Text('Version',
                style: TextStyle(color: AppColors.textLight)),
            trailing: Text(
              _appVersion ?? '…',
              style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.5)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.torchAmber.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

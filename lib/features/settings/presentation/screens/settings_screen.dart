import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/game_stats_repository.dart';
import '../../data/user_profile_service.dart';
import '../../domain/models/game_stats.dart';
import '../../domain/models/user_profile.dart';
import '../providers/app_preferences_provider.dart';

// Common emoji options for the avatar picker.
const _kEmojiOptions = [
  '🧙', '🧝', '🧛', '🧟', '🏰', '⚔️', '🛡️', '👑',
  '🐉', '🦁', '🦊', '🐺', '🦅', '🌙', '⭐', '🔮',
];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  UserProfile? _profile;
  GameStats? _stats;
  String? _appVersion;

  final _displayNameCtrl = TextEditingController();
  final _githubUrlCtrl   = TextEditingController();
  String _selectedEmoji  = '';
  bool _dirty            = false;
  bool _saving           = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _githubUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profileFuture = UserProfileService.getProfile();
    final statsFuture   = GameStatsRepository.load();
    final versionFuture = PackageInfo.fromPlatform();
    final profile  = await profileFuture;
    final stats    = await statsFuture;
    final pkgInfo  = await versionFuture;
    if (!mounted) return;
    setState(() {
      _profile    = profile;
      _stats      = stats;
      _appVersion = '${pkgInfo.version}+${pkgInfo.buildNumber}';
      _displayNameCtrl.text = profile.displayName;
      _githubUrlCtrl.text   = profile.githubUrl;
      _selectedEmoji        = profile.emoji;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    await UserProfileService.saveProfile(
      displayName: _displayNameCtrl.text,
      emoji: _selectedEmoji,
      githubUrl: _githubUrlCtrl.text,
    );
    if (!mounted) return;
    final updated = await UserProfileService.getProfile();
    setState(() {
      _profile = updated;
      _dirty   = false;
      _saving  = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  void _copyUserId() {
    if (_profile == null) return;
    Clipboard.setData(ClipboardData(text: _profile!.userId));
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
                    // Emoji avatar picker
                    Text(
                      'Avatar',
                      style: tt.labelMedium
                          ?.copyWith(color: AppColors.parchment),
                    ),
                    const SizedBox(height: 8),
                    _EmojiPicker(
                      selected: _selectedEmoji,
                      onSelected: (e) {
                        setState(() => _selectedEmoji = e);
                        _markDirty();
                      },
                    ),
                    const SizedBox(height: 16),

                    // Display name
                    Text(
                      'Display name',
                      style: tt.labelMedium
                          ?.copyWith(color: AppColors.parchment),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _displayNameCtrl,
                      maxLength: 40,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        hintText: 'How should we call you?',
                        hintStyle: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: AppColors.stoneDark,
                        counterStyle: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.4)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 12),

                    // GitHub URL
                    Text(
                      'GitHub profile (optional)',
                      style: tt.labelMedium
                          ?.copyWith(color: AppColors.parchment),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _githubUrlCtrl,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: AppColors.textLight),
                      decoration: InputDecoration(
                        hintText: 'https://github.com/username',
                        hintStyle: TextStyle(
                            color: AppColors.textLight.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: AppColors.stoneDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _dirty && !_saving ? _saveProfile : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.torchAmber,
                          foregroundColor: AppColors.textDark,
                          disabledBackgroundColor:
                              AppColors.stone.withValues(alpha: 0.5),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textDark),
                              )
                            : const Text('Save profile'),
                      ),
                    ),

                    const Divider(height: 24, color: AppColors.stoneDark),

                    // Anonymous tester ID (read-only)
                    Text(
                      'Anonymous tester ID',
                      style: tt.labelMedium
                          ?.copyWith(color: AppColors.parchment),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _profile?.userId ?? '…',
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

          // ── Game Stats ───────────────────────────────────────────────────
          const _SectionHeader('Game Stats'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              color: AppColors.stone,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _stats == null
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.torchAmber))
                    : _stats!.gamesPlayed == 0
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No games played yet',
                                style: tt.bodyMedium?.copyWith(
                                    color: AppColors.textLight
                                        .withValues(alpha: 0.5)),
                              ),
                            ),
                          )
                        : _StatsGrid(stats: _stats!),
              ),
            ),
          ),

          // ── Preferences ──────────────────────────────────────────────────
          const _SectionHeader('Preferences'),
          _TipsTile(ref: ref),

          // ── Learn ─────────────────────────────────────────────────────────
          const _SectionHeader('Learn'),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.torchAmber),
            title: const Text('How to Play',
                style: TextStyle(color: AppColors.textLight)),
            subtitle: Text(
              'Lives, scoring, streaks, modes, and more',
              style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.5)),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.stoneMid),
            onTap: () => context.push('/how-to-play'),
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
            trailing: const Icon(Icons.chevron_right, color: AppColors.stoneMid),
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
// Emoji avatar picker
// ---------------------------------------------------------------------------

class _EmojiPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _EmojiPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kEmojiOptions.map((e) {
        final isSelected = e == selected;
        return GestureDetector(
          onTap: () => onSelected(isSelected ? '' : e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.torchAmber.withValues(alpha: 0.25)
                  : AppColors.stoneDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.torchAmber : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(e, style: const TextStyle(fontSize: 20)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Game stats grid
// ---------------------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  final GameStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final accuracyPct = (stats.accuracy * 100).toStringAsFixed(0);
    final winPct      = (stats.winRate * 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          children: [
            _StatCell(label: 'Games Played', value: '${stats.gamesPlayed}'),
            _StatCell(label: 'Best Score',   value: '${stats.bestScore}'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCell(label: 'Win Rate (Std)',  value: '$winPct%'),
            _StatCell(label: 'Accuracy',  value: '$accuracyPct%'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCell(label: 'Articles Found', value: '${stats.totalArticlesFound}'),
            _StatCell(label: 'Total Score',    value: '${stats.totalScore}'),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: tt.headlineSmall?.copyWith(color: AppColors.torchGold),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tips toggle tile
// ---------------------------------------------------------------------------

class _TipsTile extends StatelessWidget {
  final WidgetRef ref;
  const _TipsTile({required this.ref});

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(appPreferencesProvider);
    final enabled = prefsAsync.asData?.value.tipsEnabled ?? true;
    return SwitchListTile(
      secondary: const Icon(Icons.lightbulb_outline, color: AppColors.torchAmber),
      title: const Text('Show tips',
          style: TextStyle(color: AppColors.textLight)),
      subtitle: Text(
        'Hint cards shown on first visit to each screen',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textLight.withValues(alpha: 0.5)),
      ),
      value: enabled,
      activeThumbColor: AppColors.torchAmber,
      onChanged: (v) =>
          ref.read(appPreferencesProvider.notifier).setTipsEnabled(v),
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

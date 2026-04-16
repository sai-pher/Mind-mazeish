import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../feedback/data/github_issue_service.dart';
import '../../data/user_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userId;
  String? _appVersion;
  late Future<List<IssueItem>> _issuesFuture;

  @override
  void initState() {
    super.initState();
    _issuesFuture = GithubIssueService.fetchOpenIssues();
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

  void _showAddComment(IssueItem issue) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.stoneDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _AddCommentSheet(
        issue: issue,
        userId: _userId,
      ),
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
              'Report a bug, request a feature, or suggest content',
              style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight.withValues(alpha: 0.5)),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppColors.stoneMid),
            onTap: () => context.push('/feedback'),
          ),

          // ── Open Issues ──────────────────────────────────────────────────
          const _SectionHeader('Open Issues'),
          FutureBuilder<List<IssueItem>>(
            future: _issuesFuture,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final issues = snap.data ?? [];
              if (issues.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(
                    'No open issues — or unable to reach GitHub.',
                    style: tt.bodySmall?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.4)),
                  ),
                );
              }
              return Column(
                children: issues.map((issue) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.stone,
                      radius: 16,
                      child: Text(
                        '#${issue.number}',
                        style: const TextStyle(
                            color: AppColors.torchAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      issue.title,
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: issue.labelNames.isNotEmpty
                        ? Text(
                            issue.labelNames.join(' · '),
                            style: TextStyle(
                                color: AppColors.textLight.withValues(alpha: 0.45),
                                fontSize: 11),
                          )
                        : null,
                    trailing: TextButton(
                      onPressed: () => _showAddComment(issue),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.torchAmber),
                      child: const Text('Comment',
                          style: TextStyle(fontSize: 12)),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  );
                }).toList(),
              );
            },
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

// ---------------------------------------------------------------------------
// Add comment bottom sheet
// ---------------------------------------------------------------------------

class _AddCommentSheet extends StatefulWidget {
  final IssueItem issue;
  final String? userId;

  const _AddCommentSheet({required this.issue, this.userId});

  @override
  State<_AddCommentSheet> createState() => _AddCommentSheetState();
}

class _AddCommentSheetState extends State<_AddCommentSheet> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final ok = await GithubIssueService.addComment(
      issueNumber: widget.issue.number,
      body: _ctrl.text.trim(),
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added — thank you!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Could not submit — check your connection and try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add comment to #${widget.issue.number}',
            style: tt.titleSmall?.copyWith(color: AppColors.parchment),
          ),
          const SizedBox(height: 4),
          Text(
            widget.issue.title,
            style: tt.bodySmall?.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.55)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            minLines: 3,
            maxLines: null,
            autofocus: true,
            style: const TextStyle(color: AppColors.textLight),
            decoration: InputDecoration(
              hintText: 'Add any additional context, updates, or follow-up…',
              hintStyle: TextStyle(
                  color: AppColors.textLight.withValues(alpha: 0.4),
                  fontSize: 13),
              filled: true,
              fillColor: AppColors.stone,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.stoneMid)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                      color: AppColors.stoneMid.withValues(alpha: 0.6))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                      color: AppColors.torchAmber, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.torchAmber,
                foregroundColor: AppColors.textDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textDark))
                  : const Icon(Icons.comment_outlined),
              label: Text(_submitting ? 'Submitting…' : 'Submit Comment',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

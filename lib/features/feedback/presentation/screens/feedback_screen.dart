import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/data/topic_registry.dart';
import '../../data/feedback_draft_repository.dart';
import '../../../settings/data/user_profile_service.dart';
import '../../data/github_issue_service.dart';

// Tab indices
const _kTabGeneral  = 0;
const _kTabContent  = 2;
const _kTabIssues   = 4;

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _appVersion;
  String? _userId;

  /// Incremented whenever a draft is saved or deleted, triggering the
  /// Pending tab to reload.
  int _draftRevision = 0;

  /// Non-null while a draft is being loaded into an input tab.
  FeedbackDraft? _loadedDraft;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _appVersion = '${i.version}+${i.buildNumber}');
    });
    UserProfileService.getUserId().then((id) {
      if (mounted) setState(() => _userId = id);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onDraftSaved() => setState(() => _draftRevision++);

  void _onDraftLoaded() => setState(() => _loadedDraft = null);

  void _loadDraft(FeedbackDraft draft) {
    setState(() => _loadedDraft = draft);
    _tabs.animateTo(
      draft.type == 'general' ? _kTabGeneral : _kTabContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.stoneDark,
        title: const Text('Feedback'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.torchAmber,
          labelColor: AppColors.torchAmber,
          unselectedLabelColor: AppColors.textLight,
          tabs: const [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'General'),
            Tab(icon: Icon(Icons.bug_report_outlined), text: 'Bug Report'),
            Tab(icon: Icon(Icons.library_add_outlined), text: 'Content'),
            Tab(icon: Icon(Icons.pending_actions_outlined), text: 'Pending'),
            Tab(icon: Icon(Icons.list_alt_outlined), text: 'Issues'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _GeneralFeedbackTab(
            appVersion: _appVersion,
            userId: _userId,
            loadedDraft: _loadedDraft?.type == 'general' ? _loadedDraft : null,
            onDraftLoaded: _onDraftLoaded,
            onDraftSaved: _onDraftSaved,
          ),
          _BugReportTab(appVersion: _appVersion),
          _ContentRequestTab(
            appVersion: _appVersion,
            userId: _userId,
            loadedDraft: _loadedDraft?.type == 'content' ? _loadedDraft : null,
            onDraftLoaded: _onDraftLoaded,
            onDraftSaved: _onDraftSaved,
          ),
          _PendingFeedbackTab(
            draftRevision: _draftRevision,
            onLoadDraft: _loadDraft,
            onDraftDeleted: _onDraftSaved,
          ),
          _IssuesTab(userId: _userId),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// General Feedback Tab
// ---------------------------------------------------------------------------

class _GeneralFeedbackTab extends StatefulWidget {
  final String? appVersion;
  final String? userId;
  final FeedbackDraft? loadedDraft;
  final VoidCallback onDraftLoaded;
  final VoidCallback onDraftSaved;

  const _GeneralFeedbackTab({
    this.appVersion,
    this.userId,
    this.loadedDraft,
    required this.onDraftLoaded,
    required this.onDraftSaved,
  });

  @override
  State<_GeneralFeedbackTab> createState() => _GeneralFeedbackTabState();
}

class _GeneralFeedbackTabState extends State<_GeneralFeedbackTab> {
  FeedbackCategory _category = FeedbackCategory.featureRequest;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _submitting = false;
  final _repo = FeedbackDraftRepository();

  @override
  void didUpdateWidget(_GeneralFeedbackTab old) {
    super.didUpdateWidget(old);
    final draft = widget.loadedDraft;
    if (draft != null && draft != old.loadedDraft) {
      _titleCtrl.text = draft.fields[FeedbackDraft.fieldTitle] ?? '';
      _bodyCtrl.text  = draft.fields[FeedbackDraft.fieldBody] ?? '';
      final catName   = draft.fields[FeedbackDraft.fieldCategory];
      if (catName != null) {
        final cat = FeedbackCategory.values
            .where((c) => c.name == catName)
            .firstOrNull;
        if (cat != null) setState(() => _category = cat);
      }
      widget.onDraftLoaded();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      _showSnack('Please fill in both fields.');
      return;
    }
    setState(() => _submitting = true);
    final ok = await GithubIssueService.submitFeedback(
      category: _category,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      appVersion: widget.appVersion,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _titleCtrl.clear();
      _bodyCtrl.clear();
    }
    _showSnack(ok
        ? 'Thank you! Your feedback has been submitted.'
        : 'Could not submit — check your connection and try again.');
  }

  Future<void> _saveDraft() async {
    if (_titleCtrl.text.trim().isEmpty && _bodyCtrl.text.trim().isEmpty) {
      _showSnack('Nothing to save — fill in at least one field.');
      return;
    }
    final draft = FeedbackDraft(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'general',
      fields: {
        FeedbackDraft.fieldTitle:    _titleCtrl.text,
        FeedbackDraft.fieldBody:     _bodyCtrl.text,
        FeedbackDraft.fieldCategory: _category.name,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.save(draft);
    if (!mounted) return;
    widget.onDraftSaved();
    _showSnack('Draft saved — find it in the Pending tab.');
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What kind of feedback?', style: tt.labelLarge?.copyWith(color: AppColors.textLight)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FeedbackCategory.values.map((c) {
              final selected = _category == c;
              return ChoiceChip(
                label: Text('${c.emoji} ${c.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _category = c),
                selectedColor: AppColors.torchAmber,
                backgroundColor: AppColors.stone,
                labelStyle: TextStyle(
                  color: selected ? AppColors.textDark : AppColors.textLight,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _titleCtrl,
            label: 'Title',
            hint: 'Brief summary (e.g. "App crashes on results screen")',
            maxLines: 1,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _bodyCtrl,
            label: 'Details',
            hint: 'Describe the issue or idea in as much detail as you like…',
            minLines: 6,
            maxLines: null,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    side: const BorderSide(color: AppColors.stoneMid),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.torchAmber,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Submitting…' : 'Submit',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (widget.appVersion != null) ...[
            const SizedBox(height: 12),
            Text('v${widget.appVersion}',
                style: tt.labelSmall?.copyWith(
                    color: AppColors.textLight.withValues(alpha: 0.35))),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bug Report Tab
// ---------------------------------------------------------------------------

class _BugReportTab extends StatefulWidget {
  final String? appVersion;
  const _BugReportTab({this.appVersion});

  @override
  State<_BugReportTab> createState() => _BugReportTabState();
}

class _BugReportTabState extends State<_BugReportTab> {
  final _titleCtrl          = TextEditingController();
  final _givenCtrl          = TextEditingController();
  final _whenCtrl           = TextEditingController();
  final _thenExpectedCtrl   = TextEditingController();
  final _butActuallyCtrl    = TextEditingController();
  final _supportingCtrl     = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _givenCtrl.dispose();
    _whenCtrl.dispose();
    _thenExpectedCtrl.dispose();
    _butActuallyCtrl.dispose();
    _supportingCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _givenCtrl.text.trim().isEmpty ||
        _whenCtrl.text.trim().isEmpty ||
        _thenExpectedCtrl.text.trim().isEmpty ||
        _butActuallyCtrl.text.trim().isEmpty) {
      _showSnack('Please fill in all required fields.');
      return;
    }
    setState(() => _submitting = true);
    final ok = await GithubIssueService.submitBugReport(
      title: _titleCtrl.text.trim(),
      given: _givenCtrl.text.trim(),
      when: _whenCtrl.text.trim(),
      thenExpected: _thenExpectedCtrl.text.trim(),
      butActually: _butActuallyCtrl.text.trim(),
      supportingDetails: _supportingCtrl.text.trim().isEmpty
          ? null
          : _supportingCtrl.text.trim(),
      appVersion: widget.appVersion,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _titleCtrl.clear();
      _givenCtrl.clear();
      _whenCtrl.clear();
      _thenExpectedCtrl.clear();
      _butActuallyCtrl.clear();
      _supportingCtrl.clear();
    }
    _showSnack(ok
        ? 'Bug report submitted — thank you!'
        : 'Could not submit — check your connection and try again.');
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe the bug using the structured fields below. '
            'Required fields are marked *.',
            style: tt.bodySmall?.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _titleCtrl,
            label: 'Title *',
            hint: 'One-line summary (e.g. "App crashes on results screen")',
            maxLines: 1,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _givenCtrl,
            label: 'Given * — scenario and conditions',
            hint: 'Describe the situation and any conditions needed to reproduce…',
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _whenCtrl,
            label: 'When * — the action you took',
            hint: 'Describe the specific action or feature you attempted…',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _thenExpectedCtrl,
            label: 'Then Expected * — what should have happened',
            hint: 'Describe the behaviour you expected to see…',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _butActuallyCtrl,
            label: 'But Actually * — what actually happened',
            hint: 'Describe what you observed instead…',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _supportingCtrl,
            label: 'Supporting details (optional)',
            hint: 'Any extra context, error messages, or steps to reproduce consistently…',
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textLight))
                  : const Icon(Icons.bug_report),
              label: Text(_submitting ? 'Submitting…' : 'Submit Bug Report',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (widget.appVersion != null) ...[
            const SizedBox(height: 12),
            Text('v${widget.appVersion}',
                style: tt.labelSmall?.copyWith(
                    color: AppColors.textLight.withValues(alpha: 0.35))),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Content Request Tab
// ---------------------------------------------------------------------------

class _ContentRequestTab extends StatefulWidget {
  final String? appVersion;
  final String? userId;
  final FeedbackDraft? loadedDraft;
  final VoidCallback onDraftLoaded;
  final VoidCallback onDraftSaved;

  const _ContentRequestTab({
    this.appVersion,
    this.userId,
    this.loadedDraft,
    required this.onDraftLoaded,
    required this.onDraftSaved,
  });

  @override
  State<_ContentRequestTab> createState() => _ContentRequestTabState();
}

class _ContentRequestTabState extends State<_ContentRequestTab> {
  ContentRequestType _type = ContentRequestType.newTopic;
  String? _selectedTopicId;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _submitting = false;
  final _repo = FeedbackDraftRepository();

  @override
  void didUpdateWidget(_ContentRequestTab old) {
    super.didUpdateWidget(old);
    final draft = widget.loadedDraft;
    if (draft != null && draft != old.loadedDraft) {
      _titleCtrl.text     = draft.fields[FeedbackDraft.fieldTitle] ?? '';
      _bodyCtrl.text      = draft.fields[FeedbackDraft.fieldBody] ?? '';
      _selectedTopicId    = draft.fields[FeedbackDraft.fieldTopicId];
      final rtName        = draft.fields[FeedbackDraft.fieldRequestType];
      if (rtName != null) {
        final rt = ContentRequestType.values
            .where((t) => t.name == rtName)
            .firstOrNull;
        if (rt != null) setState(() => _type = rt);
      }
      widget.onDraftLoaded();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a title.');
      return;
    }
    if (_type == ContentRequestType.moreQuestions && _selectedTopicId == null) {
      _showSnack('Please select a topic.');
      return;
    }
    setState(() => _submitting = true);
    final ok = await GithubIssueService.submitContentRequest(
      type: _type,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim().isEmpty
          ? '(No additional notes provided.)'
          : _bodyCtrl.text.trim(),
      topicId: _selectedTopicId,
      appVersion: widget.appVersion,
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _selectedTopicId = null);
    }
    _showSnack(ok
        ? 'Content request submitted — thank you!'
        : 'Could not submit — check your connection and try again.');
  }

  Future<void> _saveDraft() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnack('Nothing to save — fill in at least a title.');
      return;
    }
    final draft = FeedbackDraft(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'content',
      fields: {
        FeedbackDraft.fieldRequestType: _type.name,
        FeedbackDraft.fieldTitle:        _titleCtrl.text,
        FeedbackDraft.fieldBody:         _bodyCtrl.text,
        if (_selectedTopicId != null)
          FeedbackDraft.fieldTopicId: _selectedTopicId!,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.save(draft);
    if (!mounted) return;
    widget.onDraftSaved();
    _showSnack('Draft saved — find it in the Pending tab.');
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final allTopics = superCategories
        .expand((sc) => sc.categories.expand((c) => c.topics))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request type', style: tt.labelLarge?.copyWith(color: AppColors.textLight)),
          const SizedBox(height: 10),
          RadioGroup<ContentRequestType>(
            groupValue: _type,
            onChanged: (v) => setState(() {
              _type = v!;
              _selectedTopicId = null;
            }),
            child: Column(
              children: ContentRequestType.values
                  .map((t) => RadioListTile<ContentRequestType>(
                        value: t,
                        title: Text(t.label,
                            style: const TextStyle(color: AppColors.textLight)),
                        activeColor: AppColors.torchAmber,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (_type == ContentRequestType.newTopic) ...[
            _Field(
              controller: _titleCtrl,
              label: 'Topic name',
              hint: 'e.g. "Jazz Music" or "Ancient Rome"',
              maxLines: 1,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _bodyCtrl,
              label: 'Why this topic? (optional)',
              hint: 'Tell us why you\'d love to see this topic in the game…',
              minLines: 4,
              maxLines: null,
            ),
          ] else ...[
            Text('Which topic?', style: tt.labelLarge?.copyWith(color: AppColors.textLight)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.stone,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.stoneMid),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTopicId,
                  hint: const Text('Select a topic',
                      style: TextStyle(color: AppColors.textLight)),
                  dropdownColor: AppColors.stone,
                  isExpanded: true,
                  items: allTopics.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.emoji} ${t.name}',
                        style: const TextStyle(color: AppColors.textLight)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedTopicId = v),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _titleCtrl,
              label: 'What specifically would you like?',
              hint: 'e.g. "More hard questions", "Focus on 19th century"',
              maxLines: 1,
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _bodyCtrl,
              label: 'Additional notes (optional)',
              hint: 'Any specific questions or areas to cover?',
              minLines: 4,
              maxLines: null,
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveDraft,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    side: const BorderSide(color: AppColors.stoneMid),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.torchAmber,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Submitting…' : 'Submit',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Feedback Tab
// ---------------------------------------------------------------------------

class _PendingFeedbackTab extends StatefulWidget {
  final int draftRevision;
  final void Function(FeedbackDraft) onLoadDraft;
  final VoidCallback onDraftDeleted;

  const _PendingFeedbackTab({
    required this.draftRevision,
    required this.onLoadDraft,
    required this.onDraftDeleted,
  });

  @override
  State<_PendingFeedbackTab> createState() => _PendingFeedbackTabState();
}

class _PendingFeedbackTabState extends State<_PendingFeedbackTab> {
  final _repo = FeedbackDraftRepository();
  late Future<List<FeedbackDraft>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _draftsFuture = _repo.loadAll();
  }

  @override
  void didUpdateWidget(_PendingFeedbackTab old) {
    super.didUpdateWidget(old);
    if (widget.draftRevision != old.draftRevision) {
      setState(() => _draftsFuture = _repo.loadAll());
    }
  }

  Future<void> _delete(String id) async {
    await _repo.delete(id);
    widget.onDraftDeleted();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FeedbackDraft>>(
      future: _draftsFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final drafts = snap.data ?? [];
        if (drafts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending_actions_outlined,
                      size: 48,
                      color: AppColors.textLight.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No pending feedback',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use "Save Draft" on the General or Content tab to save '
                    'feedback before sending.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: drafts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final draft = drafts[i];
            final typeLabel =
                draft.type == 'general' ? '💬 General' : '📚 Content';
            final updated = _formatRelative(draft.updatedAt);
            return Card(
              color: AppColors.stone,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => widget.onLoadDraft(draft),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              draft.displayTitle,
                              style: const TextStyle(
                                  color: AppColors.parchment,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$typeLabel · $updated',
                              style: TextStyle(
                                  color:
                                      AppColors.textLight.withValues(alpha: 0.55),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.dangerRed, size: 20),
                        tooltip: 'Discard draft',
                        onPressed: () => _delete(draft.id),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// Issues Tab
// ---------------------------------------------------------------------------

class _IssuesTab extends StatefulWidget {
  final String? userId;
  const _IssuesTab({this.userId});

  @override
  State<_IssuesTab> createState() => _IssuesTabState();
}

class _IssuesTabState extends State<_IssuesTab>
    with AutomaticKeepAliveClientMixin {
  late Future<List<IssueItem>> _issuesFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _issuesFuture = GithubIssueService.fetchOpenIssues();
  }

  void _openDetail(IssueItem issue) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.stoneDark,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _IssueDetailSheet(issue: issue, userId: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tt = Theme.of(context).textTheme;
    return FutureBuilder<List<IssueItem>>(
      future: _issuesFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final issues = snap.data ?? [];
        if (issues.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_outlined,
                      size: 48,
                      color: AppColors.textLight.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No open issues',
                    style: tt.titleMedium?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No open alpha-feedback issues found, or unable to reach GitHub.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          separatorBuilder: (_, __) => const Divider(
              color: AppColors.stoneMid, height: 1, indent: 56),
          itemBuilder: (context, i) {
            final issue = issues[i];
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
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.stoneMid, size: 18),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              onTap: () => _openDetail(issue),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Issue detail bottom sheet
// ---------------------------------------------------------------------------

class _IssueDetailSheet extends StatefulWidget {
  final IssueItem issue;
  final String? userId;

  const _IssueDetailSheet({required this.issue, this.userId});

  @override
  State<_IssueDetailSheet> createState() => _IssueDetailSheetState();
}

class _IssueDetailSheetState extends State<_IssueDetailSheet> {
  late Future<List<IssueComment>> _commentsFuture;
  bool _showCommentBox = false;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture =
        GithubIssueService.fetchIssueComments(widget.issue.number);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    final ok = await GithubIssueService.addComment(
      issueNumber: widget.issue.number,
      body: _commentCtrl.text.trim(),
      userId: widget.userId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _commentCtrl.clear();
      setState(() {
        _showCommentBox = false;
        _commentsFuture =
            GithubIssueService.fetchIssueComments(widget.issue.number);
      });
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.stoneMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.stone,
                  radius: 14,
                  child: Text(
                    '#${widget.issue.number}',
                    style: const TextStyle(
                        color: AppColors.torchAmber,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.issue.title,
                    style: tt.titleSmall?.copyWith(color: AppColors.parchment),
                  ),
                ),
              ],
            ),
          ),
          if (widget.issue.labelNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Wrap(
                spacing: 6,
                children: widget.issue.labelNames
                    .map((l) => Chip(
                          label: Text(l,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.textLight)),
                          backgroundColor: AppColors.stone,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ),
          const Divider(color: AppColors.stoneMid, height: 1),
          // Scrollable body
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.issue.body.isNotEmpty) ...[
                  Text(
                    widget.issue.body,
                    style: tt.bodyMedium?.copyWith(
                        color: AppColors.textLight.withValues(alpha: 0.85),
                        height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.stoneMid),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Comments',
                  style: tt.labelMedium?.copyWith(color: AppColors.parchment),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<IssueComment>>(
                  future: _commentsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final comments = snap.data ?? [];
                    if (comments.isEmpty) {
                      return Text(
                        'No comments yet.',
                        style: tt.bodySmall?.copyWith(
                            color:
                                AppColors.textLight.withValues(alpha: 0.4)),
                      );
                    }
                    return Column(
                      children: comments
                          .map((c) => _CommentCard(comment: c))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_showCommentBox) ...[
                  TextField(
                    controller: _commentCtrl,
                    minLines: 3,
                    maxLines: null,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: InputDecoration(
                      hintText:
                          'Add any additional context, updates, or follow-up…',
                      hintStyle: TextStyle(
                          color: AppColors.textLight.withValues(alpha: 0.4),
                          fontSize: 13),
                      filled: true,
                      fillColor: AppColors.stone,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: AppColors.stoneMid)),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _showCommentBox = false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textLight,
                            side: const BorderSide(color: AppColors.stoneMid),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submitComment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.torchAmber,
                            foregroundColor: AppColors.textDark,
                          ),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textDark))
                              : const Icon(Icons.comment_outlined, size: 16),
                          label: Text(_submitting ? 'Submitting…' : 'Submit',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showCommentBox = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.torchAmber,
                        side: const BorderSide(color: AppColors.torchAmber),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.add_comment_outlined, size: 16),
                      label: const Text('Add Comment'),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment card
// ---------------------------------------------------------------------------

class _CommentCard extends StatelessWidget {
  final IssueComment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.stoneMid.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.authorLogin,
                style: tt.labelSmall?.copyWith(
                    color: AppColors.torchAmber,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _formatDate(comment.createdAt),
                style: tt.labelSmall?.copyWith(
                    color: AppColors.textLight.withValues(alpha: 0.4)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.body,
            style: tt.bodySmall?.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.8),
                height: 1.4),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Shared field widget
// ---------------------------------------------------------------------------

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  // null = unbounded (expands with content, avoids internal scroll conflicts)
  final int? maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.parchment)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppColors.textLight.withValues(alpha: 0.4), fontSize: 13),
            filled: true,
            fillColor: AppColors.stone,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.stoneMid),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                  color: AppColors.stoneMid.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.torchAmber, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

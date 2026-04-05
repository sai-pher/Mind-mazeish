import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../gameplay/data/topic_registry.dart';
import '../../data/github_issue_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _appVersion = '${i.version}+${i.buildNumber}');
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
            Tab(icon: Icon(Icons.library_add_outlined), text: 'Content Request'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _GeneralFeedbackTab(appVersion: _appVersion),
          _ContentRequestTab(appVersion: _appVersion),
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
  const _GeneralFeedbackTab({this.appVersion});

  @override
  State<_GeneralFeedbackTab> createState() => _GeneralFeedbackTabState();
}

class _GeneralFeedbackTabState extends State<_GeneralFeedbackTab> {
  FeedbackCategory _category = FeedbackCategory.featureRequest;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _submitting = false;
  bool _submitted  = false;

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
    );
    if (!mounted) return;
    setState(() { _submitting = false; _submitted = ok; });
    if (ok) {
      _titleCtrl.clear();
      _bodyCtrl.clear();
    }
    _showSnack(ok
        ? 'Thank you! Your feedback has been submitted.'
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
            maxLines: 6,
          ),
          const SizedBox(height: 24),
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
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Submitting…' : 'Submit Feedback',
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
  const _ContentRequestTab({this.appVersion});

  @override
  State<_ContentRequestTab> createState() => _ContentRequestTabState();
}

class _ContentRequestTabState extends State<_ContentRequestTab> {
  ContentRequestType _type = ContentRequestType.newTopic;
  String? _selectedTopicId;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  bool _submitting = false;

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

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    // Flat list of all topics for the picker
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
          ...ContentRequestType.values.map((t) => RadioListTile<ContentRequestType>(
            value: t,
            groupValue: _type,
            onChanged: (v) => setState(() {
              _type = v!;
              _selectedTopicId = null;
            }),
            title: Text(t.label,
                style: const TextStyle(color: AppColors.textLight)),
            activeColor: AppColors.torchAmber,
            contentPadding: EdgeInsets.zero,
            dense: true,
          )),
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
              maxLines: 4,
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
              maxLines: 4,
            ),
          ],

          const SizedBox(height: 24),
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
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                  : const Icon(Icons.send),
              label: Text(_submitting ? 'Submitting…' : 'Submit Request',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared field widget
// ---------------------------------------------------------------------------

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLines,
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

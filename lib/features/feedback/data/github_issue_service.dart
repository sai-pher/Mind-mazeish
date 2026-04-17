import 'dart:convert';
import 'package:http/http.dart' as http;

/// Injected at build time via --dart-define=FEEDBACK_GITHUB_PAT=<token>
/// Never hard-code the token here. See README → "Wiring up the feedback PAT".
const _kGithubToken = String.fromEnvironment('FEEDBACK_GITHUB_PAT');
const _kRepoOwner   = 'sai-pher';
const _kRepoName    = 'Mind-mazeish';

enum FeedbackCategory {
  bug('Bug Report',            ['bug'],             '🐛'),
  featureRequest('Feature Request', ['enhancement'], '✨'),
  uiUx('UI / UX',              ['ui-ux'],           '🎨'),
  improvement('Improvement',   ['improvement'],     '🔧'),
  other('Other',               ['feedback'],        '💬');

  const FeedbackCategory(this.label, this.githubLabels, this.emoji);
  final String label;
  final List<String> githubLabels;
  final String emoji;
}

enum ContentRequestType {
  newTopic('Suggest a new topic'),
  moreQuestions('Request more questions for an existing topic');

  const ContentRequestType(this.label);
  final String label;
}

enum IssueSort {
  /// Sort by issue number (created date descending) — default.
  byNumber,
  /// Sort by latest activity (updated date descending).
  byActivity,
}

/// A minimal view of a GitHub issue returned by [GithubIssueService.fetchOpenIssues].
class IssueItem {
  final int number;
  final String title;
  final String body;
  final List<String> labelNames;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int commentCount;
  final String? linkedPrUrl;

  const IssueItem({
    required this.number,
    required this.title,
    required this.body,
    required this.labelNames,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
    this.linkedPrUrl,
  });

  /// Whether this entry is a pull request (GitHub returns PRs via the issues endpoint).
  bool get isPullRequest => linkedPrUrl != null;

  factory IssueItem.fromJson(Map<String, dynamic> json) => IssueItem(
        number: json['number'] as int,
        title: json['title'] as String,
        body: (json['body'] as String?) ?? '',
        labelNames: (json['labels'] as List)
            .map((l) => l['name'] as String)
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.parse(json['created_at'] as String),
        commentCount: (json['comments'] as int?) ?? 0,
        // 'pull_request' key is present when the item itself is a PR.
        linkedPrUrl: (json['pull_request'] as Map<String, dynamic>?)?['html_url'] as String?,
      );
}

/// A single comment on a GitHub issue.
class IssueComment {
  final int id;
  final String body;
  final String authorLogin;
  final DateTime createdAt;

  const IssueComment({
    required this.id,
    required this.body,
    required this.authorLogin,
    required this.createdAt,
  });

  factory IssueComment.fromJson(Map<String, dynamic> json) => IssueComment(
        id: json['id'] as int,
        body: (json['body'] as String?) ?? '',
        authorLogin: (json['user'] as Map<String, dynamic>)['login'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class GithubIssueService {
  static final _client = http.Client();

  static Future<bool> submitFeedback({
    required FeedbackCategory category,
    required String title,
    required String body,
    String? appVersion,
    String? userId,
    String? attribution,
  }) async {
    final issueBody = '''
${body.trim()}

---
**Category:** ${category.emoji} ${category.label}
**App version:** ${appVersion ?? 'unknown'}
${attribution != null ? '**Submitted by:** $attribution\n' : userId != null ? '**User ID:** `$userId`\n' : ''}**Source:** In-app feedback
''';

    return _createIssue(
      title: '[${category.label}] $title',
      body: issueBody,
      labels: [...category.githubLabels, 'alpha-feedback'],
    );
  }

  static Future<bool> submitBugReport({
    required String title,
    required String given,
    required String when,
    required String thenExpected,
    required String butActually,
    String? supportingDetails,
    String? appVersion,
  }) async {
    final issueBody = '''
**Given**
${given.trim()}

**When**
${when.trim()}

**Then Expected**
${thenExpected.trim()}

**But Actually**
${butActually.trim()}

${supportingDetails != null && supportingDetails.trim().isNotEmpty ? '**Supporting details**\n${supportingDetails.trim()}\n\n' : ''}---
**Category:** 🐛 Bug Report
**App version:** ${appVersion ?? 'unknown'}
**Source:** In-app feedback
''';

    return _createIssue(
      title: '[Bug Report] $title',
      body: issueBody,
      labels: ['bug', 'alpha-feedback'],
    );
  }

  static Future<bool> submitContentRequest({
    required ContentRequestType type,
    required String title,
    required String body,
    String? topicId,
    String? appVersion,
    String? userId,
    String? attribution,
  }) async {
    final issueBody = '''
${body.trim()}

---
**Request type:** ${type.label}
${topicId != null ? '**Topic ID:** `$topicId`\n' : ''}**App version:** ${appVersion ?? 'unknown'}
${attribution != null ? '**Submitted by:** $attribution\n' : userId != null ? '**User ID:** `$userId`\n' : ''}**Source:** In-app content request
''';

    return _createIssue(
      title: '[Content Request] $title',
      body: issueBody,
      labels: ['content-request', 'alpha-feedback'],
    );
  }

  /// Fetches open issues tagged with [alpha-feedback].
  ///
  /// [sort] controls ordering: by issue number (default) or latest activity.
  static Future<List<IssueItem>> fetchOpenIssues({
    int perPage = 50,
    IssueSort sort = IssueSort.byNumber,
  }) async {
    if (_kGithubToken.isEmpty) return [];
    try {
      final sortParam = sort == IssueSort.byActivity ? 'updated' : 'created';
      final uri = Uri.parse(
        'https://api.github.com/repos/$_kRepoOwner/$_kRepoName/issues'
        '?state=open&labels=alpha-feedback&per_page=$perPage&sort=$sortParam&direction=desc',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List;
      // GitHub API may return pull requests in the issues endpoint — exclude them.
      return list
          .map((j) => IssueItem.fromJson(j as Map<String, dynamic>))
          .where((item) => item.linkedPrUrl == null)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches comments for a single issue (most recent last).
  static Future<List<IssueComment>> fetchIssueComments(int issueNumber) async {
    if (_kGithubToken.isEmpty) return [];
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_kRepoOwner/$_kRepoName/issues/$issueNumber/comments'
        '?per_page=50&sort=created&direction=asc',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List;
      return list
          .map((j) => IssueComment.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns the set of issue numbers that have at least one open PR referencing them.
  ///
  /// Parses `Closes #N`, `Fixes #N`, `Resolves #N`, and bare `#N` patterns
  /// from open PR titles and bodies.
  static Future<Set<int>> fetchIssueNumbersWithOpenPr() async {
    if (_kGithubToken.isEmpty) return {};
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_kRepoOwner/$_kRepoName/pulls'
        '?state=open&per_page=50',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return {};
      final prs = jsonDecode(response.body) as List;
      final referenced = <int>{};
      final pattern = RegExp(r'(?:closes?|fixes?|resolves?|#)\s*#?(\d+)', caseSensitive: false);
      for (final pr in prs) {
        final title = (pr['title'] as String?) ?? '';
        final body = (pr['body'] as String?) ?? '';
        for (final text in [title, body]) {
          for (final match in pattern.allMatches(text)) {
            final n = int.tryParse(match.group(1)!);
            if (n != null) referenced.add(n);
          }
        }
      }
      return referenced;
    } catch (_) {
      return {};
    }
  }

  /// Adds a comment to an existing issue. Returns true on success.
  ///
  /// [attribution] — formatted display name (e.g. "🧙 Ada"); used when set.
  /// [userId] — fallback anonymous ID when [attribution] is null.
  static Future<bool> addComment({
    required int issueNumber,
    required String body,
    String? attribution,
    String? userId,
  }) async {
    if (_kGithubToken.isEmpty) return false;
    final String commentBody;
    if (attribution != null) {
      commentBody = '$body\n\n---\n**Submitted by:** $attribution';
    } else if (userId != null) {
      commentBody = '$body\n\n---\n**User ID:** `$userId`';
    } else {
      commentBody = body;
    }
    try {
      final response = await _client
          .post(
            Uri.parse(
                'https://api.github.com/repos/$_kRepoOwner/$_kRepoName/issues/$issueNumber/comments'),
            headers: _headers,
            body: jsonEncode({'body': commentBody}),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _createIssue({
    required String title,
    required String body,
    required List<String> labels,
  }) async {
    if (_kGithubToken.isEmpty) return false;
    try {
      final response = await _client
          .post(
            Uri.parse(
                'https://api.github.com/repos/$_kRepoOwner/$_kRepoName/issues'),
            headers: _headers,
            body: jsonEncode({
              'title': title,
              'body': body,
              'labels': labels,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_kGithubToken',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      };
}

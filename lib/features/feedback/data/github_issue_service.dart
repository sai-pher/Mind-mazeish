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

/// A minimal view of a GitHub issue returned by [GithubIssueService.fetchOpenIssues].
class IssueItem {
  final int number;
  final String title;
  final String body;
  final List<String> labelNames;
  final DateTime createdAt;

  const IssueItem({
    required this.number,
    required this.title,
    required this.body,
    required this.labelNames,
    required this.createdAt,
  });

  factory IssueItem.fromJson(Map<String, dynamic> json) => IssueItem(
        number: json['number'] as int,
        title: json['title'] as String,
        body: (json['body'] as String?) ?? '',
        labelNames: (json['labels'] as List)
            .map((l) => l['name'] as String)
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
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

  /// Fetches open issues tagged with [alpha-feedback] (most recent first).
  static Future<List<IssueItem>> fetchOpenIssues({int perPage = 30}) async {
    if (_kGithubToken.isEmpty) return [];
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_kRepoOwner/$_kRepoName/issues'
        '?state=open&labels=alpha-feedback&per_page=$perPage&sort=created&direction=desc',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List;
      return list
          .map((j) => IssueItem.fromJson(j as Map<String, dynamic>))
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

  /// Adds a comment to an existing issue. Returns true on success.
  static Future<bool> addComment({
    required int issueNumber,
    required String body,
    String? userId,
  }) async {
    if (_kGithubToken.isEmpty) return false;
    final commentBody = userId != null
        ? '$body\n\n---\n**User ID:** `$userId`'
        : body;
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

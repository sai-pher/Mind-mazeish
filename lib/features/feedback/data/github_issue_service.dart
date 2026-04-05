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

class GithubIssueService {
  static final _client = http.Client();

  static Future<bool> submitFeedback({
    required FeedbackCategory category,
    required String title,
    required String body,
    String? appVersion,
  }) async {
    final issueBody = '''
${body.trim()}

---
**Category:** ${category.emoji} ${category.label}
**App version:** ${appVersion ?? 'unknown'}
**Source:** In-app feedback
''';

    return _createIssue(
      title: '[${category.label}] $title',
      body: issueBody,
      labels: [...category.githubLabels, 'alpha-feedback'],
    );
  }

  static Future<bool> submitContentRequest({
    required ContentRequestType type,
    required String title,
    required String body,
    String? topicId,
    String? appVersion,
  }) async {
    final issueBody = '''
${body.trim()}

---
**Request type:** ${type.label}
${topicId != null ? '**Topic ID:** `$topicId`\n' : ''}**App version:** ${appVersion ?? 'unknown'}
**Source:** In-app content request
''';

    return _createIssue(
      title: '[Content Request] $title',
      body: issueBody,
      labels: ['content-request', 'alpha-feedback'],
    );
  }

  static Future<bool> _createIssue({
    required String title,
    required String body,
    required List<String> labels,
  }) async {
    if (_kGithubToken == 'REPLACE_WITH_WRITE_ONLY_PAT') return false;
    try {
      final response = await _client
          .post(
            Uri.parse(
                'https://api.github.com/repos/$_kRepoOwner/$_kRepoName/issues'),
            headers: {
              'Authorization': 'Bearer $_kGithubToken',
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'Content-Type': 'application/json',
            },
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
}

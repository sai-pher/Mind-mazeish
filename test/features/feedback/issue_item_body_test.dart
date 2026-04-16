import 'package:flutter_test/flutter_test.dart';

import 'package:mind_maze/features/feedback/data/github_issue_service.dart';

// Regression test for sai-pher/Mind-mazeish#77
//
// Root cause: IssueItem.fromJson did not parse the `body` field from the
// GitHub API response, so descriptions were never available to the UI.
// IssueComment and fetchIssueComments() did not exist at all.
//
// Fix: `body` added to IssueItem; IssueComment model and
// fetchIssueComments() added to GithubIssueService.

void main() {
  group('IssueItem.fromJson', () {
    test('parses body field when present', () {
      final json = {
        'number': 42,
        'title': 'Test issue',
        'body': 'This is the issue description.',
        'labels': <dynamic>[],
        'created_at': '2026-04-16T10:00:00Z',
      };

      final item = IssueItem.fromJson(json);

      expect(item.body, equals('This is the issue description.'));
    });

    test('defaults body to empty string when null', () {
      final json = {
        'number': 43,
        'title': 'No body issue',
        'body': null,
        'labels': <dynamic>[],
        'created_at': '2026-04-16T10:00:00Z',
      };

      final item = IssueItem.fromJson(json);

      expect(item.body, equals(''));
    });

    test('parses number, title, labels and createdAt unchanged', () {
      final json = {
        'number': 77,
        'title': '[Bug Report] Issue descriptions not viewable',
        'body': 'Some body text.',
        'labels': [
          {'name': 'bug'},
          {'name': 'alpha-feedback'},
        ],
        'created_at': '2026-04-16T15:43:44Z',
      };

      final item = IssueItem.fromJson(json);

      expect(item.number, equals(77));
      expect(item.title, equals('[Bug Report] Issue descriptions not viewable'));
      expect(item.labelNames, equals(['bug', 'alpha-feedback']));
      expect(item.createdAt, equals(DateTime.parse('2026-04-16T15:43:44Z')));
    });
  });

  group('IssueComment.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 12345,
        'body': 'This is a comment.',
        'user': {'login': 'sai-pher'},
        'created_at': '2026-04-16T18:20:03Z',
      };

      final comment = IssueComment.fromJson(json);

      expect(comment.id, equals(12345));
      expect(comment.body, equals('This is a comment.'));
      expect(comment.authorLogin, equals('sai-pher'));
      expect(comment.createdAt, equals(DateTime.parse('2026-04-16T18:20:03Z')));
    });

    test('defaults body to empty string when null', () {
      final json = {
        'id': 99,
        'body': null,
        'user': {'login': 'ghost'},
        'created_at': '2026-04-16T12:00:00Z',
      };

      final comment = IssueComment.fromJson(json);

      expect(comment.body, equals(''));
    });
  });
}

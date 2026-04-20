import 'package:flutter_test/flutter_test.dart';

// Regression test for sai-pher/Mind-mazeish#114
//
// Root cause: the PR-reference regex in fetchIssueNumbersWithOpenPr() included
// a bare '#' alternative — RegExp(r'(?:closes?|fixes?|resolves?|#)\s*#?(\d+)')
// — which matched ANY '#N' mention in a PR body (e.g. "see #76", "relates to
// #91"), flagging issues as having an open PR even when none exists.
//
// Fix: removed the bare '#' branch; pattern now requires an explicit closing
// keyword: RegExp(r'(?:closes?|fixes?|resolves?)\s+#(\d+)')

final _pattern =
    RegExp(r'(?:closes?|fixes?|resolves?)\s+#(\d+)', caseSensitive: false);

Set<int> _extract(String text) => _pattern
    .allMatches(text)
    .map((m) => int.tryParse(m.group(1)!))
    .whereType<int>()
    .toSet();

void main() {
  group('PR closing-keyword pattern', () {
    test('matches Closes #N', () {
      expect(_extract('Closes #110'), equals({110}));
    });

    test('matches Close #N (without s)', () {
      expect(_extract('Close #110'), equals({110}));
    });

    test('matches Fixes #N', () {
      expect(_extract('Fixes #42'), equals({42}));
    });

    test('matches Fix #N', () {
      expect(_extract('Fix #42'), equals({42}));
    });

    test('matches Resolves #N', () {
      expect(_extract('Resolves #7'), equals({7}));
    });

    test('matches Resolve #N', () {
      expect(_extract('Resolve #7'), equals({7}));
    });

    test('is case-insensitive', () {
      expect(_extract('CLOSES #99'), equals({99}));
      expect(_extract('fixes #99'), equals({99}));
    });

    test('extracts multiple closing references from a PR body', () {
      const body = '''
Closes #110
Closes #112

Some additional context.
''';
      expect(_extract(body), equals({110, 112}));
    });

    test('does NOT match bare #N references — the bug', () {
      expect(_extract('See #76 for background'), isEmpty);
      expect(_extract('Related to #91, #94'), isEmpty);
      expect(_extract('Investigated in #107'), isEmpty);
    });

    test('does NOT match #N when preceded by non-keyword text', () {
      expect(_extract('issue #76'), isEmpty);
      expect(_extract('PR #113'), isEmpty);
    });

    test('does not double-count when body mixes closing and casual mentions', () {
      const body = 'Closes #110\nSee also #76 and #91 for background.';
      expect(_extract(body), equals({110}));
    });
  });
}

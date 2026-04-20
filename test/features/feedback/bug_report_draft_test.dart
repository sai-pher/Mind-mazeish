import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mind_mazeish/features/feedback/data/feedback_draft_repository.dart';

// Regression test for sai-pher/Mind-mazeish#110
//
// Root cause: _BugReportTab had no Save Draft button, no loadedDraft prop, and
// no didUpdateWidget() restore logic. FeedbackDraft also lacked field-name
// constants for the six bug-report fields.
//
// Fix: added fieldGiven/fieldWhen/fieldThenExpected/fieldButActually/
// fieldSupportingDetails constants and wired _BugReportTab identically to the
// General and Content tabs.

void main() {
  group('FeedbackDraft — bug type', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('bug draft round-trips all six fields through the repository',
        () async {
      final repo = FeedbackDraftRepository();
      final draft = FeedbackDraft(
        id: '1',
        type: 'bug',
        fields: {
          FeedbackDraft.fieldTitle:            'App crashes on results',
          FeedbackDraft.fieldGiven:            'A game has just finished',
          FeedbackDraft.fieldWhen:             'User taps Continue',
          FeedbackDraft.fieldThenExpected:     'Results screen is shown',
          FeedbackDraft.fieldButActually:      'App closes silently',
          FeedbackDraft.fieldSupportingDetails: 'Reproducible on Pixel 9',
        },
        createdAt: DateTime(2026, 4, 20),
        updatedAt: DateTime(2026, 4, 20),
      );

      await repo.save(draft);
      final loaded = await repo.loadAll();

      expect(loaded, hasLength(1));
      final r = loaded.first;
      expect(r.type, equals('bug'));
      expect(r.fields[FeedbackDraft.fieldTitle],            'App crashes on results');
      expect(r.fields[FeedbackDraft.fieldGiven],            'A game has just finished');
      expect(r.fields[FeedbackDraft.fieldWhen],             'User taps Continue');
      expect(r.fields[FeedbackDraft.fieldThenExpected],     'Results screen is shown');
      expect(r.fields[FeedbackDraft.fieldButActually],      'App closes silently');
      expect(r.fields[FeedbackDraft.fieldSupportingDetails], 'Reproducible on Pixel 9');
    });

    test('displayTitle returns the title field for a bug draft', () {
      final draft = FeedbackDraft(
        id: '2',
        type: 'bug',
        fields: {FeedbackDraft.fieldTitle: 'Crash on launch'},
        createdAt: DateTime(2026, 4, 20),
        updatedAt: DateTime(2026, 4, 20),
      );
      expect(draft.displayTitle, equals('Crash on launch'));
    });

    test('displayTitle falls back to (no title) when title field is absent', () {
      final draft = FeedbackDraft(
        id: '3',
        type: 'bug',
        fields: {},
        createdAt: DateTime(2026, 4, 20),
        updatedAt: DateTime(2026, 4, 20),
      );
      expect(draft.displayTitle, equals('(no title)'));
    });

    test('deleting a bug draft removes it from the repository', () async {
      final repo = FeedbackDraftRepository();
      final draft = FeedbackDraft(
        id: '42',
        type: 'bug',
        fields: {FeedbackDraft.fieldTitle: 'Delete me'},
        createdAt: DateTime(2026, 4, 20),
        updatedAt: DateTime(2026, 4, 20),
      );

      await repo.save(draft);
      await repo.delete('42');
      final remaining = await repo.loadAll();

      expect(remaining, isEmpty);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression test for sai-pher/Mind-mazeish#47
//
// Root cause: a fixed maxLines value on a multi-line TextField creates an
// internal scroll viewport that conflicts with the parent SingleChildScrollView
// gesture arena on Android, causing spurious text selection instead of cursor
// repositioning.
//
// Fix: multi-line fields use minLines + maxLines: null so the field expands
// with content and has no internal scroll to conflict.

Widget _buildField({required int? maxLines, int minLines = 1}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TextField(
          minLines: minLines,
          maxLines: maxLines,
        ),
      ),
    ),
  );
}

void main() {
  group('multi-line TextField inside SingleChildScrollView', () {
    testWidgets(
        'details field: maxLines null prevents internal scroll conflict',
        (tester) async {
      await tester.pumpWidget(_buildField(minLines: 6, maxLines: null));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.maxLines, isNull,
          reason:
              'maxLines must be null so the field grows with content rather '
              'than creating an internal scroll viewport that conflicts with '
              'the parent SingleChildScrollView on Android');
      expect(tf.minLines, equals(6));
    });

    testWidgets('single-line title field: maxLines 1 is unchanged',
        (tester) async {
      await tester.pumpWidget(_buildField(minLines: 1, maxLines: 1));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.maxLines, equals(1));
    });
  });
}

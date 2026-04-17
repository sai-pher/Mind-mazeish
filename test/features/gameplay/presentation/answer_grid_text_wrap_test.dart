import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/gameplay/presentation/widgets/answer_button.dart';

void main() {
  group('AnswerButton — long text wrapping', () {
    Widget buildButton(String text) {
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AnswerButton(
              label: 'A',
              text: text,
              state: AnswerState.idle,
            ),
          ),
        ),
      );
    }

    testWidgets('short text renders without overflow', (tester) async {
      await tester.pumpWidget(buildButton('Short answer'));
      expect(tester.takeException(), isNull);
      expect(find.text('Short answer'), findsOneWidget);
    });

    testWidgets('long text renders fully without overflow', (tester) async {
      const longText =
          'A very long answer option that spans more than one line of text '
          'and should wrap rather than be clipped or cause a render overflow';
      await tester.pumpWidget(buildButton(longText));
      // No RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.text(longText), findsOneWidget);
    });
  });
}

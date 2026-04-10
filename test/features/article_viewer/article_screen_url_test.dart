import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/article_viewer/presentation/screens/article_screen.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: child),
    );

void main() {
  group('ArticleScreen URL validation', () {
    testWidgets('shows no-article placeholder when url is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ArticleScreen(url: '', title: 'Test Article')),
      );
      await tester.pump();

      expect(find.text('No article available'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows no-article placeholder when url has no scheme',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ArticleScreen(
            url: 'en.wikipedia.org/wiki/Coffee', title: 'Coffee')),
      );
      await tester.pump();

      expect(find.text('No article available'), findsOneWidget);
    });

    testWidgets('shows no-article placeholder when url is malformed',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ArticleScreen(url: 'not a url !!', title: 'Bad')),
      );
      await tester.pump();

      expect(find.text('No article available'), findsOneWidget);
    });

    // Note: Testing that a valid https URL renders WebViewWidget is not possible
    // in the flutter_test environment without mocking the webview platform channel.
    // The URL validation logic (empty/no-scheme → placeholder) is covered above.
    // Integration/manual test: tap the book icon on a question with a known URL
    // and verify the article loads in the WebView.
  });
}

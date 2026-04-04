import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env — if absent, the app boots but Claude API calls will fail with
  // a ClaudeException (handled gracefully in QuestionNotifier).
  await dotenv.load(fileName: '.env');

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    const ProviderScope(
      child: MindMazeApp(),
    ),
  );
}

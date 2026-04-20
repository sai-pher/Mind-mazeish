import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/gameplay/domain/models/quiz_config.dart';
import 'features/start/presentation/screens/start_screen.dart';
import 'features/start/presentation/screens/topic_picker_screen.dart';
import 'features/gameplay/presentation/screens/gameplay_screen.dart';
import 'features/article_viewer/presentation/screens/article_screen.dart';
import 'features/results/presentation/screens/results_screen.dart';
import 'features/notebook/presentation/screens/notebook_screen.dart';
import 'features/feedback/presentation/screens/feedback_screen.dart';
import 'features/start/presentation/screens/question_stats_screen.dart';
import 'features/start/presentation/screens/how_to_play_screen.dart';
import 'features/start/presentation/screens/mode_picker_screen.dart';
import 'features/start/presentation/screens/game_settings_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/maze/presentation/screens/maze_settings_screen.dart';
import 'features/maze/presentation/screens/maze_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const StartScreen()),
    GoRoute(
      path: '/topics',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TopicPickerScreen(
          fromSettings: extra?['fromSettings'] == true,
        );
      },
    ),
    GoRoute(
      path: '/game-settings',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final mode = extra?['mode'] as GameMode? ?? GameMode.standard;
        return GameSettingsScreen(mode: mode);
      },
    ),
    GoRoute(path: '/game', builder: (_, __) => const GameplayScreen()),
    GoRoute(
      path: '/article',
      builder: (_, state) {
        final extra = state.extra as Map<String, String>?;
        return ArticleScreen(
          url: extra?['url'] ?? '',
          title: extra?['title'] ?? 'Wikipedia',
          topicId: extra?['topicId'],
        );
      },
    ),
    GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
    GoRoute(path: '/notebook', builder: (_, __) => const NotebookScreen()),
    GoRoute(path: '/feedback', builder: (_, __) => const FeedbackScreen()),
    GoRoute(path: '/stats', builder: (_, __) => const QuestionStatsScreen()),
    GoRoute(path: '/how-to-play', builder: (_, __) => const HowToPlayScreen()),
    GoRoute(path: '/mode', builder: (_, __) => const ModePickerScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(
        path: '/maze-settings',
        builder: (_, __) => const MazeSettingsScreen()),
    GoRoute(path: '/maze', builder: (_, __) => const MazeScreen()),
  ],
);

class MindMazeApp extends ConsumerWidget {
  const MindMazeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mind Mazeish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/gameplay/presentation/screens/gameplay_screen.dart';
import 'features/article_viewer/presentation/screens/article_screen.dart';
import 'features/results/presentation/screens/results_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const GameplayScreen(),
    ),
    GoRoute(
      path: '/article',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return ArticleScreen(
          url: extra?['url'] ?? '',
          title: extra?['title'] ?? 'Wikipedia',
        );
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
  ],
);

class MindMazeApp extends ConsumerWidget {
  const MindMazeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Mind Maze',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

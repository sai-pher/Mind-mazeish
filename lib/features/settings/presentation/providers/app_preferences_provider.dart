import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_preferences_service.dart';

class AppPreferences {
  final bool tipsEnabled;
  final Set<String> seenScreens;

  const AppPreferences({
    required this.tipsEnabled,
    required this.seenScreens,
  });

  bool hasSeenScreen(String screenId) => seenScreens.contains(screenId);
}

class AppPreferencesNotifier extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() async {
    final tipsEnabled = await AppPreferencesService.getTipsEnabled();
    final seenScreens = await AppPreferencesService.getSeenScreens();
    return AppPreferences(tipsEnabled: tipsEnabled, seenScreens: seenScreens);
  }

  Future<void> setTipsEnabled(bool value) async {
    await AppPreferencesService.setTipsEnabled(value);
    ref.invalidateSelf();
  }

  Future<void> markScreenSeen(String screenId) async {
    final current = await future;
    if (current.hasSeenScreen(screenId)) return;
    await AppPreferencesService.markScreenSeen(screenId);
    ref.invalidateSelf();
  }
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesNotifier, AppPreferences>(
  AppPreferencesNotifier.new,
);

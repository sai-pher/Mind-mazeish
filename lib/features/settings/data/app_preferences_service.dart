import 'package:shared_preferences/shared_preferences.dart';

/// Persists app-wide user preferences (tips toggle, seen-screen tracking).
class AppPreferencesService {
  static const _keyTipsEnabled = 'prefs_tips_enabled';
  static const _keySeenScreens = 'prefs_seen_screens';

  static Future<bool> getTipsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTipsEnabled) ?? true;
  }

  static Future<void> setTipsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTipsEnabled, value);
  }

  static Future<Set<String>> getSeenScreens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySeenScreens)?.toSet() ?? {};
  }

  static Future<void> markScreenSeen(String screenId) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_keySeenScreens)?.toSet() ?? {};
    seen.add(screenId);
    await prefs.setStringList(_keySeenScreens, seen.toList());
  }
}

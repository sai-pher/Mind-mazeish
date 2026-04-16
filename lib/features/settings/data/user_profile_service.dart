import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/user_profile.dart';

class UserProfileService {
  static const _keyId          = 'user_profile_id';
  static const _keyDisplayName = 'user_profile_display_name';
  static const _keyEmoji       = 'user_profile_emoji';
  static const _keyGithubUrl   = 'user_profile_github_url';

  /// Returns the stable anonymous user ID, generating one if needed.
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyId);
    if (id == null || id.isEmpty) {
      id = _generateId();
      await prefs.setString(_keyId, id);
    }
    return id;
  }

  /// Returns the full profile including the anonymous ID.
  static Future<UserProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyId);
    if (id == null || id.isEmpty) {
      id = _generateId();
      await prefs.setString(_keyId, id);
    }
    return UserProfile(
      userId: id,
      displayName: prefs.getString(_keyDisplayName) ?? '',
      emoji: prefs.getString(_keyEmoji) ?? '',
      githubUrl: prefs.getString(_keyGithubUrl) ?? '',
    );
  }

  /// Persists mutable profile fields. The userId is never changed.
  static Future<void> saveProfile({
    required String displayName,
    required String emoji,
    required String githubUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, displayName.trim());
    await prefs.setString(_keyEmoji, emoji.trim());
    await prefs.setString(_keyGithubUrl, githubUrl.trim());
  }

  static String _generateId() {
    final rand = Random.secure();
    final hex = List.generate(12, (_) => rand.nextInt(16).toRadixString(16)).join();
    return 'usr_$hex';
  }
}

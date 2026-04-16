import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages a stable, anonymous local user identifier.
///
/// The ID is generated once on first use (`usr_` + 12 random hex characters)
/// and persisted in shared_preferences. It is attached to all feedback
/// submissions so reports from the same tester can be grouped without
/// requiring an account.
class UserProfileService {
  static const _key = 'user_profile_id';

  /// Returns the stored user ID, generating one if none exists yet.
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = _generateId();
      await prefs.setString(_key, id);
    }
    return id;
  }

  static String _generateId() {
    final rand = Random.secure();
    final hex = List.generate(12, (_) => rand.nextInt(16).toRadixString(16)).join();
    return 'usr_$hex';
  }
}

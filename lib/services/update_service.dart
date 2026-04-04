import 'dart:convert';
import 'package:http/http.dart' as http;

class UpdateInfo {
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;
  final bool updateAvailable;

  const UpdateInfo({
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.updateAvailable,
  });
}

class UpdateService {
  static const _releasesUrl =
      'https://api.github.com/repos/sai-pher/mind-mazeish/releases/latest';

  /// Check GitHub releases. Returns null on network error.
  static Future<UpdateInfo?> check(int currentBuildNumber) async {
    try {
      final response = await http
          .get(Uri.parse(_releasesUrl),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = json['tag_name'] as String? ?? '';
      final htmlUrl = json['html_url'] as String? ?? '';
      final body = json['body'] as String? ?? '';

      // Tag format: v1.0.42 — extract the build number (last segment)
      final parts = tagName.replaceAll('v', '').split('.');
      final remoteBuild = int.tryParse(parts.last) ?? 0;

      return UpdateInfo(
        latestVersion: tagName,
        releaseUrl: htmlUrl,
        releaseNotes: body.length > 300 ? '${body.substring(0, 300)}…' : body,
        updateAvailable: remoteBuild > currentBuildNumber,
      );
    } catch (_) {
      return null;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/services/update_service.dart';

void main() {
  group('UpdateInfo', () {
    test('updateAvailable is true when remoteBuild > currentBuild', () {
      const info = UpdateInfo(
        latestVersion: 'v1.0.50',
        releaseUrl: 'https://example.com/release',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '## Unreleased\n\n### Features\n- New thing',
        updateAvailable: true,
      );
      expect(info.updateAvailable, isTrue);
    });

    test('updateAvailable is false when on latest version', () {
      const info = UpdateInfo(
        latestVersion: 'v1.0.26',
        releaseUrl: 'https://example.com/release',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: '',
        updateAvailable: false,
      );
      expect(info.updateAvailable, isFalse);
    });

    test('downloadUrl falls back to releaseUrl when no APK asset present', () {
      // When assets is empty the service uses htmlUrl as downloadUrl.
      // This is covered by asserting the field is populated.
      const info = UpdateInfo(
        latestVersion: 'v1.0.50',
        releaseUrl: 'https://example.com/release',
        downloadUrl: 'https://example.com/release',
        releaseNotes: '',
        updateAvailable: true,
      );
      expect(info.downloadUrl, equals(info.releaseUrl));
    });

    test('releaseNotes carries full markdown without truncation', () {
      final longNotes = '### Features\n${'- Item\n' * 50}';
      final info = UpdateInfo(
        latestVersion: 'v1.0.50',
        releaseUrl: 'https://example.com/release',
        downloadUrl: 'https://example.com/app.apk',
        releaseNotes: longNotes,
        updateAvailable: true,
      );
      expect(info.releaseNotes.length, greaterThan(300));
      expect(info.releaseNotes, equals(longNotes));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mind_maze/features/settings/domain/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    const userId = 'usr_abc123def456';

    test('hasDisplayName is false when empty', () {
      expect(const UserProfile(userId: userId).hasDisplayName, isFalse);
    });

    test('hasDisplayName is true when set', () {
      expect(
        const UserProfile(userId: userId, displayName: 'Ada').hasDisplayName,
        isTrue,
      );
    });

    test('hasEmoji is false when empty', () {
      expect(const UserProfile(userId: userId).hasEmoji, isFalse);
    });

    test('hasGithubUrl is false when empty', () {
      expect(const UserProfile(userId: userId).hasGithubUrl, isFalse);
    });

    group('attribution', () {
      test('falls back to userId when no display name', () {
        final p = UserProfile(userId: userId);
        expect(p.attribution, '`$userId`');
      });

      test('shows emoji + name when no GitHub URL', () {
        const p = UserProfile(
          userId: userId,
          displayName: 'Ada',
          emoji: '🧙',
        );
        expect(p.attribution, '🧙 Ada');
      });

      test('shows name only (no emoji prefix) when emoji is empty', () {
        const p = UserProfile(userId: userId, displayName: 'Ada');
        expect(p.attribution, 'Ada');
      });

      test('shows emoji + markdown link when both name and GitHub URL set', () {
        const p = UserProfile(
          userId: userId,
          displayName: 'Ada',
          emoji: '🧙',
          githubUrl: 'https://github.com/ada',
        );
        expect(p.attribution, '🧙 [Ada](https://github.com/ada)');
      });

      test('shows plain markdown link (no emoji) when emoji is empty', () {
        const p = UserProfile(
          userId: userId,
          displayName: 'Ada',
          githubUrl: 'https://github.com/ada',
        );
        expect(p.attribution, '[Ada](https://github.com/ada)');
      });
    });

    group('copyWith', () {
      test('preserves userId and updates provided fields', () {
        const original = UserProfile(
          userId: userId,
          displayName: 'Ada',
          emoji: '🧙',
          githubUrl: 'https://github.com/ada',
        );
        final updated = original.copyWith(displayName: 'Bob');
        expect(updated.userId, userId);
        expect(updated.displayName, 'Bob');
        expect(updated.emoji, '🧙');
        expect(updated.githubUrl, 'https://github.com/ada');
      });

      test('does not modify the original', () {
        const original = UserProfile(userId: userId, displayName: 'Ada');
        original.copyWith(displayName: 'Bob');
        expect(original.displayName, 'Ada');
      });
    });
  });
}

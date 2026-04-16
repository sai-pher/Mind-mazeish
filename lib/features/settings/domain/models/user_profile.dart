class UserProfile {
  final String userId;
  final String displayName;
  final String emoji;
  final String githubUrl;

  const UserProfile({
    required this.userId,
    this.displayName = '',
    this.emoji = '',
    this.githubUrl = '',
  });

  bool get hasDisplayName => displayName.isNotEmpty;
  bool get hasEmoji => emoji.isNotEmpty;
  bool get hasGithubUrl => githubUrl.isNotEmpty;

  /// Markdown attribution line used in GitHub issue bodies.
  /// e.g. "🧙 [Ada](https://github.com/ada)" or "🧙 Ada" or just the userId.
  String get attribution {
    final emojiPart = hasEmoji ? '$emoji ' : '';
    if (hasDisplayName && hasGithubUrl) {
      return '$emojiPart[$displayName]($githubUrl)';
    }
    if (hasDisplayName) return '$emojiPart$displayName';
    return '`$userId`';
  }

  UserProfile copyWith({
    String? displayName,
    String? emoji,
    String? githubUrl,
  }) {
    return UserProfile(
      userId: userId,
      displayName: displayName ?? this.displayName,
      emoji: emoji ?? this.emoji,
      githubUrl: githubUrl ?? this.githubUrl,
    );
  }
}

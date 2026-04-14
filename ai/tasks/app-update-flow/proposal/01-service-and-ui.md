# Proposal 01: UpdateService & Dialog UI

## Goal
Fix the in-app update experience: full markdown release notes, direct APK download, auto-check on app open.

---

## 1. UpdateService changes

### Add `downloadUrl` to `UpdateInfo`
```dart
class UpdateInfo {
  final String latestVersion;
  final String releaseUrl;      // HTML page (keep for fallback)
  final String downloadUrl;     // direct APK asset URL
  final String releaseNotes;    // full body, no truncation
  final bool updateAvailable;
}
```

### Parse `assets` array from GitHub API
```dart
final assets = (json['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
final apkAsset = assets.firstWhere(
  (a) => (a['name'] as String).endsWith('.apk'),
  orElse: () => {},
);
final downloadUrl = apkAsset['browser_download_url'] as String? ?? htmlUrl;
```

### Remove the 300-char truncation
```dart
// Before
final body = json['body'] as String? ?? '';
releaseNotes: body.length > 300 ? '${body.substring(0, 300)}…' : body,

// After
releaseNotes: json['body'] as String? ?? '',
```

---

## 2. Update dialog UI

### Add `flutter_markdown` package
```yaml
# pubspec.yaml
flutter_markdown: ^0.7.6
```

### Replace plain `Text` with scrollable `MarkdownBody`
```dart
content: SingleChildScrollView(
  child: MarkdownBody(
    data: 'Version ${info.latestVersion} is available.\n\n${info.releaseNotes}',
    styleSheet: MarkdownStyleSheet(
      p: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textLight),
      h3: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.torchGold),
      code: TextStyle(color: AppColors.torchAmber, fontFamily: 'monospace'),
    ),
  ),
),
```

### Fix download button — use direct APK URL
```dart
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pop();
    launchUrl(
      Uri.parse(info.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
  },
  child: const Text('Download'),
),
```

---

## 3. Auto-check on app open

Currently the check is only triggered by user tap. Add an auto-check in `_VersionBadgeState.initState` after `_loadVersion()` completes. Show dialog only if update is available — no snackbar for "up to date" on auto-check.

```dart
Future<void> _loadVersion() async {
  final info = await PackageInfo.fromPlatform();
  if (!mounted) return;
  setState(() {
    _version = info.version;
    _buildNumber = int.tryParse(info.buildNumber) ?? 0;
  });
  // Auto-check silently on open
  _autoCheckUpdate();
}

Future<void> _autoCheckUpdate() async {
  final info = await UpdateService.check(_buildNumber);
  if (!mounted || info == null || !info.updateAvailable) return;
  _showUpdateDialog(info);
}
```

Extract dialog into `_showUpdateDialog(UpdateInfo info)` helper (shared between auto-check and manual tap).
Manual tap path: show snackbar for "up to date" or "connection error" as before.

---

## Files to touch
| File | Change |
|------|--------|
| `lib/services/update_service.dart` | Add `downloadUrl`, remove truncation, parse `assets` |
| `lib/features/start/presentation/screens/start_screen.dart` | Auto-check, `MarkdownBody`, fix download URL |
| `pubspec.yaml` | Add `flutter_markdown: ^0.7.6` |

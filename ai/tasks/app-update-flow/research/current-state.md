# Research: Current Update Flow State

## UpdateService (`lib/services/update_service.dart`)
- Calls `GET https://api.github.com/repos/sai-pher/mind-mazeish/releases/latest`
- Returns `UpdateInfo` with: `latestVersion`, `releaseUrl` (HTML page URL), `releaseNotes` (truncated at 300 chars), `updateAvailable`
- **Problem**: `releaseNotes` is hard-truncated at 300 chars — no full markdown
- **Problem**: `releaseUrl` is the HTML page URL, not a direct APK download link
- **Missing**: no `downloadUrl` field pointing to the APK asset

## Start screen update dialog (`lib/features/start/presentation/screens/start_screen.dart`)
- `_VersionBadge` widget loads version in `initState` — no auto update check on open
- User must tap `v{version} • tap to check for updates` to trigger check
- Dialog uses plain `AlertDialog` with `Text` widget — no markdown rendering
- Download button calls `launchUrl(Uri.parse(info.releaseUrl), mode: LaunchMode.externalApplication)` — opens browser to release page, not direct APK

## CD workflow (`.github/workflows/cd.yml`)
- Triggers on push to `main` or `workflow_dispatch`
- Release body generated inline: git log since last tag + optional manual `release_notes` workflow input
- **No** `release_notes.md` file — notes are generated ad hoc at build time

## CI workflow (`.github/workflows/ci.yml`)
- Runs `flutter analyze` + `flutter test --coverage`
- **No** release notes check

## Packages available
- `url_launcher: ^6.3.0` — ✓ already present
- `package_info_plus: ^10.0.0` — ✓ already present
- `flutter_markdown` — ✗ NOT present (needed for markdown rendering in update dialog)

## GitHub API — release asset URL
The `/releases/latest` response includes an `assets` array. Each asset has `browser_download_url` — this is the direct APK download link. Currently the service ignores `assets`.

## Existing hooks / skills
- No pre-commit hooks in `.git/hooks/`
- No `/release-notes` Claude skill
- No `release_notes.md` in repo root

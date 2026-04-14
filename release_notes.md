# Release Notes

## Unreleased

### Features
- Auto-check for app updates on launch — update dialog appears automatically when a new version is available
- In-app update dialog now renders release notes as formatted markdown with full scrollable content
- Download button now triggers a direct APK download instead of opening the browser release page

### Fixes
- (none)

### Content
- (none)

### Other
- Added `flutter_markdown` package for in-app markdown rendering
- `release_notes.md` introduced as single source of truth for release notes (replaces ad hoc git log in CD workflow)
- CI action `check-release-notes` added — PRs to `main` must update this file
- Pre-push git hook added (`.githooks/pre-push`) — runs `flutter analyze` and `flutter test` locally before push
- `/release-notes` Claude skill added for drafting and syncing release notes from branch context

---

## v1.0.26 — 2026-03-01
### Fixes
- Resolve UI text overflow and action button state issues (#6, #37, #41)

## v1.0.25 — 2026-02-01
### Other
- Dependency bumps: webview_flutter_android, package_info_plus, lottie, action-gh-release

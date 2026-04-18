# iOS / Web Support — Design Spec

**Issue:** sai-pher/Mind-mazeish#5  
**Date:** 2026-04-18  
**Status:** Approved

## Goal

Enable iOS users to play Mind Mazeish without a native app by deploying a Flutter web build to GitHub Pages, installable as a PWA via iOS "Add to Home Screen".

## Constraints

- Deployment must be **free**
- No new runtime packages
- Existing Android APK pipeline must be **unchanged**

## Platform Compatibility Audit

| Package | Web-compatible? | Action |
|---|---|---|
| `flutter_riverpod` | Yes | None |
| `go_router` | Yes | None |
| `google_fonts` | Yes | None |
| `lottie` | Yes | None |
| `flutter_animate` | Yes | None |
| `shared_preferences` | Yes | None |
| `http` | Yes | None |
| `url_launcher` | Yes | None |
| `package_info_plus` | Yes | None |
| `flutter_markdown` | Yes | None |
| `webview_flutter` | **No** | Conditional import — web version uses `url_launcher` |
| `webview_flutter_android` | **No** | Android-only; not imported on web |
| `open_filex` | **No** | Guarded with `kIsWeb` — never called on web |
| `path_provider` | Limited | Guarded with `kIsWeb` — never called on web |

## Code Changes

### 1. Article Viewer — conditional imports

Split `lib/features/article_viewer/presentation/screens/article_screen.dart` into three files:

**`article_screen_mobile.dart`** — existing WebView implementation (file renamed, content unchanged).

**`article_screen_web.dart`** — web-only replacement:
- Calls `url_launcher`'s `launchUrl` with the Wikipedia URL in `LaunchMode.externalApplication` (opens in system browser / new tab)
- Immediately pops the route after launching so the user returns to gameplay
- Shows a brief `SnackBar` ("Opening article in browser…") for feedback

**`article_screen.dart`** — conditional export entry point:
```dart
export 'article_screen_mobile.dart'
    if (dart.library.html) 'article_screen_web.dart';
```

All existing imports of `article_screen.dart` remain unchanged — the router and callers don't need to know about the split.

### 2. Start Screen — update flow

In `lib/features/start/presentation/screens/start_screen.dart`:
- Wrap `_checkForUpdate()` call in `initState` with `if (!kIsWeb)`
- Add `if (kIsWeb) return;` guard at the top of `_downloadAndInstall` as a safety net
- Import `package:flutter/foundation.dart` for `kIsWeb`

The update version badge remains visible on web (it shows the current build version) but tapping it on web will not trigger a download.

## Web Assets & PWA Configuration

### Enable web platform

Run `flutter create --platforms=web .` to generate the `web/` directory.

### `web/manifest.json`

```json
{
  "name": "Mind Mazeish",
  "short_name": "Mind Maze",
  "start_url": "/Mind-mazeish/",
  "display": "standalone",
  "background_color": "#1A1208",
  "theme_color": "#FF8C00",
  "description": "Medieval castle trivia game",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/Icon-maskable-192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "icons/Icon-maskable-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

### `web/index.html` additions

Add inside `<head>`:
```html
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Mind Maze">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
```

### Service worker

Generated automatically by `flutter build web` — no manual setup required.

## Deployment

**Platform:** GitHub Pages  
**URL:** `https://sai-pher.github.io/Mind-mazeish/`  
**Build flag:** `--base-href /Mind-mazeish/`  
**Branch:** `gh-pages` (auto-created on first deploy)

### One-time manual setup — GitHub Pages

These steps must be completed by a repo admin **after the first CD-web workflow run** (which creates the `gh-pages` branch):

1. Go to `https://github.com/sai-pher/Mind-mazeish/settings/pages`
2. Under **Build and deployment**, set **Source** to `Deploy from a branch`
3. Set **Branch** to `gh-pages` and folder to `/ (root)`
4. Click **Save**
5. Wait ~60 seconds, then verify the site is live at `https://sai-pher.github.io/Mind-mazeish/`

> **Order matters:** run the CD-web workflow first (push the PR to main), then configure Pages. If you configure Pages before the `gh-pages` branch exists, GitHub will show an error — just wait for the workflow to create the branch, then save the Pages setting again.

### New workflow: `.github/workflows/cd-web.yml`

Triggers on `push` to `main` and `workflow_dispatch`. Steps:
1. Checkout
2. Set up Flutter 3.41.6 stable
3. `flutter pub get`
4. `flutter analyze --fatal-infos`
5. `flutter test --reporter expanded`
6. `flutter build web --release --base-href /Mind-mazeish/`
7. Deploy `build/web/` to `gh-pages` branch via `peaceiris/actions-gh-pages@v3`

The existing `cd.yml` (APK) is **unchanged**.

## Out of Scope

- Native iOS App Store submission
- Changes to gameplay logic or question content
- Web-specific UI redesign
- Firebase or Cloudflare deployment

## iOS Install Instructions (for issue comment / README)

1. Open `https://sai-pher.github.io/Mind-mazeish/` in Safari
2. Tap the Share button → "Add to Home Screen"
3. Tap "Add" — the game launches full-screen from your home screen

## Post-Deploy Analysis Comment

Per the issue request, a comment on sai-pher/Mind-mazeish#5 will document the deployment option comparison (GitHub Pages vs Firebase Hosting vs Cloudflare Pages) with rationale for choosing GitHub Pages.

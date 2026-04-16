# Release Notes

## Unreleased

### Features
- Settings page — new screen accessible from the start screen with user profile, feedback, open issues, and app info (#45)
- Anonymous tester ID — generated locally on first launch and attached to all feedback submissions for grouping without accounts (#45)
- Comment on open issues — view active alpha-feedback issues in Settings and add follow-up comments directly from the app (#45)
- Auto-check for app updates on launch — update dialog appears automatically when a new version is available
- In-app update dialog now renders release notes as formatted markdown with full scrollable content
- Download button now triggers a direct APK download instead of opening the browser release page
- Fair multi-topic question selection — round-robin interleaving ensures every selected topic has equal representation regardless of pool size (#44)
- Difficulty bias selector (1–5) on the topic picker — tune your game from easy-skewed to hard-skewed before starting (#44)
- Visual difficulty badge on each question card: 🕯️ Easy · 🔥 Medium · ⚔️ Hard (#44)

### Fixes
- Update download no longer hangs — replaced browser-delegated download with an in-app HTTP download that shows a progress indicator, then opens the package installer directly (#60)

### Content
- Added 86 questions for Deep Sea (Physical World) with 10 new Wikipedia sources
- Added 35 questions for Physical Geography (Physical World)
- Added questions for Candy (confectionery) and Crocheting (textiles)
- Added 40 questions for Therapy (mental health) covering DBT, EMDR, and psychoanalysis
- Added 100 questions for Lily Mayne (literature & arts)

### Other
- CD pipeline now archives `## Unreleased` as a versioned section and resets it to empty stubs after each release (#61)
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

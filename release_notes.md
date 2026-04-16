# Release Notes

## Unreleased

### Features
- (none)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)
---

## v1.0.42
### Features
- (none)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)

## v1.0.41
### Features
- User profile page — set a display name, pick an emoji avatar, and optionally link a GitHub profile; display name and emoji now sign all feedback submissions (#78)
- Game stats in Settings — cumulative stats (games played, best score, win rate, accuracy, total articles found) are recorded after each game and shown on the Settings screen (#78)
- Endless mode streak counter — a 🔥 streak chip appears in the header while you maintain a correct-answer streak; streak limit scales with difficulty (easy 5 → hard 15) (#74)
- Endless mode life recovery — reaching the streak limit restores one life if you have fewer than three; if lives are full, the milestone awards streak-limit × 10 bonus points instead (#74)
- Endless mode high score — your best score is saved and shown on the results screen ("Endless Best" / "New Record!") and on the topic picker when endless mode is selected (#57)

### Fixes
- App icon no longer shows as a small image inside a white circle on Android 8.0+ devices — added adaptive icon configuration (`mipmap-anydpi-v26`) with the castle dark background (#66)

### Content
- (none)

### Other
- (none)

## v1.0.40
### Features
- Issues tab in Feedback — open alpha-feedback issues are now shown in a dedicated "Issues" tab on the Feedback screen instead of the Settings page (#77)

### Fixes
- Issue descriptions and comments now display when tapping an issue — body and comment thread were missing due to unparsed API fields and no detail view (#77)
- "Bug Report" chip removed from the General feedback tab — it was a duplicate of the dedicated Bug Report tab (#75)

### Content
- (none)

### Other
- (none)

## v1.0.39
### Features
- Structured bug report form — new "Bug Report" tab in Feedback with Given / When / Then Expected / But Actually fields for clearer, actionable reports (#48)
- Save feedback as a draft before sending — new "Pending" tab in Feedback lists saved drafts; tap to reload into the form, swipe or tap the delete icon to discard (#49)
- Settings page — new screen accessible from the start screen with user profile, feedback, open issues, and app info (#45)
- Anonymous tester ID — generated locally on first launch and attached to all feedback submissions for grouping without accounts (#45)
- Comment on open issues — view active alpha-feedback issues in Settings and add follow-up comments directly from the app (#45)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)

## v1.0.38
### Features
- Auto-check for app updates on launch — update dialog appears automatically when a new version is available
- In-app update dialog now renders release notes as formatted markdown with full scrollable content
- Download button now triggers a direct APK download instead of opening the browser release page
- Fair multi-topic question selection — round-robin interleaving ensures every selected topic has equal representation regardless of pool size (#44)
- Difficulty bias selector (1–5) on the topic picker — tune your game from easy-skewed to hard-skewed before starting (#44)
- Visual difficulty badge on each question card: 🕯️ Easy · 🔥 Medium · ⚔️ Hard (#44)

### Fixes
- Update download no longer hangs — replaced browser-delegated download with an in-app HTTP download that shows a progress indicator, then opens the package installer directly (#60)
- Feedback details field no longer triggers spurious text selection when repositioning the cursor — multi-line text fields now expand with content instead of creating an internal scroll viewport (#47)

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

## v1.0.26 — 2026-03-01
### Fixes
- Resolve UI text overflow and action button state issues (#6, #37, #41)

## v1.0.25 — 2026-02-01
### Other
- Dependency bumps: webview_flutter_android, package_info_plus, lottie, action-gh-release

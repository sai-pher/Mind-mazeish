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

## v1.0.51
### Features
- (none)

### Fixes
- Fix feedback submission on web — inject FEEDBACK_GITHUB_PAT into the web build so users can submit feedback from the GitHub Pages app

### Content
- (none)

### Other
- (none)

## v1.0.50
### Features
- (none)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)

## v1.0.49
### Features
- iOS / web support — play Mind Mazeish in any browser and install it as a PWA from Safari on iOS via "Add to Home Screen"; deployed to GitHub Pages at https://sai-pher.github.io/Mind-mazeish/ (#5)

### Fixes
- (none)

### Content
- (none)

### Other
- Add CD web workflow deploying Flutter web build to GitHub Pages on every `main` push

## v1.0.48
### Features
- New **Mode Selection** screen replaces the direct "Choose Topics" entry — two illustrated cards (Standard: stone arch door, Endless: receding corridor) each with a gear settings button for difficulty, question count, and topic selection; Endless card shows your best score badge (#58)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)

## v1.0.47
### Features
- Added a **"How to Play"** screen explaining lives, scoring, streaks, modes, wiki links, and the notebook; accessible from the start screen and from Settings (#59)
- First-visit **tip cards** slide up on the Start and Gameplay screens to orient new players; tips auto-dismiss when tapped "Got it" and never reappear (#59)
- New **Preferences** section in Settings with a "Show tips" toggle to enable or disable hint cards globally; setting is persisted across sessions (#59)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)

## v1.0.46
### Features
- After answering a question, the fun-fact sheet now shows a **"Read Article"** button that opens the Wikipedia article in the in-app viewer before proceeding (#55)
- Question bank rows are now tappable — tap any topic to open a **content-request form** and submit a request for more sources or questions (#56)
- UI scales responsively across screen sizes: content is capped at 520 dp wide on tablets, the gameplay illustration height is clamped for small phones, and the start screen title adapts to screen width (#62)

### Fixes
- Question bank URL column now shows `W/T` (questions-with-URL / total) instead of the confusing `−N` notation, and the count is calculated per-question rather than per-unique-sourceId so shared sources are counted correctly (#56)

### Content
- (none)

### Other
- (none)

## v1.0.45
### Features
- (none)

### Fixes
- Answer option text now wraps correctly instead of being clipped on long options (#54)
- Articles opened now counts all unique articles visited during the session, not just notebook-new ones (#83)
- Win rate on the stats screen is now scoped to Standard mode games only and labelled "Win Rate (Std)" — Endless games no longer dilute it (#83)

### Content
- (none)

### Other
- (none)

## v1.0.44
### Features
- (none)

### Fixes
- Added missing VIBRATE permission to AndroidManifest for haptic feedback on answer selection; documented purpose of all declared permissions (#63)

### Content
- (none)

### Other
- (none)

## v1.0.43
### Features
- Issues tab — Markdown rendering for issue body and comments, pull-to-refresh, label filter chips, sort by issue number or latest activity, comment count badge, and PR-linked indicator per issue row; added comment now signs with display name when set (#82)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)

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

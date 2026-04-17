# Plan: Release Roadmap — Triaged Issues (excl. #82)

## Context
Eight triaged alpha-feedback issues need to be worked through in a logical release order. They range from trivial UI bugs to a major UX redesign of the home flow. This plan groups them into four sequential releases, each independently shippable, with infrastructure work (responsive layout, settings) landing before features that depend on it.

---

## Issues in Scope

| Issue | Title | Type | Release |
|-------|-------|------|---------|
| #54 | Long text wrapping on answer buttons | UI bug | A — v1.1 |
| #83 | Game stats inaccurate (win rate + articles = 0) | Bug | A — v1.1 |
| #63 | App permissions audit | Improvement | A — v1.1 |
| #55 | Wiki link in answer result popup | UI feature | B — v1.2 |
| #56 | Question bank: negative URL counts + content request popup | Bug + feature | B — v1.2 |
| #62 | Flexible/responsive scaling (all screens) | Cross-cutting | B — v1.2 |
| #59 | About page + first-visit tooltips + app settings | New screens | C — v1.3 |
| #58 | Game mode selection redesign (home flow) | Major feature | D — v1.4 |

---

## Release A — v1.1: Bug Fix Sprint

**Goal:** Eliminate the most visible defects reported by alpha testers with low-risk, isolated changes.

### #54 — Long text wrapping
- **File:** `lib/features/gameplay/presentation/widgets/answer_button.dart`
- **Fix:** Ensure the `Text` inside `Expanded` has no external height cap (`maxLines`, fixed height container); `softWrap: true` is default. Investigate caller in `gameplay_screen.dart` for any fixed-height `SizedBox` or `ConstrainedBox` wrapping answer buttons.
- **Skill:** `fix-bug`

### #83 — Game stats inaccurate
- **Root cause investigation needed first** (use `investigate-issue`)
- Likely causes:
  1. `articlesFound: gs.newArticleUrls.length` — counts only *newly discovered* articles per session; articles already opened before count as 0
  2. Win rate is 0 in Endless because `won: gs.status == GameStatus.complete` never fires for Endless games that end via `gameOver`
- **Files:** `lib/features/results/presentation/screens/results_screen.dart`, `lib/features/settings/domain/models/game_stats.dart`, `lib/features/settings/data/game_stats_repository.dart`
- **Fix options:**
  - Fix articles tracking: count all articles opened in session (not just new ones), or clarify the label
  - Fix Endless win recording: define what a "win" means for Endless (e.g. any completed session, or a score milestone)
  - Add mode-scoped label: "Standard Win Rate" if win rate only counts Standard games
- **Skill:** `investigate-issue` → `fix-bug`

### #63 — App permissions
- **Audit:** `android/app/src/main/AndroidManifest.xml` — check declared permissions vs actual usage
- App uses: internet (WebView) — INTERNET is a normal permission, no runtime dialog needed
- Check: vibration (used by `flutter_animate` shake?), camera (not used), storage (not used)
- Remove any over-declared permissions; add rationale if any dangerous permission is needed
- **Skill:** `implement-feature`

---

## Release B — v1.2: Gameplay UX

**Goal:** Improve the in-game experience and developer-facing question bank; make all existing screens responsive.

### #55 — Wiki link in answer popup
- Find the `answerRevealed` phase overlay in `lib/features/gameplay/presentation/screens/gameplay_screen.dart`
- Add a "Read article" button that pushes `/article` with the current question's wiki URL
- Button should only appear if the question has a wiki URL
- **Skill:** `implement-feature`

### #56 — Question bank display + content request
- **Part 1 (bug):** Negative URL counts in `lib/features/start/presentation/screens/question_stats_screen.dart` — trace calculation and fix
- **Part 2 (feature):** Wrap each list row with `GestureDetector` → show a `showModalBottomSheet` form with:
  - Field: "New sources to request" (number)
  - Field: "New questions to request" (number)
  - Submit → write a `ContentRequest` entry to a local list (or SharedPreferences log) + show a confirmation snackbar
- **Skill:** `fix-bug` (Part 1) then `implement-feature` (Part 2)

### #62 — Flexible/responsive scaling
- **Audit:** identify all hardcoded pixel values in layout widgets
- **Strategy:** use `MediaQuery.of(context).size` or `LayoutBuilder` to scale padding/font sizes; avoid third-party ScreenUtil unless already in pubspec
- **Screens to fix:** `StartScreen`, `TopicPickerScreen`, `GameplayScreen`, `ResultsScreen`, `QuestionCard`, `AnswerButton`, `RoomHeader`, `QuestionStatsScreen`
- **Test points:** 360dp (Pixel 6), 412dp (Pixel 9, baseline), 480dp (large phone), 600dp+ (tablet)
- **Key rule:** no hardcoded sizes in new widgets; use `Theme.of(context).textTheme` scales and fractional padding
- **Skill:** `implement-feature`

---

## Release C — v1.3: Onboarding & Settings

**Goal:** Help new users learn the game; establish the settings infrastructure needed by the mode redesign in D.

### #59 — About page + first-visit tooltips + app settings
- **New route:** `/about` — `AboutScreen` with "How to Play" content (rooms, lives, scoring, streak, wiki)
- **New route:** `/settings` — `AppSettingsScreen` with at minimum:
  - "Show gameplay tips" toggle (persisted via `SharedPreferences`)
- **First-visit coach marks:**
  - Store visited-screens set in `SharedPreferences` (key: `visited_screens_v1`)
  - On first visit to `/game` and `/results`, show an `OverlayEntry` coach mark or `TutorialCoachMark` package
  - Dismissed permanently once user taps "Got it"
- **Settings icon:** add to `StartScreen` AppBar → navigates to `/settings`
- **About link:** add to `/settings` or directly accessible from `StartScreen`
- **Skill:** `implement-feature`

---

## Release D — v1.4: Mode Selection Redesign

**Goal:** Replace the topic picker with a proper game-mode selection experience, surfacing Standard vs Endless clearly.

### #58 — Game mode selection
- **Replace:** `TopicPickerScreen` (or demote it to a sub-screen within mode settings)
- **New screen:** `ModeSelectionScreen` as the landing after "Play" on `StartScreen`
- **UI:** two large cards side-by-side (or stacked):
  - Standard — image: castle doors; subtitle: "Answer a set number of questions"
  - Endless — image: dark corridor or infinity symbol; subtitle: "Keep going until you fall"
- **Settings modal per mode** (bottom sheet or dialog):
  - Common: difficulty picker, topic multi-select
  - Standard only: question count slider/picker (5 / 10 / 15 / 20)
- **Wire up:** tapping "Play" on a mode card + confirming settings → pushes to `/game` with the configured `QuizConfig`
- **GoRouter:** new route `/modes`; update `/` → Play button → `/modes` instead of direct to `/game`
- **Skill:** `implement-feature`

---

## Order of Operations

1. **A1** — Investigate #83 (stats bug root cause) with `investigate-issue`
2. **A2** — Fix #54 (text wrapping) with `fix-bug`
3. **A3** — Fix #83 (stats) with `fix-bug` (informed by A1)
4. **A4** — Audit + fix #63 (permissions) with `implement-feature`
5. **A5** — PR, release v1.1
6. **B1** — Implement #55 (wiki in popup) with `implement-feature`
7. **B2** — Fix + extend #56 (question bank) with `fix-bug` + `implement-feature`
8. **B3** — Implement #62 (responsive scaling) with `implement-feature` — test on emulated sizes
9. **B4** — PR, release v1.2
10. **C1** — Implement #59 (about + tooltips + settings) with `implement-feature`
11. **C2** — PR, release v1.3
12. **D1** — Implement #58 (mode selection redesign) with `implement-feature`
13. **D2** — PR, release v1.4

---

## Files to Create / Modify

| File | Action | Release |
|------|--------|---------|
| `lib/features/gameplay/presentation/widgets/answer_button.dart` | Fix text height constraints | A |
| `lib/features/gameplay/presentation/screens/gameplay_screen.dart` | Fix answer button height + add wiki button to answer reveal | A, B |
| `lib/features/results/presentation/screens/results_screen.dart` | Fix articlesFound + win tracking | A |
| `lib/features/settings/domain/models/game_stats.dart` | Add mode-scoped win tracking or label fix | A |
| `android/app/src/main/AndroidManifest.xml` | Audit permissions | A |
| `lib/features/start/presentation/screens/question_stats_screen.dart` | Fix URL count display + add row tap + bottom sheet | B |
| All layout widgets (see #62 scope) | Replace hardcoded sizes | B |
| `lib/features/start/presentation/screens/start_screen.dart` | Add settings icon | C |
| `lib/features/settings/presentation/screens/app_settings_screen.dart` | Create new | C |
| `lib/features/start/presentation/screens/about_screen.dart` | Create new | C |
| `lib/core/router/` or `lib/app.dart` | Add `/about`, `/settings`, `/modes` routes | C, D |
| `lib/features/start/presentation/screens/mode_selection_screen.dart` | Create new | D |
| `lib/features/start/presentation/widgets/mode_card.dart` | Create new | D |

---

## Verification

```bash
# After each release group
flutter analyze --fatal-infos
flutter test --reporter expanded

# Manual test matrix for #62
# Run on: Android emulator 360dp (Pixel 6a), 412dp (Pixel 9), 600dp (tablet)
# Check: no overflow, no clipped text, all buttons tappable

# After #83 fix
# Play a game, open 2 articles, finish → check stats screen shows correct counts
# Play Endless game → check win rate / stats update appropriately
```

# Issue Analysis — Triaged Issues (excl. #82)

## Issues in scope

| # | Title | Type | Complexity |
|---|-------|------|------------|
| 54 | Long text wrapping on answer buttons | UI bug | XS |
| 55 | Wiki link in answer result popup | UI feature | S |
| 56 | Question bank: negative URL counts + content request popup | Bug + feature | M |
| 58 | Game mode selection redesign (home flow) | Major feature | XL |
| 59 | About page + tooltips + app settings | New screens | L |
| 62 | Flexible/responsive scaling (all screens) | Cross-cutting | L |
| 63 | App permissions audit and implementation | Platform + UI | S |
| 83 | Game stats inaccurate (win rate + articles = 0) | Bug | S |

---

## Issue detail notes

### #54 — Long text wrapping
- `answer_button.dart` already uses `Expanded` wrapping a `Text` with no `overflow` or `maxLines` constraint
- Bug is likely a fixed height constraint applied by the caller in `gameplay_screen.dart`
- Fix: remove/relax height constraints; ensure `Text` has `softWrap: true` (default)

### #55 — Wiki link in answer popup
- After answering, `GameStatus.answerRevealed` state is shown with a result overlay
- Need to find that overlay widget and add a "Read article" button that navigates to `/article` with the current question's wiki URL
- Does not affect gameplay flow, just the `answerRevealed` phase

### #56 — Question bank display bug + content request
- The question stats screen (`question_stats_screen.dart`) shows negative URL counts
- Need to trace how counts are calculated and fix the display logic
- Content request popup: add `GestureDetector` on list rows → bottom sheet form (sources count + questions count)

### #58 — Game mode selection redesign
- Replace `topic_picker_screen.dart` as the post-home navigation target
- Add a new `ModeSelectionScreen` with Standard card and Endless card
- Each card has a settings modal (difficulty, topics; Standard also has question count)
- Standard mode already exists; Endless already exists — this is a UX entry point, not new game logic
- **Depends on #59** having established settings persistence patterns

### #59 — About page + tooltips + app settings
- New `AboutScreen` accessible from home/settings icon
- First-visit coach mark system: use `SharedPreferences` to track which screens have been visited; show overlay on first visit
- `AppSettingsScreen` with "Disable tips" toggle (persisted)
- Settings icon on `StartScreen` needed
- **Establishes settings persistence pattern used by #58**

### #62 — Flexible scaling
- App designed for Pixel 9 (412dp wide); needs to work from Pixel 6 (360dp) to tablets (600dp+)
- Use `LayoutBuilder` / `MediaQuery` for responsive constraints
- Replace any hardcoded pixel dimensions with `% of screen` or `ScreenUtil`-style fractions
- Affects: `StartScreen`, `GameplayScreen`, `ResultsScreen`, `QuestionCard`, `AnswerButton`, `RoomHeader`
- Should be done before building new screens in #58 and #59 so new screens are responsive from birth

### #63 — App permissions
- Audit `AndroidManifest.xml` for declared permissions
- App uses: internet (WebView), possibly vibration (shake animation)
- Android 6+ requires runtime permission for dangerous permissions; internet is a normal permission (no runtime dialog needed)
- Check if any permissions are missing or over-declared; add rationale dialogs if needed

### #83 — Game stats inaccurate
- `results_screen.dart:43` → `articlesFound: gs.newArticleUrls.length`
- `newArticleUrls` is populated when user opens an article the app hasn't seen before; if all articles were previously opened they count as 0
- Win rate: `won: gs.status == GameStatus.complete` — in Endless mode the game ends via `GameStatus.gameOver` (lives run out) or is potentially never "won"; `totalWins` will never increment for Endless
- **Fix needed**: clarify what "win" means in Endless (possibly a high score milestone), and clarify articles tracking
- **UX fix**: label win rate as "Standard Mode Win Rate" if it's mode-scoped

---

## Key dependencies

```
#54 → none (standalone bug)
#83 → none (standalone bug)
#63 → none (audit + small fix)
#55 → none (contained to gameplay answer overlay)
#56 → none (contained to question bank screen)
#62 → none but SHOULD run before #59 and #58
#59 → #62 (build new screens responsively)
#58 → #59 (uses settings persistence) + #62 (responsive from start)
```

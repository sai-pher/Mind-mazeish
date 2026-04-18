# Mind Mazeish

[![CI — Analyze & Test](https://github.com/sai-pher/mind-mazeish/actions/workflows/ci.yml/badge.svg)](https://github.com/sai-pher/mind-mazeish/actions/workflows/ci.yml)
[![CD — Build & Publish APK](https://github.com/sai-pher/mind-mazeish/actions/workflows/cd.yml/badge.svg)](https://github.com/sai-pher/mind-mazeish/actions/workflows/cd.yml)
[![CD — Deploy Web](https://github.com/sai-pher/mind-mazeish/actions/workflows/cd-web.yml/badge.svg)](https://github.com/sai-pher/mind-mazeish/actions/workflows/cd-web.yml)

A medieval castle trivia game for Android and the web. Answer questions across 35 topic areas — from Ancient History to Coffee Brewing — all sourced from Wikipedia. Read the source articles in-app after each answer.

> **Alpha release** — you are one of our first testers. Expect rough edges, and please use the in-app feedback button to let us know what you find.

---

## Play in your browser

**[https://sai-pher.github.io/Mind-mazeish/](https://sai-pher.github.io/Mind-mazeish/)**

No install required — open the link in any modern browser and play immediately.

### Add to Home Screen on iOS (PWA)

You can install Mind Mazeish as a full-screen app on your iPhone or iPad:

1. Open the link above in **Safari** (must be Safari — Chrome and Firefox on iOS cannot install PWAs).
2. Tap the **Share** button (the box with an arrow pointing up) in the bottom toolbar.
3. Scroll down and tap **Add to Home Screen**.
4. Give it a name and tap **Add**.

The app icon will appear on your Home Screen and launch full-screen, just like a native app.

---

## Download & Install (Android)

1. Go to the [**Releases page**](https://github.com/sai-pher/Mind-mazeish/releases/latest) and download `app-release.apk`.
2. On your Android device, open **Settings → Apps** (or **Special app access**) and enable **Install unknown apps** for your file manager or browser.
3. Open the downloaded APK file and tap **Install**.
4. Once installed, open **Mind Mazeish** from your app drawer.

> The app is signed with a debug keystore for this alpha. You will see a security warning during install — this is expected.

### Updating to a newer build

1. Download the latest APK from the [Releases page](https://github.com/sai-pher/Mind-mazeish/releases/latest).
2. Install it over the existing app — your settings are preserved.

---

## What's in the app

| Feature | Details |
|---------|---------|
| **35 topics** | Literature, History, Science, Health, Food, Crafts, and more |
| **Topic picker** | Select exactly which topics you want to be quizzed on |
| **Question counts** | Choose 5, 10, or 20 questions per session |
| **Three difficulty levels** | Easy / Medium / Hard — mixed within each session |
| **Fun facts** | Every answer reveals a surprising fact from Wikipedia |
| **Wikipedia viewer** | Tap the article link after any question to read the full source |
| **Notebook** | Tracks articles you've discovered during play |

---

## Sending Feedback

Tap the **Feedback** button on the home screen at any time.

**General Feedback tab** — for bugs, feature ideas, UI suggestions, and anything else:
1. Pick a category (Bug, Feature Request, UI/UX, Improvement, Other)
2. Write a short title and description
3. Tap **Submit Feedback**

Your feedback is submitted directly as an issue on this GitHub repository so it can be tracked and prioritised.

**Content Request tab** — to suggest new trivia topics or ask for more questions on existing topics:
1. Choose **Suggest a new topic** or **Request more questions**
2. Fill in the details and submit

---

## Known Alpha Limitations

- Questions are bundled in the app — no internet needed to play (except to open Wikipedia articles)
- Some topics have fewer than 10 questions — more are being added
- The Android app requires sideloading (no Play Store listing yet)
- No account or progress sync between devices

### Web-specific limitations

- **Wikipedia articles open in a new tab** — your browser must allow pop-ups for this site. If tapping "Open Wikipedia article" does nothing, go to your browser's address bar, click the pop-up blocked icon, and choose **Always allow pop-ups from this site**.
- **Add to Home Screen requires Safari on iOS** — Chrome and Firefox on iOS cannot install PWAs.

---

## Developer Setup

```bash
# Prerequisites: Flutter 3.27.4 stable, Android SDK

git clone https://github.com/sai-pher/Mind-mazeish.git
cd Mind-mazeish

flutter pub get
flutter run          # on a connected device or emulator
```

### Running checks

```bash
export PATH="$PATH:/opt/flutter/bin"
git config --global --add safe.directory /opt/flutter
flutter analyze --fatal-infos
flutter test --reporter expanded
```

### Adding questions

Questions live in `assets/questions/topics/{topicId}.json`. Each file is a JSON array. See [`.claude/generate-questions.md`](.claude/generate-questions.md) for the full workflow and schema.

### Wiring up the feedback PAT

The feedback feature submits issues via a write-only GitHub PAT. The token is **never stored in source code** — it is injected at build time.

1. Generate a fine-grained PAT:
   - GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Repository: `sai-pher/Mind-mazeish` only
   - Permissions: **Issues → Read & Write** (nothing else)

2. Add it as a repository secret:
   - Repo → Settings → Secrets and variables → Actions → New repository secret
   - Name: `FEEDBACK_GITHUB_PAT`
   - Value: the token you just created

The CD workflow passes it to Flutter at build time via `--dart-define`. No source code changes needed.

---

## Architecture

| Layer | Technology |
|-------|------------|
| State management | Riverpod (`NotifierProvider`, `FutureProvider`) |
| Navigation | GoRouter |
| Questions | Per-topic JSON assets — no runtime API calls |
| Article viewer | `webview_flutter` (Wikipedia mobile) |
| Animations | `flutter_animate`, `lottie` |
| Fonts | Cinzel, Cinzel Decorative, Lora (Google Fonts) |

### Screens

| Route | Screen |
|-------|--------|
| `/` | Start — Quick Play, Choose Topics, Notebook, Feedback |
| `/topics` | Topic picker — 3-level hierarchy, question count selector |
| `/game` | Gameplay — question card, answer buttons, fun fact sheet |
| `/article` | Wikipedia viewer (WebView) |
| `/results` | Results — score, accuracy, star rating |
| `/notebook` | Discovered articles |
| `/feedback` | Feedback & Content Request (→ GitHub Issues) |

### Project structure

```
assets/
└── questions/topics/     ← one JSON file per topic (35 topics)
lib/
├── core/theme/           # AppColors, AppTheme
├── features/
│   ├── start/            # StartScreen, TopicPickerScreen
│   ├── gameplay/         # Question loading, game logic, providers
│   ├── article_viewer/   # WebView screen
│   ├── results/          # Results screen
│   ├── notebook/         # Article history
│   └── feedback/         # Feedback + content request → GitHub Issues
```

## CI / CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| **CI** | Push / PR | `flutter analyze --fatal-infos` + `flutter test` |
| **CD** | Push to `main` | Analyze → Test → Build APK → Publish to GitHub Releases |
| **CD Web** | Push to `main` | Analyze → Test → Build Flutter Web → Deploy to GitHub Pages |

# Mind Maze — Architecture Decisions Log

## Decision Log

### 2026-04-04 — State management: Riverpod
Chose flutter_riverpod over Bloc/Provider for cleaner async state and code generation support via riverpod_generator. Keeps providers close to features without boilerplate.

### 2026-04-04 — Question generation: Claude API + Wikipedia REST
Wikipedia provides grounded article summaries; Claude generates well-formed questions from them. This avoids hallucinated facts since all questions derive from the article text sent in the prompt.

### 2026-04-04 — Article viewer: webview_flutter
Opens Wikipedia mobile site in-app. Preserves the rabbit-hole feel without building a custom reader. Uses `https://en.m.wikipedia.org/wiki/{title}` for mobile-optimised layout.

### 2026-04-04 — Flutter project at repo root
Created Flutter project at the repository root (not in a subdirectory) to keep `PROGRESS.md`, `DECISIONS.md`, and `CLAUDE_CODE_PROMPT.md` co-located with the app source.

### 2026-04-04 — .env asset strategy
`flutter_dotenv` requires `.env` to be listed as a Flutter asset. The real `.env` is gitignored; `.env.example` is committed as a template. CI/CD must inject the `.env` file at build time. An empty `.env` is kept locally so `flutter run` doesn't crash on asset load.

### 2026-04-04 — Android minSdk 26, targetSdk 36
minSdk 26 (Android 8.0) as specified. targetSdk 36 (Android 16) for Pixel 9 target. INTERNET permission added to AndroidManifest.xml for Wikipedia and Claude API calls.

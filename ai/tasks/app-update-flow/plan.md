# Plan: Improve App Update Process

## Context
Issue #46 requests a full overhaul of the update UX. Currently, the in-app update dialog shows truncated plain-text notes, the download button opens a browser page rather than directly downloading the APK, and the check only runs on manual tap. Release notes are generated ad hoc from git log at build time with no repo-level source of truth. The goal is to make updates seamless for users and release communication consistent for contributors.

---

## Current vs Target State

| Area | Current | Target |
|------|---------|--------|
| Release notes in dialog | Truncated plain text (300 chars) | Full markdown, scrollable |
| Download button | Opens HTML release page in browser | Direct APK download via `browser_download_url` |
| Update check timing | Manual tap only | Auto-check on app open (silent if up to date) |
| Release notes source | Ad hoc git log in cd.yml | `release_notes.md` at repo root |
| PR enforcement | None | CI action fails if `release_notes.md` not modified |
| Pre-push quality gate | None | `.githooks/pre-push` runs analyze + test |
| Release notes drafting | Manual | `/release-notes` Claude skill |

---

## Affected Areas

### A — App: Service layer
- `UpdateInfo`: add `downloadUrl` (APK asset), remove 300-char truncation
- Parse `assets[].browser_download_url` from GitHub API response
- See: `proposal/01-service-and-ui.md`

### B — App: Update dialog UI
- Add `flutter_markdown: ^0.7.6` to `pubspec.yaml`
- Replace `Text` with scrollable `MarkdownBody` in update dialog
- Fix download button to use `downloadUrl` (direct APK)
- Extract `_showUpdateDialog()` helper
- See: `proposal/01-service-and-ui.md`

### C — App: Auto-check on open
- Call `_autoCheckUpdate()` from `_loadVersion()` in `initState`
- Show dialog only if update available; suppress "up to date" noise
- See: `proposal/01-service-and-ui.md`

### D — Release pipeline: `release_notes.md`
- Create `release_notes.md` at repo root with `## Unreleased` stub
- Modify `cd.yml` to extract `## Unreleased` section as release body
- Remove `workflow_dispatch.release_notes` input (obsolete)
- See: `proposal/02-release-pipeline.md`

### E — CI: Check release notes
- New `.github/workflows/check-release-notes.yml`
- Fails PR if `release_notes.md` not in the diff
- See: `proposal/02-release-pipeline.md`

### F — Hooks: Pre-push quality gate
- `.githooks/pre-push`: runs `flutter analyze` + `flutter test`
- Set `core.hooksPath = .githooks` (documented in CONTRIBUTING.md)
- Claude `PostToolUse` hook: reminds agent if `release_notes.md` not updated, fires on `Bash(git push:*)`, `Bash(gh pr:*)`, `Skill(commit-commands:commit-push-pr)` only
- See: `proposal/03-hooks-and-skill.md`

### G — Skill: `/release-notes`
- New `.claude/skills/release-notes/SKILL.md`
- Reads PR/branch diff, classifies commits into Features/Fixes/Content/Other
- **Skip logic**: compares existing `## Unreleased` bullets against significant changes; skips write if all covered
- Merges new bullets into existing content — never erases prior entries
- See: `proposal/03-hooks-and-skill.md`

### H — Docs: CONTRIBUTING.md + CLAUDE.md
- Add release notes requirement section to CONTRIBUTING.md
- Document `.githooks` setup in CONTRIBUTING.md
- Add `/release-notes` skill entry to CLAUDE.md
- **CLAUDE.md enforcement rule**: "Before creating or updating a PR, always run `skill: release-notes`" — skill is idempotent (safe to run multiple times)

---

## Order of Operations

1. Create `release_notes.md` at repo root (D)
2. Modify `cd.yml` to read from `release_notes.md` (D)
3. Create `.github/workflows/check-release-notes.yml` (E)
4. Update `CONTRIBUTING.md` — release notes section + githooks setup (H)
5. Update `CLAUDE.md` — add release-notes skill entry (H)
6. Add `flutter_markdown` to `pubspec.yaml` (B)
7. Update `UpdateService` — add `downloadUrl`, remove truncation (A)
8. Update `start_screen.dart` — markdown dialog, direct download, auto-check (B, C)
9. Create `.githooks/pre-push` (F)
10. Add Claude `PostToolUse` hook to `.claude/settings.json` (F)
11. Create `.claude/skills/release-notes/SKILL.md` (G)
12. Write widget tests for updated dialog behaviour
13. Run `flutter analyze --fatal-infos` + `flutter test`
14. Open PR `feat/issue-46-improve-app-update-process`

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `release_notes.md` | Create |
| `.github/workflows/check-release-notes.yml` | Create |
| `.github/workflows/cd.yml` | Modify — replace note generation |
| `lib/services/update_service.dart` | Modify — add downloadUrl, remove truncation |
| `lib/features/start/presentation/screens/start_screen.dart` | Modify — markdown dialog, auto-check |
| `pubspec.yaml` | Modify — add flutter_markdown |
| `.githooks/pre-push` | Create |
| `.claude/skills/release-notes/SKILL.md` | Create |
| `.claude/settings.json` | Modify — add PostToolUse hook |
| `CONTRIBUTING.md` | Modify — add release notes + githooks sections |
| `CLAUDE.md` | Modify — add release-notes skill entry |
| `test/features/start/update_dialog_test.dart` | Create — widget tests |

---

## Verification

```bash
# Flutter checks
export PATH="$PATH:/opt/flutter/bin"
flutter pub get
flutter analyze --fatal-infos
flutter test --reporter expanded

# CI check locally — simulate PR diff containing release_notes.md
git diff --name-only HEAD~1 HEAD | grep release_notes.md

# Confirm release_notes.md has ## Unreleased section
grep "## Unreleased" release_notes.md

# Confirm githook is executable
ls -la .githooks/pre-push

# Confirm skill file exists
ls .claude/skills/release-notes/SKILL.md
```

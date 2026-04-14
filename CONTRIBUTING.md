# Contributing to Mind Mazeish

## Branch naming

| Type | Pattern | Example |
|------|---------|---------|
| Bug fix | `fix/issue-{N}-{slug}` | `fix/issue-12-crash-on-results` |
| Feature / UI / Improvement | `feat/issue-{N}-{slug}` | `feat/issue-7-dark-mode-toggle` |
| Content (questions/topics) | `content/issue-{N}-{slug}` | `content/issue-3-add-jazz-topic` |
| Chore / infra | `chore/{slug}` | `chore/upgrade-flutter-3-41` |

Slugs: lowercase, hyphens, max 5 words. Always reference the issue number if one exists.

## Commit message format

```
{type}: {short description} (#{issue})
```

Types: `fix`, `feat`, `improvement`, `content`, `chore`, `ci`, `docs`, `test`

Examples:
- `fix: resolve crash on results screen (#12)`
- `content: add 30 jazz music questions (#3)`
- `chore: upgrade Flutter to 3.41.6`

One subject line (≤72 chars). No body unless change is non-obvious.

## Release notes

Every PR to `main` must include an update to `release_notes.md`.

- Add your changes under `## Unreleased` using the Features / Fixes / Content / Other sections.
- Focus on **user-facing** changes. Summarise internal/CI changes briefly under "Other".
- Run `/release-notes` (Claude skill) to auto-generate a draft from the current branch diff.
- The CI `Check Release Notes` action will fail if `release_notes.md` is not modified in the PR.

## Pull requests

- Title mirrors the commit message format
- Body must include `Closes #{N}` if resolving an issue
- All PRs require green CI (analyze + test + check-release-notes) before merge
- Scope: one issue per PR; no bundled unrelated changes
- Target branch: `main`

## Code standards

- **State management**: Riverpod (`NotifierProvider`, `AsyncNotifierProvider`) — no setState outside local widget state
- **Navigation**: GoRouter — no `Navigator.push` directly
- **Colours**: `AppColors` constants only — no inline hex values
- **No new packages** without discussion — keep pub.dev dependency count low
- `flutter analyze --fatal-infos` must pass (zero infos, warnings, errors)

## Testing

See `TESTING.md` for coverage requirements. All new features require widget tests. All bug fixes require a regression test.

## Git hooks

This repo ships hooks in `.githooks/`. Enable them once after cloning:

```bash
git config core.hooksPath .githooks
```

The `pre-push` hook runs `flutter analyze --fatal-infos` and `flutter test` before every push. Fix any failures before retrying.

## AI agent contributions

Agents follow the same standards. Agent-authored PRs include the structured resolution comment on the linked issue before the PR is opened. See `.claude/skills/` for available agent skills.

Before creating or updating a PR, agents always run the `/release-notes` skill to sync `release_notes.md` with the branch changes.

## Questions

Open a GitHub issue with label `feedback` or `enhancement`.

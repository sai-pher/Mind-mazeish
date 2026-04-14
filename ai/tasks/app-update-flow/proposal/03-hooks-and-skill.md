# Proposal 03: Hooks & Release-Notes Skill

## Goal
Add a pre-push git hook that runs tests before code reaches remote, and a `/release-notes` Claude skill that drafts the `release_notes.md` update from the current PR/branch context.

---

## 1. Pre-push git hook

File: `.githooks/pre-push`

```bash
#!/usr/bin/env bash
set -e

echo "🔍 Running flutter analyze..."
export PATH="$PATH:/opt/flutter/bin"
flutter analyze --fatal-infos

echo "🧪 Running flutter test..."
flutter test --reporter compact

echo "✅ Pre-push checks passed."
```

Enable with:
```bash
git config core.hooksPath .githooks
```

This should be documented in CONTRIBUTING.md so contributors run the config command on clone. The `.githooks/` directory is checked into the repo (unlike `.git/hooks/`).

**Note:** This replaces running tests only in CI — catches failures locally before push.

---

## 2. Claude hook (settings.json)

For AI-driven workflows, add a `PostToolUse` hook that reminds the agent to update release notes when it commits to a non-main branch and `release_notes.md` wasn't in the staged files.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash(git push:*)",
        "hooks": [
          {
            "type": "command",
            "command": "git diff origin/main...HEAD --name-only 2>/dev/null | grep -q release_notes.md || echo 'REMINDER: release_notes.md not updated — run /release-notes before this push reaches a PR'"
          }
        ]
      },
      {
        "matcher": "Bash(gh pr:*)",
        "hooks": [
          {
            "type": "command",
            "command": "git diff origin/main...HEAD --name-only 2>/dev/null | grep -q release_notes.md || echo 'REMINDER: release_notes.md not updated — run /release-notes to draft the notes for this PR'"
          }
        ]
      },
      {
        "matcher": "Skill(commit-commands:commit-push-pr)",
        "hooks": [
          {
            "type": "command",
            "command": "git diff origin/main...HEAD --name-only 2>/dev/null | grep -q release_notes.md || echo 'REMINDER: release_notes.md not updated — run /release-notes before opening the PR'"
          }
        ]
      }
    ]
  }
}
```

Triggers only on `git push`, `gh pr *`, or the `commit-push-pr` skill — not on every commit. Outputs a reminder into the Claude context (non-blocking).

---

## 3. `/release-notes` Claude skill

File: `.claude/skills/release-notes/SKILL.md`

### Purpose
Ensure `release_notes.md` is in sync with the current branch before a PR is created or updated. Skips writing if the notes already cover all significant changes.

### Inputs gathered automatically
1. Current branch name and PR number (if open): `gh pr view --json number,title,body,baseRefName`
2. Diff summary: `git diff origin/{base}...HEAD --stat` + `git log origin/{base}...HEAD --oneline`
3. Linked issues: extract `#N` refs from commits and PR body, then `gh issue view {N} --repo sai-pher/Mind-mazeish --json title,labels`
4. Current `release_notes.md` `## Unreleased` section

### Skip logic (run before writing)
Before updating the file, compare the existing `## Unreleased` content against the set of significant changes on the branch:

- A change is **significant** if it touches user-facing behaviour: Features, Fixes, or Content (new questions/topics).
- CI config, dependency bumps, internal refactors, and doc-only changes are **not significant** on their own.
- If every significant change already has a corresponding bullet in `## Unreleased`, print `"release_notes.md already covers all changes — skipping update"` and stop.
- If there are uncovered significant changes, proceed to update.

This prevents redundant rewrites when the skill is invoked multiple times in a session.

### Output structure
```markdown
## Unreleased

### Features
- {user-facing new capabilities}

### Fixes
- {bugs resolved, referencing #issue}

### Content
- {new topics or questions added}

### Other
- {internal / CI / dependency changes — one-liner summaries}
```

### Rules
- Only user-facing items in Features/Fixes/Content — no internal refactors
- Internal changes go in Other, kept to one line each
- Each bullet references the issue/PR number where applicable: `(#N)`
- Merge with existing content — never erase bullets already present
- After writing, print a short summary of what was added

### Workflow
```
1. Fetch PR info (if PR open) + git log + linked issues
2. Read current ## Unreleased section from release_notes.md
3. Identify significant changes not yet covered by existing bullets
4. If none: print skip message and stop
5. Classify uncovered changes into the four buckets
6. Merge new bullets into ## Unreleased (append, don't overwrite)
7. Write updated block to release_notes.md
8. Print: "release_notes.md updated — N items added"
```

---

## 4. CLAUDE.md update

Add to the "Available skills" section:

```markdown
### Release workflow
- `release-notes` — sync `## Unreleased` in `release_notes.md` with current branch/PR changes; skips if notes are already up to date
  - Invoke: `skill: "release-notes"`
  - **Required** before creating or updating a PR
```

Add an **enforcement rule** in the PR / contribution section of CLAUDE.md:

```markdown
## Release notes (required on every PR)

Before creating or updating a PR, always run:

```
skill: "release-notes"
```

The skill checks whether `release_notes.md` is already in sync with the branch and skips writing if so — it is safe to run multiple times. If it updates the file, stage and commit the change before opening/updating the PR.

The CI `Check Release Notes` action will fail the PR if `release_notes.md` was not modified anywhere in the branch diff.

---

## Files to create / modify
| File | Action |
|------|--------|
| `.githooks/pre-push` | Create — runs analyze + test before push |
| `.githooks/README.md` | Create — one-liner setup instruction |
| `.claude/skills/release-notes/SKILL.md` | Create — new `/release-notes` skill |
| `.claude/settings.json` | Modify — add PostToolUse commit reminder hook |
| `CONTRIBUTING.md` | Modify — document `.githooks` setup + release-notes skill |
| `CLAUDE.md` | Modify — add release-notes skill entry |

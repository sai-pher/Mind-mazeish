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
Generate or update the `## Unreleased` section of `release_notes.md` from the current branch's context.

### Inputs gathered automatically
1. Current branch name and PR number (if open): `gh pr view --json number,title,body,baseRefName`
2. Diff summary: `git diff origin/{base}...HEAD --stat` + `git log origin/{base}...HEAD --oneline`
3. Linked issues: extract `#N` refs from commits and PR body, then `gh issue view {N} --repo sai-pher/Mind-mazeish --json title,labels`
4. Current `release_notes.md` `## Unreleased` section

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
- If the section already has content, merge rather than overwrite
- After writing, print a short summary of what was added/changed

### Workflow
```
1. Fetch PR info (if PR open) + git log
2. Read current release_notes.md
3. Classify each commit/issue into the four buckets
4. Draft Unreleased section
5. Write to release_notes.md (edit ## Unreleased block only)
6. Print confirmation: "release_notes.md updated — N items added"
```

---

## 4. CLAUDE.md update

Add to the "Available skills" section:

```markdown
### Release workflow
- `release-notes` — draft or update `## Unreleased` in `release_notes.md` from current branch/PR context
  - Invoke: `skill: "release-notes"`
```

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

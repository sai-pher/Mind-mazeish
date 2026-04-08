---
name: fix-bug
description: Apply a minimal fix for a confirmed bug on sai-pher/Mind-mazeish, ensure tests pass, and open a PR. Use after investigate-issue has identified root cause.
metadata:
  author: ariwoode
  version: "1.0"
---

# fix-bug

Applies a minimal bug fix, adds a regression test, and opens a PR.

## Inputs (from investigate-issue)

`issueNumber`, `rootCause`, `affectedFiles[]`, `branchName` (e.g. `fix/issue-12-crash-on-results`)

## Step 1 — Create branch

```bash
git checkout -b {branchName}
```

## Step 2 — Apply fix

- Minimal change only — no unrelated refactors
- Follow existing patterns in `lib/`
- Use `AppColors` constants for any colour changes
- State: Riverpod only; navigation: GoRouter only

## Step 3 — Add regression test

In `test/features/{feature}/` mirroring the source path.

Test must **fail** before the fix and **pass** after. Name: `'{scenario} {expected outcome}'`.

## Step 4 — Quality gates

```bash
export PATH="$PATH:/opt/flutter/bin"
flutter analyze --fatal-infos
flutter test --reporter expanded
```

Both must exit 0 with no new failures before proceeding.

## Step 5 — Commit and PR

```bash
git add {changed files}
git commit -m "fix: resolve #{issueNumber} — {short description}"

gh pr create \
  --title "fix: {title} (#{issueNumber})" \
  --body "$(cat <<'EOF'
Closes #{issueNumber}

{description of what was fixed and how}

## Test plan
- [ ] `flutter analyze --fatal-infos` passes
- [ ] `flutter test` passes with regression test
- [ ] Manual: {1–3 steps to verify the fix}
EOF
)"
```

## Step 6 — Invoke resolve-issue

Pass the PR URL to `resolve-issue`.

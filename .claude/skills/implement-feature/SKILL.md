---
name: implement-feature
description: Implement a scoped feature, UI/UX change, or improvement on sai-pher/Mind-mazeish and open a PR. Use after triage-issue for Feature Request, UI/UX, or Improvement issues.
metadata:
  author: ariwoode
  version: "1.0"
---

# implement-feature

Implements a scoped feature or improvement and opens a PR.

## Inputs (from triage-issue)

`issueNumber`, `type`, `slug`, `scope`

## Step 1 — Post intent comment before writing any code

```bash
gh issue comment {N} --repo sai-pher/Mind-mazeish --body "$(cat <<'EOF'
## 📋 Implementation Plan

**I will implement:**
{Bullet list of exact changes}

**I will NOT change:**
{Anything explicitly out of scope — helps avoid scope creep}

**Branch:** `{branchName}`

Proceeding unless there are objections within the next review cycle.

---
*Agent: implement-feature | {ISO date}*
EOF
)"
```

## Step 2 — Create branch

```bash
# Feature / UI / UX
git checkout -b feat/issue-{N}-{slug}

# Improvement
git checkout -b improvement/issue-{N}-{slug}
```

## Step 3 — Implement

- Minimal change scoped to the request
- Follow existing patterns in `lib/`
- **Colours**: `AppColors` constants only — no inline hex values
- **State management**: Riverpod only
- **Navigation**: GoRouter only
- **No new packages** without explicit approval

## Step 4 — Quality gates

```bash
export PATH="$PATH:/opt/flutter/bin"
flutter analyze --fatal-infos
flutter test --reporter expanded
```

Both must exit 0 before proceeding.

## Step 5 — Commit and PR

```bash
git add {changed files}
git commit -m "feat: resolve #{N} — {short description}"

gh pr create \
  --title "feat: {title} (#{N})" \
  --body "$(cat <<'EOF'
Closes #{N}

{description of what was implemented}

## Test plan
- [ ] `flutter analyze --fatal-infos` passes
- [ ] `flutter test` passes
- [ ] Manual: {1–3 steps to verify the feature}
EOF
)"
```

## Step 6 — Invoke resolve-issue

Pass the PR URL to `resolve-issue`.

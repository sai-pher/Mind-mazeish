---
name: investigate-issue
description: Deeply investigate a bug or ambiguous issue on sai-pher/Mind-mazeish. Traces the execution path, identifies root cause, and posts an investigation comment. Use after triage-issue when type is Bug Report or Other.
metadata:
  author: ariwoode
  version: "1.0"
---

# investigate-issue

Identifies root cause of a bug or ambiguous issue and posts an investigation comment.

## Inputs (from triage-issue)

`issueNumber`, `type`, `slug`

## Step 1 — Re-read issue body and existing comments

Use the cached JSON from `triage-issue`. Do not re-fetch unless comments were added after triage.

## Step 2 — Search codebase

Targeted reads only — do not read unrelated files.

```bash
# Find affected widget / screen
grep -r "{keyword from issue}" lib/ --include="*.dart" -l

# Trace execution path
grep -r "GoRoute" lib/ --include="*.dart"

# For UI issues: read theme and affected widget
# lib/core/theme/app_theme.dart
# lib/features/{feature}/presentation/screens/{screen}.dart
```

## Step 3 — Form hypothesis

Document: what breaks, where (file:line), why.

For bugs: identify the state transition or rendering path that fails.
For UI issues: compare desired vs actual layout/colour from `AppColors`/`AppTheme`.

## Step 4 — Post investigation comment

```bash
gh issue comment {N} --repo sai-pher/Mind-mazeish --body "$(cat <<'EOF'
## 🔍 Investigation

**Root cause:** {one-sentence summary}

**Affected code:**
{file path(s) and brief description — e.g. `lib/features/gameplay/presentation/screens/gameplay_screen.dart:142` — state not reset on navigation}

**Reproduction path:**
{Numbered steps if relevant}

**Proposed fix:**
{1–3 bullet points describing the minimal change}

**Estimated risk:** {Low | Medium | High} — {reason}

---
*Agent: investigate-issue | {ISO date}*
EOF
)"
```

## Output

Return `{ issueNumber, rootCause, affectedFiles[], proposedFix, branchName }` for `fix-bug`.

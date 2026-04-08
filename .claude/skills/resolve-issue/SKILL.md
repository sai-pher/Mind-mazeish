---
name: resolve-issue
description: Post a structured resolution summary comment on a sai-pher/Mind-mazeish GitHub issue and mark it resolved or awaiting-merge. Use as the final step after fix-bug or implement-feature opens a PR.
metadata:
  author: ariwoode
  version: "1.0"
---

# resolve-issue

Posts a resolution comment and updates issue labels. Final step in all resolution workflows.

## Inputs

`issueNumber`, `prUrl`, `summary`, `testResults` (N tests, 0 failures)

## Step 1 — Post resolution comment

```bash
gh issue comment {N} --repo sai-pher/Mind-mazeish --body "$(cat <<'EOF'
## ✅ Resolved

**PR:** {prUrl}
**Branch:** `{branchName}`

**What was changed:**
{Bullet list matching the implementation plan — or root cause fix description}

**Tests:**
- `flutter analyze --fatal-infos` ✅
- `flutter test` ✅ ({N} tests, 0 failures)

**Verification steps for reviewer:**
{1–3 steps to manually verify the fix}

---
*Agent: resolve-issue | {ISO date}*
EOF
)"
```

## Step 2 — Update labels

```bash
# Add resolved, remove triaged
gh issue edit {N} --repo sai-pher/Mind-mazeish \
  --add-label "resolved" \
  --remove-label "triaged"
```

## Step 3 — Close or mark awaiting-merge

```bash
# If PR is already merged:
gh issue close {N} --repo sai-pher/Mind-mazeish

# If PR is open (pending review):
gh issue edit {N} --repo sai-pher/Mind-mazeish --add-label "awaiting-merge"
```

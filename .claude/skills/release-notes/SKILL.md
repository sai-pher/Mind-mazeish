# release-notes

Syncs the `## Unreleased` section of `release_notes.md` with the current branch's changes. Safe to run multiple times — skips writing if the notes already cover all significant changes.

**Required before creating or updating any PR.**

---

## Step 1 — Gather context

Run all three in parallel:

```bash
# PR info (ok to fail if no PR open yet)
gh pr view --repo sai-pher/Mind-mazeish \
  --json number,title,body,baseRefName 2>/dev/null || echo '{}'

# Commit log vs base branch
git log origin/main...HEAD --oneline --no-decorate

# Files changed
git diff origin/main...HEAD --name-only
```

Also read the current `## Unreleased` block from `release_notes.md`.

---

## Step 2 — Identify significant changes

A change is **significant** if it touches user-facing behaviour:
- New or changed features visible to the player
- Bug fixes that affect gameplay or UI
- New topics or questions added to the game

The following are **not significant** on their own:
- CI/CD config changes
- Dependency version bumps
- Internal refactors, test-only changes, doc-only changes

Extract linked issue numbers from commit messages and PR body (`#N` pattern), then fetch titles/labels for context:

```bash
gh issue view {N} --repo sai-pher/Mind-mazeish --json title,labels 2>/dev/null
```

---

## Step 3 — Skip check

Compare the set of significant changes against the existing `## Unreleased` bullets:

- For each significant change, check whether a matching bullet already exists (by issue number or key phrase).
- If **all** significant changes are covered → print:
  ```
  release_notes.md already covers all changes — skipping update
  ```
  Stop here.
- If **any** significant changes are not covered → proceed to Step 4.

---

## Step 4 — Classify uncovered changes

Sort uncovered items into four buckets:

| Section | Include |
|---------|---------|
| **Features** | New user-facing capabilities |
| **Fixes** | Bugs resolved; include `(#N)` |
| **Content** | New topics or question sets added |
| **Other** | CI, deps, internal changes — one-liner each |

---

## Step 5 — Write `## Unreleased`

Edit `release_notes.md` — update the `## Unreleased` block only:
- Append new bullets to each section; do **not** remove existing bullets.
- Each bullet referencing an issue uses format: `- Description (#N)`
- Keep user-facing language in Features/Fixes/Content; keep Other terse.

---

## Step 6 — Confirm

Print:
```
release_notes.md updated — N item(s) added
  Features: X  Fixes: Y  Content: Z  Other: W
```

If the file was updated, remind the agent to stage and commit the change:
```
Stage and commit before opening/updating the PR:
  git add release_notes.md
  git commit -m "docs: update release notes for <branch slug>"
```

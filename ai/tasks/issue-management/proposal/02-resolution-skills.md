# Proposal: Issue Resolution Skills

## Skill Set

Four skills cover the full resolution lifecycle. Communication skills are a separate set (see `03-communication-skills.md`).

---

### `triage-issue`

**Purpose**: Read a GitHub issue, classify it, and post an initial understanding comment.

**Location**: `.claude/skills/triage-issue/SKILL.md`

**Steps**:
1. `gh issue view {N} --repo sai-pher/Mind-mazeish --json number,title,body,labels,comments`
2. Determine type from labels + body (see `01-issue-workflows.md`)
3. If type ambiguous: relabel `needs-info`, post clarifying comment (template: `communication-skills.md#needs-info`)
4. If type clear: add label `triaged`, post understanding comment (template: `communication-skills.md#understanding`)
5. Output: `{ type, issueNumber, slug, branchName }` for chaining

**Tools**: `gh` CLI, label reference table from `01-issue-workflows.md`

**Token efficiency**: Read issue JSON once; do not re-fetch in downstream skills — pass `issueNumber` as argument.

---

### `investigate-issue`

**Purpose**: Deeply understand a bug or ambiguous issue; identify root cause; post investigation plan.

**Location**: `.claude/skills/investigate-issue/SKILL.md`

**When to use**: Bug reports; "Other" issues after triage; any issue where root cause is not obvious.

**Steps**:
1. Receive: `issueNumber`, `type`, `slug` from `triage-issue`
2. Re-read issue body + any existing comments
3. Search codebase for relevant code:
   - For bugs: find affected screen/widget/provider; trace execution path
   - For UI issues: read `app_theme.dart`, affected screen, widget tree
4. Form hypothesis: what breaks, where, why
5. Post investigation comment (template: `communication-skills.md#investigation`)
6. Output: `{ rootCause, affectedFiles[], proposedFix }` for chaining

**Code tools**:
```bash
# Find affected widget/screen
grep -r "{keyword}" lib/ --include="*.dart" -l

# Check routes
grep -r "GoRoute" lib/ --include="*.dart"
```

**Token efficiency**: Use `Grep` for targeted searches; do not read files unrelated to the root cause.

---

### `fix-bug`

**Purpose**: Apply a minimal fix for a confirmed bug, ensure tests pass, open a PR.

**Location**: `.claude/skills/fix-bug/SKILL.md`

**Steps**:
1. Receive: `issueNumber`, `rootCause`, `affectedFiles[]`, `branchName` from `investigate-issue`
2. Create branch: `git checkout -b fix/issue-{N}-{slug}`
3. Apply fix (minimal — no unrelated changes)
4. Add/update regression test in `test/` mirroring the bug scenario
5. Quality gates:
   ```bash
   export PATH="$PATH:/opt/flutter/bin"
   flutter analyze --fatal-infos
   flutter test --reporter expanded
   ```
6. If gates pass: commit with message `fix: resolve #{N} — {short description}`
7. Open PR:
   ```bash
   gh pr create --title "fix: {title}" --body "Closes #{N}\n\n{description}"
   ```
8. Invoke `resolve-issue` with PR URL

**Quality gate exit condition**: Both commands exit 0 with no new test failures.

---

### `implement-feature`

**Purpose**: Implement a scoped feature, improvement, or UI/UX change; open a PR.

**Location**: `.claude/skills/implement-feature/SKILL.md`

**Steps**:
1. Receive: `issueNumber`, `type`, `slug`, `scope` from `triage-issue` or user
2. Confirm scope: post intent comment before coding (template: `communication-skills.md#intent`)
3. Create branch: `feat/issue-{N}-{slug}` or `improvement/issue-{N}-{slug}`
4. Implement minimal change; follow existing patterns in `lib/`
5. Quality gates:
   ```bash
   flutter analyze --fatal-infos
   flutter test --reporter expanded
   ```
6. Commit: `feat: resolve #{N} — {short description}` or `improvement: ...`
7. Open PR: `gh pr create --title "..." --body "Closes #{N}\n\n..."`
8. Invoke `resolve-issue` with PR URL

**Constraints**:
- Follow `AppColors`/`AppTheme` for all UI changes
- State management: Riverpod only
- Navigation: GoRouter only
- No new packages without explicit approval

---

### `resolve-issue`

**Purpose**: Post a structured resolution summary comment and close the issue (or mark awaiting merge).

**Location**: `.claude/skills/resolve-issue/SKILL.md`

**Steps**:
1. Receive: `issueNumber`, `prUrl`, `summary`
2. Post resolution comment (template: `communication-skills.md#resolution`)
3. Add label `resolved` (remove `triaged` if present)
4. If PR is merged: `gh issue close {N} --repo sai-pher/Mind-mazeish`
5. If PR pending review: label `awaiting-merge`, do not close yet

---

## Skill Chaining

```
triage-issue
  └─► investigate-issue (bugs/other)
        └─► fix-bug
              └─► resolve-issue
  └─► implement-feature (features/ui-ux/improvements)
        └─► resolve-issue
  └─► add-topic (content: new topic)
        └─► resolve-issue
  └─► generate-questions (content: more questions)
        └─► resolve-issue
```

Each skill accepts the previous skill's outputs as arguments. This allows manual invocation of any step without re-running prior steps.

---

## Required GitHub Labels

Ensure these labels exist on the repo before deploying skills:

| Label | Colour | Purpose |
|-------|--------|---------|
| `triaged` | `#0075ca` | Agent has classified the issue |
| `needs-info` | `#e4e669` | Clarification needed |
| `resolved` | `#0e8a16` | Fix merged or in active PR |
| `awaiting-merge` | `#d93f0b` | PR open, not yet merged |

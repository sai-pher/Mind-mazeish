# Proposal: Agent Communication Skills

## Overview

All agent comments on GitHub issues follow structured templates to:
- Make agent intent transparent to the maintainer
- Provide a consistent audit trail
- Avoid redundant re-reads by downstream skills

Comments are posted with `gh issue comment {N} --repo sai-pher/Mind-mazeish --body "$(cat <<'EOF' ... EOF)"`.

---

## Comment Templates

### `understanding` — Initial triage

Posted by `triage-issue` immediately after classification.

```markdown
## 🤖 Agent Understanding

**Issue type:** {Bug Report | Feature Request | UI/UX | Improvement | Content Request | Other}
**Classified from:** {label list + key phrase from body}

**What I understand:**
{1–3 bullet points describing what the user reported}

**Scope:**
{What is in scope for this issue}

**Out of scope:**
{Anything explicitly not being addressed — or "Nothing excluded"}

**Next step:** {Investigating root cause | Planning implementation | Routing to generate-questions | etc.}

---
*Agent: {skill name} | {ISO date}*
```

---

### `needs-info` — Clarification needed

Posted when issue is ambiguous or insufficient detail.

```markdown
## 🤖 Needs Clarification

Thank you for the feedback! I need a bit more information before I can action this:

{Specific question(s) — numbered list}

I'll pick this up once the above is answered.

---
*Agent: triage-issue | {ISO date}*
```

---

### `investigation` — Root cause analysis

Posted by `investigate-issue` after code tracing.

```markdown
## 🔍 Investigation

**Root cause:** {One-sentence summary}

**Affected code:**
{File path(s) and brief description — e.g. `lib/features/gameplay/presentation/screens/gameplay_screen.dart:142` — state not reset on navigation}

**Reproduction path:**
{Numbered steps if relevant}

**Proposed fix:**
{1–3 bullet points describing the minimal change}

**Estimated risk:** {Low | Medium | High} — {reason}

---
*Agent: investigate-issue | {ISO date}*
```

---

### `intent` — Pre-implementation scope confirmation

Posted by `implement-feature` before writing any code.

```markdown
## 📋 Implementation Plan

**I will implement:**
{Bullet list of exact changes}

**I will NOT change:**
{Anything explicitly out of scope — helps avoid scope creep}

**Branch:** `{branchName}`

Proceeding unless there are objections within the next review cycle.

---
*Agent: implement-feature | {ISO date}*
```

---

### `resolution` — PR summary

Posted by `resolve-issue` after PR is opened.

```markdown
## ✅ Resolved

**PR:** {PR URL}
**Branch:** `{branchName}`

**What was changed:**
{Bullet list matching the implementation plan — or root cause fix description}

**Tests:**
- `flutter analyze --fatal-infos` ✅
- `flutter test` ✅ ({N} tests, {0} failures)

**Verification steps for reviewer:**
{1–3 steps to manually verify the fix}

---
*Agent: resolve-issue | {ISO date}*
```

---

## Posting Commands

```bash
# Post a comment
gh issue comment {N} --repo sai-pher/Mind-mazeish --body "$(cat <<'EOF'
{comment body}
EOF
)"

# Add a label
gh issue edit {N} --repo sai-pher/Mind-mazeish --add-label "triaged"

# Remove a label
gh issue edit {N} --repo sai-pher/Mind-mazeish --remove-label "needs-info"

# Close an issue
gh issue close {N} --repo sai-pher/Mind-mazeish
```

---

## Token Efficiency Rules

1. Fetch issue JSON once with `--json number,title,body,labels,comments` — cache fields in variables
2. Post comments via heredoc — never return large comment text to main context
3. Do not re-fetch issue after posting a comment — assume success on exit 0
4. Sub-agents write comments directly — main agent only coordinates

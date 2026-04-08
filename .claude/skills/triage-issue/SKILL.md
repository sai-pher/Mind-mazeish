---
name: triage-issue
description: Read a GitHub issue on sai-pher/Mind-mazeish, classify it by type, and post an initial understanding comment. Use when starting work on any inbound feedback issue.
metadata:
  author: ariwoode
  version: "1.0"
---

# triage-issue

Classifies a GitHub issue and posts an initial understanding comment. Outputs `{ type, issueNumber, slug, branchName }` for downstream skills.

## Step 1 — Fetch issue

```bash
gh issue view {N} --repo sai-pher/Mind-mazeish \
  --json number,title,body,labels,comments
```

Cache all fields in variables. Do not re-fetch downstream.

## Step 2 — Classify

| Labels present | Type |
|----------------|------|
| `bug` | Bug Report |
| `enhancement` | Feature Request |
| `ui-ux` | UI / UX |
| `improvement` | Improvement |
| `content-request` | Content Request |
| `feedback` (no other type label) | Other / Ambiguous |

If type is ambiguous, go to Step 3b.

Derive slug from title: lowercase, spaces→hyphens, max 5 words.
Branch name: `fix/issue-{N}-{slug}` (bug), `feat/issue-{N}-{slug}` (feature/ui/improvement), `content/issue-{N}-{slug}` (content).

## Step 3a — Clear type: post understanding comment + label triaged

```bash
gh issue comment {N} --repo sai-pher/Mind-mazeish --body "$(cat <<'EOF'
## 🤖 Agent Understanding

**Issue type:** {type}
**Classified from:** {label list + key phrase from body}

**What I understand:**
{1–3 bullet points describing what the user reported}

**Scope:**
{What is in scope for this issue}

**Out of scope:**
{Anything explicitly not being addressed — or "Nothing excluded"}

**Next step:** {next action}

---
*Agent: triage-issue | {ISO date}*
EOF
)"

gh issue edit {N} --repo sai-pher/Mind-mazeish --add-label "triaged"
```

## Step 3b — Ambiguous: post needs-info comment + label needs-info

```bash
gh issue comment {N} --repo sai-pher/Mind-mazeish --body "$(cat <<'EOF'
## 🤖 Needs Clarification

Thank you for the feedback! I need a bit more information before I can action this:

{Specific numbered questions}

I'll pick this up once the above is answered.

---
*Agent: triage-issue | {ISO date}*
EOF
)"

gh issue edit {N} --repo sai-pher/Mind-mazeish --add-label "needs-info"
```

## Output

Return `{ type, issueNumber, slug, branchName }` for the next skill in the chain.

## Skill chaining

```
triage-issue
  └─► investigate-issue  (Bug Report, Other)
  └─► implement-feature  (Feature Request, UI/UX, Improvement)
  └─► add-topic          (Content Request — new topic)
  └─► generate-questions (Content Request — more questions)
```

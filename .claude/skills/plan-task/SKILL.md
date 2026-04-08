---
name: plan-task
description: Research and plan a new initiative, creating a structured ai/tasks/{feature-area}/plan.md. Use when starting any new multi-step feature or tooling initiative.
metadata:
  author: ariwoode
  version: "1.0"
---

# plan-task

Creates or updates a plan in `ai/tasks/{feature-area}/` following the standard structure from `ai/tasks/issue-management/proposal/05-ai-task-docs.md`.

## Step 1 — Determine slug

Derive `{feature-area}` as kebab-case noun phrase from the user's description.

## Step 2 — Check for existing plan

```bash
ls ai/tasks/{feature-area}/ 2>/dev/null
```

If `plan.md` exists, read it before proceeding — rewrite, don't append.

## Step 3 — Research

Identify what information is needed:
- Codebase reads (Grep/Read as needed)
- GitHub issues (`gh issue list --repo sai-pher/Mind-mazeish --label ...`)
- External docs (use `context7` MCP for library docs)

Write non-trivial findings to `ai/tasks/{feature-area}/research/{topic}.md` rather than holding them in context.

## Step 4 — Write proposals

One file per distinct concern: `ai/tasks/{feature-area}/proposal/NN-{topic}.md`

Keep each proposal ≤ 500 lines. Split if longer.

## Step 5 — Write plan.md

Follow this template exactly:

```markdown
# Plan: {Title}

## Context
{Why this work exists. 2–5 sentences.}

---

## {Section}
{Tables / bullet lists preferred over prose}

---

## Order of Operations
{Numbered list in execution order}

---

## Files to Create / Modify
| File | Action |
|------|--------|

---

## Verification
{Commands to confirm the work is complete}
```

## Step 6 — Commit

```bash
git add ai/tasks/{feature-area}/
git commit -m "docs: add ai task plan for {feature-area}"
```

## Token efficiency

- Write research to files — do not hold large blobs in context
- Proposals are written sequentially
- `plan.md` is written last, after all proposals exist

## Discovery (for agents entering a new conversation)

```bash
find ai/tasks -name "plan.md" | xargs ls -t
```

Read the most relevant `plan.md` to understand current priorities.

---
name: audit-questions
description: Run a full health audit of all trivia questions — difficulty spread, thin topics, missing sources, validation errors. Use before adding questions or when assessing the question bank.
metadata:
  author: ariwoode
  version: "1.0"
---

# audit-questions

Audits the question bank and produces a prioritised action plan.

## Step 1 — Run audit

```bash
python3 .claude/skills/generate-questions/scripts/audit_questions.py
```

Accepts optional scope flags: `--topic {topicId}`, `--category {categoryId}`, `--super-category {superCategoryId}`.

Display the full output.

## Step 2 — Run validation

```bash
python3 .claude/skills/generate-questions/scripts/validate_questions.py
```

Display violations report. Structural errors (exit 1) must be fixed before any other work.

## Step 3 — Synthesise action plan

Prioritise:

| Priority | Condition |
|----------|-----------|
| **CRITICAL** | Validation errors (exit 1 from validate_questions.py) |
| **HIGH** | Thin topics sorted by count ascending (< 10 q) |
| **MEDIUM** | Missing sources / facts / sync issues |
| **LOW** | Variety warnings (difficulty spread, wrong answer counts) |

## Step 4 — Offer to generate

Offer to invoke `generate-questions` for the N thinnest topics. Default: top 5.

User specifies N. Then invoke the skill:

```
Skill tool: generate-questions
```

Pass topic IDs from the thin-topics list.

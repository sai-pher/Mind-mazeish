# Proposal: AI Agent Task Documentation Standards

## Directory structure

```
ai/
└── tasks/
    └── {feature-area}/           ← one directory per initiative
        ├── plan.md               ← REQUIRED: authoritative plan (this file)
        ├── proposal/             ← optional: pre-plan proposals
        │   ├── 01-{topic}.md
        │   └── ...
        └── research/             ← optional: raw research notes, never committed half-complete
            └── {topic}.md
```

### Naming conventions

| Item | Rule | Example |
|------|------|---------|
| Directory | `kebab-case`, noun phrase | `issue-management`, `question-maintainence` |
| `plan.md` | Always `plan.md` — one per directory | `ai/tasks/issue-management/plan.md` |
| Proposal files | `NN-{topic}.md` (zero-padded number + topic) | `01-issue-workflows.md` |
| Research files | `{topic}.md` | `github-api-notes.md` |

---

## `plan.md` structure

Every plan follows this template:

```markdown
# Plan: {Title}

## Context
{Why this work exists. 2–5 sentences. Link to relevant issues or prior plans.}

---

## {Section heading}
{Concise content — tables, bullet lists, code blocks preferred over prose}

---

## Order of Operations
{Numbered list of steps in execution order}

---

## Files to Create / Modify
| File | Action |
|------|--------|
| ... | Create / Modify / Delete |

---

## Verification
{Commands to confirm the work is complete and correct}
```

**Rules**:
- No prose where a table or list works
- Maximum 500 lines — split into proposals if longer
- Links between related plans are encouraged
- Plans are living documents — rewrite (don't append) when scope changes

---

## Skill: `plan-task` (CLAUDE.md instruction)

Add to `CLAUDE.md` under "Available skills":

```
- `plan-task` — research and plan a new initiative in ai/tasks/
  - Invoke with the `Skill` tool: `skill: "plan-task"`
```

**Skill location**: `.claude/skills/plan-task/SKILL.md`

**Steps**:
1. Determine `{feature-area}` slug from user description
2. Check if `ai/tasks/{feature-area}/` exists — if so, read existing `plan.md`
3. Identify what research is needed (codebase reads, GitHub issues, external docs)
4. Research (Grep/Read as needed) — write findings to `ai/tasks/{feature-area}/research/{topic}.md` if non-trivial
5. Write proposals to `ai/tasks/{feature-area}/proposal/NN-{topic}.md` (one file per distinct concern)
6. Write or rewrite `ai/tasks/{feature-area}/plan.md` from proposals
7. Commit: `docs: add ai task plan for {feature-area}`

**Token efficiency**:
- Write research to files — do not hold large research blobs in context
- Proposals are written sequentially, committed after each to checkpoint
- `plan.md` is written last, after all proposals exist

---

## Discovery

An agent entering a new conversation can orient itself by:

```bash
find ai/tasks -name "plan.md" | xargs ls -t  # most recently modified first
```

Then read the most relevant `plan.md` to understand current priorities and constraints.

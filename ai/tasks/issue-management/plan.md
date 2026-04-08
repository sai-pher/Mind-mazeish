# Plan: Issue Management Tooling for Mind Mazeish

## Context

In-app feedback creates GitHub issues on `sai-pher/Mind-mazeish` via `GithubIssueService`. Issues fall into 7 types across two categories: general feedback (bug, feature, ui-ux, improvement, other) and content requests (new topic, more questions). This plan delivers skills and standards to manage those issues end-to-end.

Proposals: `ai/tasks/issue-management/proposal/`

---

## Proposals Summary

| # | Proposal | Output |
|---|---------|--------|
| 01 | [Issue Workflows](proposal/01-issue-workflows.md) | Per-type workflows + quality gates + branch naming |
| 02 | [Resolution Skills](proposal/02-resolution-skills.md) | 5 new skills: `triage-issue`, `investigate-issue`, `fix-bug`, `implement-feature`, `resolve-issue` |
| 03 | [Communication Skills](proposal/03-communication-skills.md) | 5 comment templates + `gh` CLI commands |
| 04 | [Contributing Standards](proposal/04-contributing.md) | `CONTRIBUTING.md` at project root |
| 05 | [AI Task Doc Standards](proposal/05-ai-task-docs.md) | `plan.md` template + `plan-task` skill + CLAUDE.md update |
| 06 | [Testing Standards](proposal/06-testing-standards.md) | Coverage gates + `TESTING.md` + test conventions |

---

## Order of Operations

1. **Create `CONTRIBUTING.md`** — project root; unblocks all other work
2. **Create `TESTING.md`** — project root; referenced by `CONTRIBUTING.md`
3. **Create `triage-issue` skill** — `.claude/skills/triage-issue/SKILL.md`
4. **Create `investigate-issue` skill** — `.claude/skills/investigate-issue/SKILL.md`
5. **Create `fix-bug` skill** — `.claude/skills/fix-bug/SKILL.md`
6. **Create `implement-feature` skill** — `.claude/skills/implement-feature/SKILL.md`
7. **Create `resolve-issue` skill** — `.claude/skills/resolve-issue/SKILL.md`
8. **Create `plan-task` skill** — `.claude/skills/plan-task/SKILL.md`
9. **Update `CLAUDE.md`** — add new skills to the available skills list
10. **Create required GitHub labels** — `triaged`, `needs-info`, `resolved`, `awaiting-merge`
11. **Add CI coverage gate** — update `.github/workflows/` to enforce coverage thresholds
12. **Commit all** — `chore: add issue management skills and contributing standards`

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `CONTRIBUTING.md` | Create |
| `TESTING.md` | Create |
| `.claude/skills/triage-issue/SKILL.md` | Create |
| `.claude/skills/investigate-issue/SKILL.md` | Create |
| `.claude/skills/fix-bug/SKILL.md` | Create |
| `.claude/skills/implement-feature/SKILL.md` | Create |
| `.claude/skills/resolve-issue/SKILL.md` | Create |
| `.claude/skills/plan-task/SKILL.md` | Create |
| `CLAUDE.md` | Modify — add 6 new skills |
| `.github/workflows/ci.yml` | Modify — add coverage gate |

---

## Quality Gates (for this plan's own implementation)

```bash
# All skills exist
ls .claude/skills/{triage-issue,investigate-issue,fix-bug,implement-feature,resolve-issue,plan-task}/SKILL.md

# CONTRIBUTING.md and TESTING.md exist
ls CONTRIBUTING.md TESTING.md

# CLAUDE.md lists new skills
grep -c "triage-issue\|investigate-issue\|fix-bug\|implement-feature\|resolve-issue\|plan-task" CLAUDE.md
# Expected: 6
```

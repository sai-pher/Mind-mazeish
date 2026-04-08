# Proposal: Issue Workflows

## Issue Types

Issues arrive from the in-app feedback feature as GitHub issues on `sai-pher/Mind-mazeish` with the following label sets:

| Type | Labels | Owner skill |
|------|--------|-------------|
| Bug Report | `bug`, `alpha-feedback` | `fix-bug` |
| Feature Request | `enhancement`, `alpha-feedback` | `implement-feature` |
| UI / UX | `ui-ux`, `alpha-feedback` | `implement-feature` |
| Improvement | `improvement`, `alpha-feedback` | `implement-feature` |
| Other | `feedback`, `alpha-feedback` | `triage-issue` |
| Content Request — New Topic | `content-request`, `alpha-feedback` | `add-topic` (existing skill) |
| Content Request — More Questions | `content-request`, `alpha-feedback` | `generate-questions` (existing skill) |

---

## Workflow per Type

### Bug Report

```
triage → investigate → fix → test → PR → resolve
```

1. **Triage** (`triage-issue`): read issue, post understanding comment, label `triaged`
2. **Investigate** (`investigate-issue`): reproduce path, identify root cause, post investigation comment
3. **Fix**: apply minimal code change; add/update regression test
4. **Quality gate**: `flutter analyze --fatal-infos` + `flutter test --reporter expanded` pass; no new failures
5. **PR**: branch `fix/issue-{N}-{slug}`, PR references issue
6. **Resolve** (`resolve-issue`): post resolution comment on issue, link PR

### Feature Request / UI-UX / Improvement

```
triage → plan → implement → test → PR → resolve
```

1. **Triage** (`triage-issue`): read issue, post understanding comment, label `triaged`
2. **Plan**: post intent comment with scope (what will/won't be implemented)
3. **Implement**: minimal change scoped to the request
4. **Quality gate**: `flutter analyze --fatal-infos` + `flutter test --reporter expanded` pass
5. **PR**: branch `feat/issue-{N}-{slug}` or `improvement/issue-{N}-{slug}`
6. **Resolve** (`resolve-issue`): post resolution comment, link PR

### Content Request — New Topic

```
triage → add-topic skill → PR → resolve
```

1. **Triage**: confirm topic name, post understanding comment
2. **Execute**: invoke `add-topic` skill (creates registry entry, JSON files, generates 30 questions)
3. **Quality gate**: `validate_questions.py --topic {topicId}` exits 0; `flutter analyze` passes
4. **PR**: branch `content/issue-{N}-add-topic-{slug}`
5. **Resolve**: post resolution comment with topic summary

### Content Request — More Questions

```
triage → generate-questions skill → PR → resolve
```

1. **Triage**: confirm topicId, target count, post understanding comment
2. **Execute**: invoke `generate-questions` skill
3. **Quality gate**: `validate_questions.py --topic {topicId}` exits 0
4. **PR**: branch `content/issue-{N}-more-questions-{topicId}`
5. **Resolve**: post resolution comment with count added

### Other / Ambiguous

```
triage → classify → route to appropriate workflow
```

1. **Triage**: read issue, determine actual category, relabel
2. **Route**: invoke the correct workflow above
3. If ambiguous: post clarifying comment, add label `needs-info`

---

## Quality Gates (summary)

| Gate | Command | Pass condition |
|------|---------|----------------|
| Static analysis | `flutter analyze --fatal-infos` | Exit 0 |
| Tests | `flutter test --reporter expanded` | Exit 0, no regressions |
| Question validation | `validate_questions.py --topic {id}` | Exit 0 |
| PR scope | PR diff | No unrelated changes |
| Issue linked | PR body | `Closes #N` present |

---

## Branch Naming

```
fix/issue-{N}-{short-slug}
feat/issue-{N}-{short-slug}
improvement/issue-{N}-{short-slug}
content/issue-{N}-{short-slug}
```

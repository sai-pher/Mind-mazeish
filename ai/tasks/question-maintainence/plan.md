# Plan: Question Management Tooling for Mind Mazeish

## Context

35 topics, ~256 questions (growing to 1–5k in alpha, >10k in beta). Questions live in per-topic JSON assets and will migrate to SQLite later. This plan delivers a new RDB-compatible schema, migration scripts, AI agent skills, and Dart model updates to support that evolution.

Proposals:
- [01 — Skills & Models](proposal/01-skills-and-models.md): full schema spec, scripts, and skill designs
- [02 — Model Compatibility](proposal/02-model-compatibility.md): Dart code changes for the new schema

---

## Schema changes

| Field | Change |
|-------|--------|
| `articleTitle`, `articleUrl` | Removed — replaced by `sourceId` |
| `sourceId` | New FK → `assets/questions/sources/{topicId}.json` |
| `topicCategoryId`, `superCategoryId` | New — denormalised from registry |
| `wrongAnswers` | Target 8–12 (was 4–10) |

New top-level assets: `assets/questions/sources/{topicId}.json` (Source + Facts), `assets/questions/book_sets/{superCategoryId}.json`.

---

## Scripts

All in `.claude/skills/generate-questions/scripts/`. See [proposal/01](proposal/01-skills-and-models.md#scripts) for full specs.

| Script | Purpose |
|--------|---------|
| `export_registry.py` | Parse `topic_registry.dart` → `data/registry.json` |
| `migrate_questions.py` | `articleTitle`/`articleUrl` → `sourceId`; add `topicCategoryId`, `superCategoryId` |
| `sync_sources.py` | Rebuild `questionIds` in all sources files |
| `audit_questions.py` | Health report: counts, difficulty spread, thin topics |
| `validate_questions.py` | Deep validation; exits 1 on violations |

---

## Skills

| Skill | Location | Status |
|-------|---------|--------|
| `generate-questions` | `.claude/skills/generate-questions/SKILL.md` | Update paths + schema |
| `audit-questions` | `.claude/skills/audit-questions/SKILL.md` | New |
| `add-topic` | `.claude/skills/add-topic/SKILL.md` | New |
| `relearn` | `.claude/skills/relearn/SKILL.md` | New |
| `research-rabbit` | `.claude/skills/research-rabbit/SKILL.md` | New |

---

## Dart changes

3 files — no UI impact. See [proposal/02](proposal/02-model-compatibility.md) for full diff.

| File | Change |
|------|--------|
| `domain/models/question.dart` | Add `sourceId`, `topicCategoryId`, `superCategoryId`; add `withSource()` factory; backward-compat `fromJson` |
| `data/question_repository.dart` | Load sources JSON; inject `articleTitle`/`articleUrl` from source at load time |
| `test/.../game_state_test.dart` | Add 3 new fields to all `Question(...)` fixtures |

---

## Order of Operations

1. Run `export_registry.py` → `registry.json`
2. Run `migrate_questions.py` — update all 35 topic JSON files
3. Run `sync_sources.py` — rebuild `questionIds` in all sources files
4. Apply Dart changes (question.dart, question_repository.dart, game_state_test.dart)
5. `flutter analyze --fatal-infos` + `flutter test` — must pass
6. Update `generate-questions/SKILL.md` — fix paths + new schema
7. Write `audit-questions/SKILL.md`
8. Write `add-topic/SKILL.md`
9. Write `relearn/SKILL.md`
10. Write `research-rabbit/SKILL.md`
11. Update `CLAUDE.md` — add new skills
12. Commit: `chore: migrate question schema and add question management skills`

---

## Verification

```bash
# 1. Export registry
python3 .claude/skills/generate-questions/scripts/export_registry.py
# Expected: "Exported 9 superCategories, 18 topicCategories, 35 topics"

# 2. Validate all questions
python3 .claude/skills/generate-questions/scripts/validate_questions.py
# Expected: exit 0 (or warnings only)

# 3. Audit report
python3 .claude/skills/generate-questions/scripts/audit_questions.py
# Expected: full hierarchy report

# 4. Flutter checks
flutter analyze --fatal-infos && flutter test --reporter expanded
# Expected: both exit 0

# 5. Skills exist
ls .claude/skills/{audit-questions,add-topic,relearn,research-rabbit}/SKILL.md
```

# Proposal: Testing Standards & Coverage Gateways

## Current state

- 2 test files: `test/widget_test.dart`, `test/features/gameplay/domain/game_state_test.dart`
- No coverage enforcement
- No widget or integration tests

---

## Test types

| Type | Location | Tools | When required |
|------|---------|-------|---------------|
| Unit | `test/features/{feature}/domain/` | `flutter_test` | All domain models, pure functions, providers |
| Widget | `test/features/{feature}/presentation/` | `flutter_test`, `flutter_riverpod` | All screens and stateful widgets |
| Integration | `integration_test/` | `integration_test` package | Critical user flows (start → game → results) |

---

## Coverage requirements

| Scope | Minimum coverage | Enforced by |
|-------|-----------------|-------------|
| Domain models & logic (`domain/`) | 80% line coverage | CI gate |
| Question data functions (`data/question_bank.dart`) | 90% line coverage | CI gate |
| Overall project | 60% line coverage | CI gate (soft — warning only until > 60% is reached) |

**Exclusions**: generated files, `main.dart`, theme/constants files.

---

## Quality gates (CI)

```bash
# Gate 1: static analysis
flutter analyze --fatal-infos

# Gate 2: tests + coverage
flutter test --coverage --reporter expanded

# Gate 3: coverage threshold check
lcov --summary coverage/lcov.info
# Fail CI if domain/ < 80% or question_bank.dart < 90%
```

Both gates must pass for a PR to merge.

---

## Test requirements by issue type

| Issue type | Test requirement |
|-----------|-----------------|
| Bug fix | Regression test that fails before the fix, passes after |
| Feature / UI change | Widget test covering the new screen state or interaction |
| Improvement | Existing tests must not regress |
| Content (questions) | `validate_questions.py` — no unit test required |

---

## Test conventions

- Test file mirrors source file: `lib/features/gameplay/domain/game_state.dart` → `test/features/gameplay/domain/game_state_test.dart`
- Group with `group('{ClassName}', () { ... })`
- Name tests: `'{method/scenario} {expected outcome}'` — e.g. `'selectQuestionsFrom returns N questions for valid topicId'`
- Use `setUp`/`tearDown` for shared state; avoid `setUpAll` with mutable state
- Riverpod: use `ProviderContainer` in unit tests; `ProviderScope` in widget tests
- No mocking of internal code — use real implementations; mock only external I/O (HTTP, platform channels)

---

## Testing standards file

A `TESTING.md` at the project root (referenced from `CONTRIBUTING.md`) explains:
- How to run tests locally
- Coverage report generation
- What to test for each contribution type

**File**: `TESTING.md`

```markdown
# Testing

## Run tests
```bash
export PATH="$PATH:/opt/flutter/bin"
flutter test --reporter expanded
```

## Run with coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Coverage requirements
- Domain logic: ≥ 80%
- `question_bank.dart`: ≥ 90%
- See `ai/tasks/issue-management/proposal/06-testing-standards.md` for full spec
```

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

- Domain logic (`domain/`): ≥ 80% line coverage
- `question_bank.dart`: ≥ 90% line coverage
- Overall project: ≥ 60% line coverage (soft gate — warning only until threshold is reached)

See `ai/tasks/issue-management/proposal/06-testing-standards.md` for full spec.

## Test types

| Type | Location | When required |
|------|---------|---------------|
| Unit | `test/features/{feature}/domain/` | All domain models, pure functions, providers |
| Widget | `test/features/{feature}/presentation/` | All screens and stateful widgets |
| Integration | `integration_test/` | Critical user flows (start → game → results) |

## Requirements by contribution type

| Contribution | Test requirement |
|-------------|-----------------|
| Bug fix | Regression test that fails before the fix, passes after |
| Feature / UI change | Widget test covering the new screen state or interaction |
| Improvement | Existing tests must not regress |
| Content (questions) | `validate_questions.py` — no unit test required |

## Conventions

- Test file mirrors source: `lib/features/gameplay/domain/game_state.dart` → `test/features/gameplay/domain/game_state_test.dart`
- Group with `group('{ClassName}', () { ... })`
- Name tests: `'{method/scenario} {expected outcome}'`
- Riverpod: use `ProviderContainer` in unit tests; `ProviderScope` in widget tests
- No mocking of internal code — mock only external I/O (HTTP, platform channels)

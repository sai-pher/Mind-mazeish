# Plan: Model Compatibility — Code Changes for New Question Schema

## Context

`skills-and-models-plan.md` proposes a new question schema that replaces `articleTitle`/`articleUrl` with `sourceId` and adds `topicCategoryId` + `superCategoryId`. This plan covers the Dart code changes needed once migration scripts run on the JSON assets.

---

## Schema diff

| Field | Old | New | Impact |
|-------|-----|-----|--------|
| `articleTitle` | `String` required | removed | Used in 4 locations |
| `articleUrl` | `String` required | removed | Used in 4 locations |
| `sourceId` | absent | `String` (may be `""`) | New — replaces above |
| `topicCategoryId` | absent | `String` required | New — unused in UI |
| `superCategoryId` | absent | `String` required | New — unused in UI |

**UI dependency**: `articleTitle` and `articleUrl` are consumed by:
- `gameplay_screen.dart:154–155` — article tap route params
- `question_card.dart:38` — tooltip message
- `QuizQuestion` getters `:86–87`

These must remain resolvable after the schema change.

---

## Approach

Resolve `articleTitle`/`articleUrl` at load time from the sources JSON. Inject them into `Question` objects in the repository so all UI code stays unchanged.

New Dart type `Source` (internal to repository — not exported) holds `id`, `title`, `url`. Repository builds a `sourceId → Source` map from `assets/questions/sources/{topicId}.json`, then populates `Question.articleTitle`/`Question.articleUrl` from that map during deserialization.

---

## Changes

### 1. `lib/features/gameplay/domain/models/question.dart`

**`Question`**:
- Add fields: `sourceId`, `topicCategoryId`, `superCategoryId` (all `String`, default `""`)
- Keep `articleTitle`, `articleUrl` as `String` (no change to type — resolved externally)
- Update `fromJson`: read new fields; backward-compat fallback for old JSON that still has `articleTitle`/`articleUrl`

```dart
// fromJson changes
sourceId: json['sourceId'] as String? ?? '',
topicCategoryId: json['topicCategoryId'] as String? ?? '',
superCategoryId: json['superCategoryId'] as String? ?? '',
// backward-compat: may still be present in old JSON pre-migration
articleTitle: json['articleTitle'] as String? ?? '',
articleUrl: json['articleUrl'] as String? ?? '',
```

Add factory constructor for source injection:
```dart
Question withSource({required String title, required String url}) => Question(
  id: id, question: question, correctAnswers: correctAnswers,
  wrongAnswers: wrongAnswers, funFact: funFact, sourceId: sourceId,
  topicCategoryId: topicCategoryId, superCategoryId: superCategoryId,
  articleTitle: title, articleUrl: url, topicId: topicId, difficulty: difficulty,
);
```

**`QuizQuestion`**: no changes needed — still delegates to `source.articleTitle`/`source.articleUrl`.

---

### 2. `lib/features/gameplay/data/question_repository.dart`

Add private `Source` record (not exported):
```dart
typedef _Source = ({String id, String title, String url});
```

Add `_loadSources(String topicId)`:
```dart
Future<Map<String, _Source>> _loadSources(String topicId) async {
  try {
    final raw = await rootBundle.loadString('assets/questions/sources/$topicId.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return {
      for (final e in list.cast<Map<String, dynamic>>())
        if ((e['id'] as String?)?.isNotEmpty == true)
          e['id'] as String: (id: e['id'] as String, title: e['title'] as String? ?? '', url: e['url'] as String? ?? ''),
    };
  } catch (_) {
    return {};
  }
}
```

Update `loadQuestionsForTopics`:
```dart
Future<List<Question>> loadQuestionsForTopics(Set<String> topicIds) async {
  final results = <Question>[];
  for (final id in topicIds) {
    final sources = await _loadSources(id);
    // ... existing loadString for topics ...
    results.addAll(list.map((e) {
      final q = Question.fromJson(e as Map<String, dynamic>);
      if (q.articleTitle.isEmpty && q.sourceId.isNotEmpty) {
        final src = sources[q.sourceId];
        if (src != null) return q.withSource(title: src.title, url: src.url);
      }
      return q;
    }));
  }
  return results;
}
```

---

### 3. `test/features/gameplay/domain/game_state_test.dart`

Update all 3 `Question(...)` constructors:
- Add `sourceId: ''`, `topicCategoryId: ''`, `superCategoryId: ''`
- Keep `articleTitle`, `articleUrl` as-is (still valid fields)
- Update `fromJson` map fixture to add the 3 new fields

---

## Order of operations

1. Run `migrate_questions.py` (JSON assets — per `skills-and-models-plan.md`)
2. Apply code changes (steps 1–3 above)
3. Run `flutter analyze --fatal-infos` — must exit 0
4. Run `flutter test --reporter expanded` — must exit 0
5. Smoke-test on device: article tap still opens WebView with correct title/url

---

## Files changed

| File | Change |
|------|--------|
| `lib/features/gameplay/domain/models/question.dart` | Add 3 fields; add `withSource`; update `fromJson` |
| `lib/features/gameplay/data/question_repository.dart` | Add `_Source`, `_loadSources`; update `loadQuestionsForTopics` |
| `test/features/gameplay/domain/game_state_test.dart` | Add 3 new fields to all `Question(...)` fixtures |

`NotebookEntry`, `gameplay_screen.dart`, `question_card.dart`, `QuizQuestion` — **no changes**.

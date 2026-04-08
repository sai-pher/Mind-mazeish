---
name: add-topic
description: Add a brand-new topic to Mind Mazeish — creates registry entry, JSON files, and generates 30 starter questions. Use when a content request for a new topic arrives.
metadata:
  author: ariwoode
  version: "1.0"
---

# add-topic

Adds a new topic end-to-end: registry, JSON files, sources, 30 questions.

## Step 0 — Gather inputs

Ask the user (or derive from issue body):
- `topicId` — must match `^[a-z][a-z0-9_]*$`
- Display name (e.g. "Jazz Music")
- Emoji
- SuperCategory and TopicCategory (existing or new)

## Step 1 — Validate

- Not already in `lib/features/gameplay/data/topic_registry.dart`
- Not already in `assets/questions/topics/`
- `topicId` matches `^[a-z][a-z0-9_]*$`

## Step 2 — Edit topic_registry.dart

Append `Topic(id: '{topicId}', name: '{name}', categoryId: '{categoryId}', emoji: '{emoji}')` to the correct `TopicCategory.topics` list.

## Step 3 — Edit question_repository.dart

Add `'{topicId}',` to `_allTopicIds` (alphabetical order).

## Step 4 — Create asset files

```bash
echo '[]' > assets/questions/topics/{topicId}.json
echo '[]' > assets/questions/sources/{topicId}.json
```

## Step 5 — Rebuild registry

```bash
python3 .claude/skills/generate-questions/scripts/export_registry.py
```

Confirm the new topic appears in output.

## Step 6 — Generate questions

```
Skill tool: generate-questions
```

Target: 30 questions. Pass `topicId` as scope.

## Step 7 — Sync and validate

```bash
python3 .claude/skills/generate-questions/scripts/sync_sources.py --topic {topicId}
python3 .claude/skills/generate-questions/scripts/validate_questions.py --topic {topicId}
```

Fix any violations before committing.

## Step 8 — Commit

```bash
git add lib/features/gameplay/data/topic_registry.dart \
        lib/features/gameplay/data/question_repository.dart \
        assets/questions/topics/{topicId}.json \
        assets/questions/sources/{topicId}.json \
        .claude/skills/generate-questions/data/registry.json
git commit -m "content: add {topicId} topic with 30 starter questions"
```

## Quality gate

```bash
export PATH="$PATH:/opt/flutter/bin"
flutter analyze --fatal-infos
```

Must exit 0 before committing.

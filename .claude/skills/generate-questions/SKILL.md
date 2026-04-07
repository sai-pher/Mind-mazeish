---
name: generate-questions
description: Generate trivia questions for the Mind Mazeish castle game and append them to per-topic JSON files in assets/questions/topics/. Use when expanding an existing topic, adding questions to a specific topicId, seeding a brand-new topic (target ≥ 30 questions), or bulk-updating multiple topics at once. Fetches Wikipedia source material via bundled scripts. Falls back to built-in knowledge when network is unavailable.
compatibility: Requires Python 3.9+ with Wikipedia-API<0.10.0 installed (pip install -r .claude/generate-questions/scripts/requirements.txt). Internet access recommended for Wikipedia sourcing.
metadata:
  author: ariwoode
  version: "1.1"
---

# generate-questions

Generates trivia questions and appends them to `assets/questions/topics/{topicId}.json`.

## Question schema

```json
{
  "id": "coffee_006",
  "question": "Question text?",
  "correctAnswers": ["The correct answer"],
  "wrongAnswers": ["Wrong 1", "Wrong 2", "Wrong 3", "Wrong 4"],
  "funFact": "1–2 sentences shown after the answer.",
  "articleTitle": "Wikipedia article title",
  "articleUrl": "https://en.m.wikipedia.org/wiki/Article_Title",
  "topicId": "coffee",
  "difficulty": "easy"
}
```

| Field | Rule |
|-------|------|
| `id` | `{topicId}_{NNN}` — unique; count up from current highest |
| `correctAnswers` | 1–3 equally-valid items |
| `wrongAnswers` | **min 4**, plausible (same category / era / scale) |
| `difficulty` | `easy` / `medium` / `hard` — aim for balanced spread |
| `articleUrl` | Mobile Wikipedia only: `https://en.m.wikipedia.org/wiki/...` |
| `topicId` | Must match key in `topic_registry.dart` exactly |

Aim for ≥ 1 question per difficulty level and variety: facts, dates, definitions, comparisons.

---

## Execution procedure

### Step 0 — Clarify scope (ask once)
1. Which topic(s)? (specific id, category name, or "all thin topics")
2. Target count? (default: **10** for existing topics, **30** for new)
3. Any specific angles or subtopics to cover?

### Step 1 — Determine work items
For each topic: read `assets/questions/topics/{topicId}.json`, note current count, highest id suffix, and existing IDs (for dedup). Group topics by TopicCategory; process one category at a time.

### Step 1.5 — Search Wikipedia
```bash
python3 .claude/generate-questions/scripts/search_wiki.py "{topic name}" --results 5
```
- **Exit 0, results** → select 2–3 most relevant articles; skip disambiguation pages
- **Exit 0, `[]`** → guess canonical title (e.g. `"Coffee"` for topicId `coffee`)
- **Exit 3** → network unavailable; set `network_down = true`; skip Steps 1.5 & 2

### Step 3 — Spawn one sub-agent per topic

**Network available:**
> Generate {N} trivia questions for topicId `{topicId}` covering {brief description}.
> Existing IDs to avoid: {comma-separated list}.
> Start from: `{topicId}_{NNN}`.
>
> Fetch each article with `python3 .claude/generate-questions/scripts/fetch_wiki.py "{title}"` (no `--summary-only`).
> If a fetch exits 2 or 3: skip it; use built-in knowledge; set `articleTitle`/`articleUrl` to `""`;
> append `"(Based on general knowledge — no Wikipedia source was available.)"` to funFact.
>
> Append new questions to `assets/questions/topics/{topicId}.json` (read first, then append).
> Reply: new IDs written + which article each came from (or "general knowledge").

**Network down:**
> Generate {N} questions for topicId `{topicId}` covering {brief description}.
> Existing IDs to avoid: {comma-separated list}. Start from `{topicId}_{NNN}`.
> Network unavailable — use built-in knowledge only. Set `articleTitle`/`articleUrl` to `""`.
> Append `"(Based on general knowledge — no Wikipedia source was available.)"` to each funFact.
> Append to `assets/questions/topics/{topicId}.json`. Reply: new IDs written.

Wait for each sub-agent to complete before spawning the next.

### Step 3.5 — Update sources manifest
Skip if `network_down = true`. Read `assets/questions/sources/{topicId}.json` (or start with `[]`). For each successfully fetched article, find its entry by `title` or append a new one; merge new `questionIds` (no duplicates); write back.

Entry structure:
```json
{
  "title": "Coffee",
  "url": "https://en.m.wikipedia.org/wiki/Coffee",
  "summary": "...",
  "categories": ["Coffee", "Beverages"],
  "questionIds": ["coffee_006", "coffee_007"]
}
```

### Step 4 — Verify
```bash
python3 -c "
import json; data = json.load(open('assets/questions/topics/{topicId}.json'))
ids = [q['id'] for q in data]
assert len(ids) == len(set(ids)), 'Duplicate IDs!'
assert all(len(q['wrongAnswers']) >= 4 for q in data), 'Too few wrong answers!'
assert all(q['difficulty'] in ('easy','medium','hard') for q in data), 'Bad difficulty!'
print(f'OK — {len(ids)} questions')
"
```
Fix any violations inline before moving on.

### Step 5 — Checkpoint commit (after each TopicCategory)
```bash
export PATH="$PATH:/opt/flutter/bin"
git config --global --add safe.directory /opt/flutter
git add assets/questions/topics/ assets/questions/sources/
git commit -m "content: add questions for {category} topics ({topicId}, ...)"
git push -u origin $(git branch --show-current)
```

### Step 6 — Report
```
| Topic  | Added | Sources                                         |
|--------|-------|-------------------------------------------------|
| coffee |   5   | Coffee (3 q), Coffee preparation (2 q)          |
| tennis |   5   | Tennis (4 q), general knowledge (1 q)           |
| adhd   |   8   | general knowledge (8 q) — network unavailable   |
```

---

## Token efficiency rules
1. Sub-agents write to files directly — never return large JSON blobs to main context
2. Pass IDs only for dedup, not full question text
3. Sub-agents fetch full article text — main agent only runs `search_wiki.py`
4. One sub-agent per topic, not per article
5. Verify with one-liner (not re-reading the full file)

---

For detailed workflow examples and instructions for adding a brand-new topic, see [references/examples.md](references/examples.md).

---
name: generate-questions
description: Generate trivia questions for the Mind Mazeish castle game and append them to per-topic JSON files in assets/questions/topics/. Use when expanding an existing topic, adding questions to a specific topicId, seeding a brand-new topic (target ≥ 30 questions), or bulk-updating multiple topics at once. Requires Wikipedia source material — aborts if network is unavailable.
compatibility: Requires Python 3.9+ with Wikipedia-API<0.10.0 installed (pip install -r .claude/skills/generate-questions/scripts/requirements.txt). Internet access required.
metadata:
  author: ariwoode
  version: "1.4"
---

# generate-questions

Generates trivia questions and appends them to `assets/questions/topics/{topicId}.json`.

## Question schema

```json
{
  "id": "coffee_006",
  "question": "Question text?",
  "correctAnswers": ["The correct answer"],
  "wrongAnswers": [
    "Wrong 1", "Wrong 2", "Wrong 3", "Wrong 4",
    "Wrong 5", "Wrong 6", "Wrong 7", "Wrong 8"
  ],
  "funFact": "1–2 sentences shown after the answer.",
  "sourceId": "src_history_of_coffee",
  "topicId": "coffee",
  "topicCategoryId": "beverages",
  "superCategoryId": "food_drink",
  "difficulty": "easy"
}
```

| Field | Rule |
|-------|------|
| `id` | `{topicId}_{NNN}` — unique; count up from current highest |
| `correctAnswers` | 1–3 equally-valid items (see difficulty criteria below) |
| `wrongAnswers` | **target 8–12**, min 4, max 20 — plausible (same category / era / scale) |
| `difficulty` | `easy` / `medium` / `hard` — aim for balanced spread |
| `sourceId` | `src_{slugify(articleTitle)}` — **must be a valid, non-empty source id** |
| `topicCategoryId` | From `registry.json` for this topic |
| `superCategoryId` | From `registry.json` for this topic |
| `topicId` | Must match key in `topic_registry.dart` exactly |

**Note:** `articleTitle` and `articleUrl` are no longer stored on questions. They are resolved at load time from `assets/questions/sources/{topicId}.json` via `sourceId`.

---

## Difficulty criteria (use verbatim in all prompts)

| Level | Criteria |
|-------|----------|
| **easy** | Widely known fact. Casual fan would know it. Single-hop recall. Always 1 correct answer. |
| **medium** | Requires genuine interest. Comparative, numerical, contextual. 1–2 correct answers; open-ended framing where natural. |
| **hard** | Obscure, specialist knowledge. 1–3 correct answers; both odd-one-out and open-ended styles encouraged. |

**Multiple correct answers:** The game picks one at random to display. Question wording must be satisfiable by any single correct answer in isolation. Never use "select all that apply" framing.

---

## Execution procedure

### Step 0 — Clarify scope (ask once)
1. Which topic(s)? (specific id, category name, or "all thin topics")
2. Target count? (default: **10** for existing topics, **30** for new)
3. Generate from Wikipedia (default) or from existing source facts?
4. Any specific angles or subtopics to cover?

### Step 1 — Determine work items
For each topic: read `assets/questions/topics/{topicId}.json`, note current count, highest id suffix, and existing IDs (for dedup). Read `registry.json` for `topicCategoryId`/`superCategoryId`. Group topics by TopicCategory; process one category at a time.

### Step 1.5 — Search Wikipedia and save source stubs
```bash
python3 .claude/skills/generate-questions/scripts/search_wiki.py "{topic name}" --results 5
```
- **Exit 0, results** → select 2–3 most relevant articles; skip disambiguation pages
- **Exit 0, `[]`** → guess canonical title (e.g. `"Coffee"` for topicId `coffee`)
- **Exit 3** → **network unavailable — abort entirely. Do not generate any questions. Inform the user and stop.**

**After a successful search** — immediately persist all results:
```bash
python3 .claude/skills/generate-questions/scripts/search_wiki.py "{topic name}" --results 5 \
  | python3 .claude/skills/generate-questions/scripts/save_sources.py --topic {topicId}
```
This upserts stubs into `assets/questions/sources/{topicId}.json` without overwriting existing values. Source stubs exist on disk before sub-agents run, even if generation is later interrupted.

### Step 3 — Spawn one sub-agent per topic

**Wikipedia mode (default):**
> Generate {N} trivia questions for topicId `{topicId}` (topicCategoryId: `{tcId}`, superCategoryId: `{scId}`).
> Covering {brief description}.
> Existing IDs to avoid: {comma-separated list}.
> Start from: `{topicId}_{NNN}`.
>
> For each article title to fetch:
>
> **A. Fetch article text (and save it):**
> ```
> python3 .claude/skills/generate-questions/scripts/fetch_wiki.py "{title}" \
>   | tee /tmp/wiki_article.txt
> python3 .claude/skills/generate-questions/scripts/save_sources.py \
>   --topic {topicId} --source-id src_{slugify(title)} --article-text < /tmp/wiki_article.txt
> ```
> The first command prints the article text (use it for question generation) and writes `/tmp/wiki_article.txt`.
> The second command saves it to the sources file; it skips the write if `articleText` is already set.
> **If `fetch_wiki.py` exits 2 or 3: do not generate any questions for this article. Skip it and
> continue with remaining articles. If ALL articles fail, abort and report the failure — do not write
> any questions.**
>
> Every question **must** derive from a fetched article. Set `sourceId` = `src_{slugify(articleTitle)}`.
> Never set `sourceId` to `""` or use built-in knowledge as a source.
> Set `topicCategoryId` = `{tcId}`, `superCategoryId` = `{scId}` on every question.
> Target 8–12 wrongAnswers per question.
>
> Append new questions to `assets/questions/topics/{topicId}.json` (read first, then append).
> Reply: new IDs written + which article each came from.

**Facts mode** (user selected facts from existing sources):
> Generate {N} questions for topicId `{topicId}` using the facts in `assets/questions/sources/{topicId}.json`.
> For each fact used: set `sourceId` to the fact's source `id`.
> Set `topicCategoryId` = `{tcId}`, `superCategoryId` = `{scId}`.
> Existing IDs to avoid: {list}. Start from `{topicId}_{NNN}`.
> Append to `assets/questions/topics/{topicId}.json`. Reply: new IDs written.

Spawn one sub-agent per topic, in sequence — wait for each to complete before spawning the next. No parallel agents.

### Step 3.5 — Sync sources
```bash
python3 .claude/skills/generate-questions/scripts/sync_sources.py --topic {topicId}
```

### Step 4 — Verify
```bash
python3 .claude/skills/generate-questions/scripts/validate_questions.py --topic {topicId}
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
| Topic  | Added | Sources                                              |
|--------|-------|------------------------------------------------------|
| coffee |   5   | src_coffee (3 q), src_coffee_brewing (2 q)           |
| tennis |   5   | src_tennis (3 q), src_serena_williams (2 q)          |
```

---

## Token efficiency rules
1. Sub-agents write to files directly — never return large JSON blobs to main context
2. Pass IDs only for dedup, not full question text
3. Sub-agents fetch full article text — main agent only runs `search_wiki.py`
4. One sub-agent per topic, not per article
5. Verify with validate_questions.py (not re-reading the full file)

---

For detailed workflow examples and instructions for adding a brand-new topic, see [references/examples.md](references/examples.md).

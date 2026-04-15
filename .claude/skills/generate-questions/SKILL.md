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
For each topic, get metadata without reading the full file:
```bash
python3 .claude/skills/generate-questions/scripts/topic_stats.py --topic {topicId}
```
This outputs `count`, `nextId`, and `existingIds` — use these for starting ID and dedup. Read `registry.json` for `topicCategoryId`/`superCategoryId`. Group topics by TopicCategory; process one category at a time.

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

### Step 3 — Spawn sub-agents per topic

**Batching rule:** spawn one sub-agent per topic. If the topic has more than 5 source articles to process, split them into batches of ≤5 and run each batch as a separate sequential sub-agent. Pass the next starting ID from the previous batch's output as the starting ID for the next batch.

**Within each sub-agent — process articles one at a time, not all at once.** Fetch an article, generate its questions, append them immediately, then move to the next article. This keeps only one article's text live in working context at any moment.

**Wikipedia mode (default):**
> Generate {N} trivia questions for topicId `{topicId}` (topicCategoryId: `{tcId}`, superCategoryId: `{scId}`).
> Covering {brief description}.
> Existing IDs to avoid: {comma-separated list}.
> Start from: `{topicId}_{NNN}`.
>
> **Process each article in sequence — fetch, generate, append, then move on:**
>
> For article "{title}":
> ```bash
> python3 .claude/skills/generate-questions/scripts/fetch_wiki.py "{title}" \
>   | tee /tmp/wiki_{slug}.txt
> python3 .claude/skills/generate-questions/scripts/save_sources.py \
>   --topic {topicId} --source-id src_{slug} --article-text < /tmp/wiki_{slug}.txt
> ```
> Generate {n_per_article} questions from the article text above.
> Write them to `/tmp/{topicId}_{slug}_questions.json`, then append immediately:
> ```bash
> python3 .claude/skills/generate-questions/scripts/append_questions.py \
>   --topic {topicId} < /tmp/{topicId}_{slug}_questions.json
> ```
> Then proceed to the next article. Do not hold all articles in memory before generating.
>
> **If `fetch_wiki.py` exits 2 or 3:** skip that article, continue with the rest.
> **If ALL articles fail:** abort and report — do not write any questions.
>
> Every question **must** derive from its fetched article. Set `sourceId` = `src_{slug}`.
> Never set `sourceId` to `""` or use built-in knowledge as a source.
> Set `topicCategoryId` = `{tcId}`, `superCategoryId` = `{scId}` on every question.
> Target 8–12 wrongAnswers per question.
> Do NOT read `assets/questions/topics/{topicId}.json` directly.
> Reply: new IDs written + which article each came from.

**Targeted fetching (use when article is large or only partially relevant):**
- `--sections "History" "Techniques"` — fetch only named sections instead of all content
- `--summary-only` — fetch just the intro paragraph (~1200 chars); sufficient for 2–3 questions on peripheral topics

**Facts mode** (user selected facts from existing sources):
> Generate {N} questions for topicId `{topicId}` using the facts from this command (strips large articleText):
> ```bash
> jq '[.[] | del(.articleText)]' assets/questions/sources/{topicId}.json
> ```
> For each fact used: set `sourceId` to the fact's source `id`.
> Set `topicCategoryId` = `{tcId}`, `superCategoryId` = `{scId}`.
> Existing IDs to avoid: {list}. Start from `{topicId}_{NNN}`.
> Write all new questions as a JSON array to `/tmp/{topicId}_new_questions.json`, then append:
> ```bash
> python3 .claude/skills/generate-questions/scripts/append_questions.py \
>   --topic {topicId} < /tmp/{topicId}_new_questions.json
> ```
> Do NOT read `assets/questions/topics/{topicId}.json` directly.
> Reply: new IDs written.

Spawn one sub-agent per topic (or batch), in sequence — wait for each to complete before spawning the next. No parallel agents.

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
1. **Stats only:** use `topic_stats.py` — never read the full topic JSON
2. **Append, don't rewrite:** sub-agents pipe generated questions to `append_questions.py` — never read the topic file
3. **Process article-by-article:** fetch → generate → append → next article. Never accumulate all articles before generating
4. **Batch at 5:** >5 source articles → multiple sub-agents of ≤5 sources each, passing the next starting ID between them
5. **Targeted fetching:** use `--sections` or `--summary-only` on `fetch_wiki.py` for large or peripheral articles
6. **Facts mode when available:** pre-extracted facts (`jq '[.[] | del(.articleText)]'`) are far more compact than fetching full article text; prefer facts mode for topics with ≥20 facts in sources
7. **Main agent stays light:** main agent only runs `search_wiki.py` and `save_sources.py` — all Wikipedia fetching happens inside sub-agents
8. **Verify without reading:** use `validate_questions.py`, not re-reading the full file

---

For detailed workflow examples and instructions for adding a brand-new topic, see [references/examples.md](references/examples.md).

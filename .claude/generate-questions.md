# Skill: /generate-questions

Generates trivia questions and appends them to the correct per-topic asset files
under `assets/questions/topics/{topicId}.json`.

---

## When to use

- Expand an existing topic with more questions
- Seed a brand-new topic from scratch (target ≥ 30 questions)
- Bulk-update several topics at once

---

## Question schema

Each entry in a topic JSON file is:

```json
{
  "id": "coffee_006",
  "question": "Question text?",
  "correctAnswers": ["The correct answer"],
  "wrongAnswers": ["Wrong 1", "Wrong 2", "Wrong 3", "Wrong 4"],
  "funFact": "1–2 sentences of genuinely interesting context shown after the answer.",
  "articleTitle": "Wikipedia article title",
  "articleUrl": "https://en.m.wikipedia.org/wiki/Article_Title",
  "topicId": "coffee",
  "difficulty": "easy"
}
```

### Field rules

| Field | Rule |
|-------|------|
| `id` | `{topicId}_{NNN}` — unique across the whole file; count up from the current highest |
| `correctAnswers` | 1–3 items (all equally valid; game picks one per round) |
| `wrongAnswers` | **minimum 4**, up to 10; must be plausible (same category / era / scale) |
| `difficulty` | `"easy"` / `"medium"` / `"hard"` |
| `articleUrl` | Must use `https://en.m.wikipedia.org/wiki/...` (mobile Wikipedia) |
| `topicId` | Must match the key in `topic_registry.dart` exactly |

### Per-topic output target

Produce:
- At least **1 question per difficulty level** (easy, medium, hard) = minimum 3
- Aim for a balanced spread across easy / medium / hard
- Aim for variety: facts, dates, definitions, cause-and-effect, comparisons

---

## Topic hierarchy (3 levels)

Topics sit in a 3-level hierarchy defined in `lib/features/gameplay/data/topic_registry.dart`:

```
SuperCategory  (e.g. Health & Medicine)
  └── TopicCategory  (e.g. Mental Health)
        └── Topic  (e.g. ADHD)  ← topicId used in JSON
```

When handling **multiple topics**, group and sequence tasks by **TopicCategory** (Level 2) so that related topics are handled together before moving to the next category.

---

## Execution procedure

### Step 0 — Clarify scope (ask the user once)

Before starting, ask:
1. Which topic(s) to work on? (or "all thin topics" / a super-category name)
2. Target question count per topic? (default: **10** for existing topics, **30** for new topics)
3. Any specific angles or subtopics the user wants covered?

### Step 1 — Determine work items

For each topic in scope:
1. Read `assets/questions/topics/{topicId}.json` (or note it doesn't exist yet)
2. Note the current question count and the **highest existing `id` suffix**
3. Note the **existing IDs only** (not full question text) to avoid duplicates later
4. Calculate how many questions are still needed to reach the target

Group topics by their **TopicCategory** (Level 2). Process one TopicCategory at a time.

### Step 1.5 — Search for relevant Wikipedia pages

```bash
python3 scripts/search_wiki.py "{topic name}" --results 5
```

- **Exit 0 with results** → select 2–3 most relevant articles by summary/categories; skip any disambiguation pages
- **Exit 0 with `[]`** → fall back to a canonical title guess (e.g. `"Coffee"` for topicId `coffee`), proceed to Step 2
- **Exit 3** → network unavailable; skip Steps 1.5 and 2 entirely; set built-in knowledge flag and proceed to Step 3

### Step 2 — Fetch article text (mandatory when network is available)

For each article title selected in Step 1.5, run:

```bash
python3 scripts/fetch_wiki.py "{title}" --summary-only
# or with specific sections:
python3 scripts/fetch_wiki.py "{title}" --sections "History" "Uses"
```

Concatenate all outputs with a `---` divider as source material for Step 3.

- **Exit 0** → use the returned text as source material
- **Exit 2** → article not found; try the next candidate from Step 1.5; if all fail, treat as exit 3
- **Exit 3** → network unavailable; set built-in knowledge flag and proceed to Step 3

### Step 3 — Spawn one sub-agent per topic (not per article)

For each topic, spawn **one sub-agent** with this task:

**When source material is available:**
> "Generate {N} trivia questions for topicId `{topicId}` covering {brief description}.
> Existing IDs to avoid duplicating: {comma-separated list of existing IDs, e.g. coffee_001, coffee_002}.
> Next ID to start from: `{topicId}_{NNN}`.
> Source material: {concatenated fetch output}.
> Generate questions directly grounded in this text.
>
> Write the questions **directly** to `assets/questions/topics/{topicId}.json` by
> reading the existing file and rewriting it with the new questions appended.
> Do NOT return the JSON in your reply — just confirm how many questions were written
> and list the new IDs."

**When network was unreachable (built-in knowledge flag set):**
> "Generate {N} trivia questions for topicId `{topicId}` covering {brief description}.
> Existing IDs to avoid duplicating: {comma-separated list}.
> Next ID to start from: `{topicId}_{NNN}`.
> Network was unreachable — use built-in knowledge. Set `articleTitle: ""` and
> `articleUrl: ""`. End each `funFact` with the sentence:
> `"(Based on general knowledge — no Wikipedia source was available.)"`
>
> Write the questions **directly** to `assets/questions/topics/{topicId}.json` by
> reading the existing file and rewriting it with the new questions appended.
> Do NOT return the JSON in your reply — just confirm how many questions were written
> and list the new IDs."

**Wait for the sub-agent to complete before spawning the next one.**

### Step 3.5 — Update the topic sources manifest

After the sub-agent confirms which IDs were written, update
`assets/questions/sources/{topicId}.json`:

1. Read the file if it exists, or start with `[]`
2. For each article fetched in Step 2, find its entry in the array by `title`
   (or append a new entry if not present)
3. Merge the new question IDs into that entry's `questionIds` list (no duplicates)
4. Write the updated array back to the file

**Entry structure:**
```json
{
  "title": "Coffee",
  "url": "https://en.m.wikipedia.org/wiki/Coffee",
  "summary": "Coffee is a beverage prepared from roasted coffee beans [...]",
  "categories": ["Coffee", "Beverages", "Stimulants"],
  "questionIds": ["coffee_001", "coffee_002", "coffee_006"]
}
```

- Use the `title`, `url`, `summary`, and `categories` values from `search_wiki.py`'s output
- Skip this step if the built-in knowledge flag is set (no article was fetched)

### Step 4 — Verify

After each sub-agent completes, run a quick sanity check:

```bash
python3 -c "
import json, sys
data = json.load(open('assets/questions/topics/{topicId}.json'))
ids = [q['id'] for q in data]
assert len(ids) == len(set(ids)), 'Duplicate IDs!'
assert all(len(q['wrongAnswers']) >= 4 for q in data), 'Too few wrong answers!'
assert all(q['difficulty'] in ('easy','medium','hard') for q in data), 'Bad difficulty!'
print(f'OK — {len(data)} questions, IDs: {ids}')
"
```

Fix any violations inline before moving on.

### Step 5 — Checkpoint commit

After completing each **TopicCategory group**, run:

```bash
export PATH="$PATH:/opt/flutter/bin"
git config --global --add safe.directory /opt/flutter
git add assets/questions/topics/ assets/questions/sources/
git commit -m "content: add questions for {category} topics ({topicId}, {topicId}, ...)"
git push -u origin $(git branch --show-current)
```

Then continue to the next TopicCategory group.

---

## Token efficiency rules

1. **Sub-agents write to files directly** — never return large JSON blobs back to the main context
2. **Pass IDs only** for duplicate-checking, not full question text
3. **Always search then fetch** — run `search_wiki.py` first, then `fetch_wiki.py` for the top 2–3 results; only fall back to built-in knowledge when both return exit code 3
4. **One sub-agent per topic** (not per article) — reduces agent spawning overhead
5. **Verify with a one-liner** — the bash python3 check above is cheaper than re-reading the file

---

## Example: expanding a single existing topic

User: `/generate-questions coffee`

1. Read `assets/questions/topics/coffee.json` → 5 questions, highest id `coffee_005`
2. Existing IDs: `coffee_001, coffee_002, coffee_003, coffee_004, coffee_005`
3. Target 10 → need 5 more; start from `coffee_006`
4. Search: `python3 scripts/search_wiki.py "coffee" --results 5`
   → selects "Coffee" and "Coffee preparation"
5. Fetch: `python3 scripts/fetch_wiki.py "Coffee" --summary-only` (exit 0)
   `python3 scripts/fetch_wiki.py "Coffee preparation" --summary-only` (exit 0)
6. Sub-agent → generate 5 questions grounded in fetch output → write to file → confirm IDs
7. Update `assets/questions/sources/coffee.json` with new entries and question IDs
8. Verify with one-liner
9. Commit: `content: add questions for beverages topics (coffee)`

---

## Example: bulk update (multiple topics)

User: `/generate-questions mental_health category`

Topics in Mental Health: `therapy`, `adhd`, `autism`

1. Read all three files → note current counts and existing IDs
2. Search + fetch for `therapy` → sub-agent writes → update sources manifest → verify
3. Search + fetch for `adhd` → sub-agent writes → update sources manifest → verify
4. Search + fetch for `autism` → sub-agent writes → update sources manifest → verify
5. Commit: `content: expand mental_health questions (therapy, adhd, autism)`

---

## Adding a brand-new topic

1. Check `assets/questions/topics/{topicId}.json` → doesn't exist
2. Ask user: which TopicCategory should it sit under?
3. Add `Topic(id: '{topicId}', ...)` to `topic_registry.dart`
4. Add `'{topicId}'` to `_allTopicIds` in `question_repository.dart`
5. Sub-agent creates the file with ≥ 30 questions
6. Commit after all done

---

## Notes

- **Never remove existing questions** — only append
- **No duplicate IDs** — always read the file first to find the current max suffix
- **Mobile Wikipedia URLs only** — `https://en.m.wikipedia.org/wiki/...`
- **One sub-agent at a time** — wait for completion before spawning the next
- **Commit after each TopicCategory** — prevents token-limit loss

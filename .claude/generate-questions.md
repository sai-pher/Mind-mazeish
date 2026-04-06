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

- **Exit 0 with results** → capture the full JSON array; select 2–3 most relevant articles by summary/categories; skip any disambiguation pages
- **Exit 0 with `[]`** → fall back to a canonical title guess (e.g. `"Coffee"` for topicId `coffee`); record `[{"title": "{guessed title}", "url": "https://en.m.wikipedia.org/wiki/{Guessed_Title}"}]` as the search result
- **Exit 3** → network unavailable; skip Steps 1.5 and 2; set `network_down = true` and proceed to Step 3

Do **not** fetch article text in the main agent — pass titles and URLs to the sub-agent (Step 3).

### Step 2 — (skipped — sub-agent handles fetching)

Article fetching is done inside the sub-agent in Step 3 so that large article text never passes through the main context.

### Step 3 — Spawn one sub-agent per topic (not per article)

For each topic, spawn **one sub-agent** with this task:

**When articles were found (network_down = false):**
> "Generate {N} trivia questions for topicId `{topicId}` covering {brief description}.
> Existing IDs to avoid: {comma-separated list, e.g. coffee_001, coffee_002}.
> Next ID to start from: `{topicId}_{NNN}`.
>
> Fetch source material for each article below using `fetch_wiki.py` (no `--summary-only`):
> {for each selected article:}
>   - Title: "{title}" → run: `python3 scripts/fetch_wiki.py "{title}"`
>
> Use the fetched text as the basis for your questions. If a fetch returns exit 2 or 3,
> skip that article and use built-in knowledge for any remaining questions; mark those
> questions with `articleTitle: ""`, `articleUrl: ""`, and end their `funFact` with
> `"(Based on general knowledge — no Wikipedia source was available.)"`
>
> Write the questions **directly** to `assets/questions/topics/{topicId}.json` by
> reading the existing file and appending the new questions.
> Reply with:
> 1. A list of the new IDs written
> 2. Which IDs came from which article title (or "general knowledge" if no article)"

**When network was unreachable (network_down = true):**
> "Generate {N} trivia questions for topicId `{topicId}` covering {brief description}.
> Existing IDs to avoid: {comma-separated list}.
> Next ID to start from: `{topicId}_{NNN}`.
> Network is unavailable — use built-in knowledge for all questions.
> Set `articleTitle: ""` and `articleUrl: ""` on every question.
> End each `funFact` with: `"(Based on general knowledge — no Wikipedia source was available.)"`
>
> Write the questions **directly** to `assets/questions/topics/{topicId}.json` by
> reading the existing file and appending the new questions.
> Reply with the list of new IDs written (all marked as general knowledge)."

**Wait for the sub-agent to complete before spawning the next one.**

### Step 3.5 — Update the topic sources manifest

After the sub-agent replies, update `assets/questions/sources/{topicId}.json`:

1. Read the file if it exists, or start with `[]`
2. For each article that was successfully fetched (per the sub-agent's reply):
   - Find its entry by `title`, or append a new entry
   - Merge the new `questionIds` into that entry's list (no duplicates)
   - Use `title`, `url`, `summary`, and `categories` from the Step 1.5 search output
3. Write the updated array back to the file
4. Skip this step entirely if `network_down = true`

**Entry structure:**
```json
{
  "title": "Coffee",
  "url": "https://en.m.wikipedia.org/wiki/Coffee",
  "summary": "Coffee is a beverage prepared from roasted coffee beans [...]",
  "categories": ["Coffee", "Beverages", "Stimulants"],
  "questionIds": ["coffee_006", "coffee_007", "coffee_008"]
}
```

### Step 4 — Verify

After each sub-agent completes, run:

```bash
python3 -c "
import json
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

### Step 6 — Report to user

After all topics are done, print a summary table:

```
## Questions generated

| Topic       | Added | Sources                                      |
|-------------|-------|----------------------------------------------|
| coffee      |   5   | Coffee (3 q), Coffee preparation (2 q)       |
| tennis      |   5   | Tennis (4 q), general knowledge (1 q)        |
| adhd        |   8   | general knowledge (8 q) — network unavailable |
```

- List each Wikipedia article title used and how many questions came from it
- Mark any questions not backed by a fetched article as "general knowledge"
- If the network was down for the entire run, add a note: "⚠ Network was unreachable — all questions are from built-in knowledge and have no Wikipedia source."

---

## Token efficiency rules

1. **Sub-agents write to files directly** — never return large JSON blobs back to the main context
2. **Pass IDs only** for duplicate-checking, not full question text
3. **Sub-agents fetch full article text** — the main agent only runs `search_wiki.py`; article fetching and source material handling is the sub-agent's responsibility (no `--summary-only`)
4. **One sub-agent per topic** (not per article) — reduces agent spawning overhead
5. **Verify with a one-liner** — the bash python3 check above is cheaper than re-reading the file

---

## Example: expanding a single existing topic

User: `/generate-questions coffee`

1. Read `assets/questions/topics/coffee.json` → 5 questions, highest id `coffee_005`
2. Existing IDs: `coffee_001 … coffee_005`; need 5 more; start from `coffee_006`
3. Search: `python3 scripts/search_wiki.py "coffee" --results 5`
   → captures results; selects titles "Coffee" and "Coffee preparation"
4. Sub-agent receives titles → runs `fetch_wiki.py "Coffee"` and `fetch_wiki.py "Coffee preparation"` → generates 5 questions → writes to file → reports IDs + attribution
5. Update `assets/questions/sources/coffee.json`
6. Verify with one-liner
7. Commit: `content: add questions for beverages topics (coffee)`
8. Report:
   ```
   | coffee | 5 | Coffee (3 q), Coffee preparation (2 q) |
   ```

---

## Example: bulk update (multiple topics)

User: `/generate-questions mental_health category`

Topics in Mental Health: `therapy`, `adhd`, `autism`

1. Read all three files → note counts and existing IDs
2. Search for `therapy` → sub-agent fetches + writes → update sources → verify
3. Search for `adhd` → sub-agent fetches + writes → update sources → verify
4. Search for `autism` → sub-agent fetches + writes → update sources → verify
5. Commit: `content: expand mental_health questions (therapy, adhd, autism)`
6. Report table with per-topic article attribution

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

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

### Per-article output target

For each Wikipedia article loaded into context, produce:
- At least **1 question per difficulty level** (easy, medium, hard) = minimum 3
- Up to **5 questions per difficulty level** = maximum 15 per article
- Aim for variety: facts, dates, definitions, cause-and-effect, comparisons

---

## Topic hierarchy (3 levels)

Topics sit in a 3-level hierarchy defined in `lib/features/gameplay/data/topic_registry.dart`:

```
SuperCategory  (e.g. Health & Medicine)
  └── TopicCategory  (e.g. Mental Health)
        └── Topic  (e.g. ADHD)  ← topicId used in JSON
```

When handling **multiple topics**, group and sequence tasks by **TopicCategory** (Level 2) so that related articles are researched together before moving to the next category.

---

## Execution procedure

### Step 0 — Clarify scope (ask the user once)

Before starting, ask:
1. Which topic(s) to work on? (or "all thin topics" / a super-category name)
2. For each topic: how many Wikipedia articles to source? (default: 2 for existing topics, 4 for new topics)
3. Any articles the user wants to include specifically?

### Step 1 — Determine work items

For each topic in scope:
1. Read `assets/questions/topics/{topicId}.json` (or note it doesn't exist yet)
2. Note the current question count and the highest existing `id` suffix
3. Calculate how many questions are still needed to reach the target (default target: **30**)

Group topics by their **TopicCategory** (Level 2). Process one TopicCategory at a time.

### Step 2 — Research and generate (one sub-agent per article)

For each article to process, spawn **one sub-agent** with this task:

> "Fetch `{articleUrl}` via WebFetch. Read the full content. Then generate
> between 3 and 15 trivia questions (at least 1 per difficulty: easy/medium/hard,
> up to 5 per difficulty). All questions must be answerable from the article content.
> Return a JSON array following the schema below. topicId = `{topicId}`.
> Do not duplicate any of these existing questions: `{list_of_existing_questions}`."

Wait for the sub-agent to complete before spawning the next one.

### Step 3 — Validate output

Before writing, check each generated question:
- [ ] `id` is unique (not already in the file)
- [ ] `wrongAnswers` has ≥ 4 items
- [ ] `difficulty` is `easy`, `medium`, or `hard`
- [ ] `articleUrl` is the mobile Wikipedia URL fetched
- [ ] `funFact` is distinct from the question text

Fix any violations inline (don't skip the question).

### Step 4 — Write to file

Append the validated questions to `assets/questions/topics/{topicId}.json`.
If the topic file doesn't exist yet, create it as a new JSON array `[...]`.

Also add the new `topicId` to `_allTopicIds` in `question_repository.dart`
if it doesn't already appear there.

For a **brand-new topic**, also add it to `topic_registry.dart` under the
appropriate SuperCategory and TopicCategory (ask the user if unsure where it fits).

### Step 5 — Checkpoint commit

After completing each **TopicCategory group**, run:

```bash
export PATH="$PATH:/opt/flutter/bin"
git config --global --add safe.directory /opt/flutter
git add assets/questions/topics/ lib/features/gameplay/data/
git commit -m "content: add questions for {category} topics ({topicId}, {topicId}, ...)"
git push -u origin $(git branch --show-current)
```

Then continue to the next TopicCategory group.

---

## Example: expanding a single existing topic

User: `/generate-questions coffee — 2 articles`

1. Read `assets/questions/topics/coffee.json` → 5 existing questions, highest id `coffee_005`
2. Target: 30 questions → need 25 more
3. Source 2 articles: pick 2 Wikipedia URLs related to coffee not already covered
4. Sub-agent 1 → fetch first article → generate 10–15 questions → validate → append
5. Sub-agent 2 → fetch second article → generate 10–15 questions → validate → append
6. Commit: `content: add questions for coffee (coffee topic)`

---

## Example: seeding a new topic

User: `/generate-questions jazz — new topic, 4 articles`

1. Check `assets/questions/topics/jazz.json` → doesn't exist
2. Ask user: which TopicCategory should Jazz sit under? (e.g. Music & Arts → Music)
3. Add `Topic(id: 'jazz', ...)` to `topic_registry.dart`
4. Add `'jazz'` to `_allTopicIds` in `question_repository.dart`
5. Source 4 Wikipedia articles on jazz history, instruments, artists, theory
6. Process each article with one sub-agent sequentially
7. Create `assets/questions/topics/jazz.json` with all generated questions
8. Target: ≥ 30 questions before finishing
9. Commit after all 4 articles done

---

## Example: bulk update (multiple topics)

User: `/generate-questions mental_health category`

Topics in Mental Health: `therapy`, `adhd`, `autism`

Process in sequence:
1. All three topics → read current files → plan articles
2. `therapy` → sub-agent per article → write → (continue within same category)
3. `adhd` → sub-agent per article → write
4. `autism` → sub-agent per article → write
5. Commit: `content: expand mental_health questions (therapy, adhd, autism)`

Then move on if there are more categories requested.

---

## Notes

- **Never remove existing questions** — only append
- **No duplicate IDs** — always read the file first to find the current max suffix
- **Mobile Wikipedia URLs only** — `https://en.m.wikipedia.org/wiki/...`
- **One sub-agent at a time** — wait for completion before spawning the next
- **Commit after each TopicCategory** — prevents token-limit loss

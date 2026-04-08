# Plan: Question-Management Tooling for Mind Mazeish

## Context

The project has 35 topics and 256 questions (growing to 1–5k in alpha, >10k in beta). Questions start in per-topic JSON files and will migrate to an on-device SQLite database later. All schemas and IDs are designed for RDB compatibility from the start so that migration is a mechanical transformation, not a redesign.

The core hierarchy — SuperCategory → TopicCategory → Topic → Question — maps directly to four database tables. Sources become a fifth table. Facts (atomic knowledge units extracted from sources) become a sixth. WrongAnswers and CorrectAnswers normalise to join tables in the DB but stay as arrays in JSON for now.

Key design decisions driven by these constraints:
- Every entity has a stable, unique string PK (no auto-increment int that drifts between JSON and DB)
- Questions reference sources via `sourceId` (FK), not by duplicating title/url
- Sources have their own `id` field; facts within sources have their own `id` field
- Arrays (wrongAnswers, correctAnswers, facts) are clearly identified as future join tables
- Book sets and article text caching are built into the schema now, used by the app later

---

## Difficulty Criteria (canonical definitions — used by all skills)

These definitions must be included verbatim in every skill that generates or validates questions.

| Level | Criteria |
|-------|----------|
| **easy** | Widely known fact about a famous entity or landmark event. A casual fan of the topic would know it. Single-hop recall: "Who won…", "What is X called…", "In which country…" Single correct answer. |
| **medium** | Requires genuine interest in the topic. Comparative, numerical, or contextual: dates that aren't iconic, runner-up positions, technical terms, regional distinctions. Two-hop: "Which of these is NOT…", "How many times did X do Y…". **May have multiple correct answers** — e.g. "Which of these players reached the quarter-finals of the 2025 English Open?" where 2–3 of the options are valid. |
| **hard** | Obscure, specialist knowledge. Lesser-known entities, precise statistics, historical footnotes, technical processes. Requires domain expertise or deep reading. Rewarding to get right. **Frequently uses multiple correct answers** to increase ambiguity and reward nuanced knowledge — e.g. "Which of these are valid serves under Wimbledon rules?" |

**Multiple correct answers — how the game uses them:**
The game always presents one question and the player picks exactly one answer. When `correctAnswers` has > 1 item, the game randomly picks one to show as "the" correct option alongside 3 wrong answers. This means:
- The question wording must be satisfiable by any single correct answer in isolation
- "Select all that apply" framing must never be used — the player only picks one
- Two valid question styles when using multiple correct answers:

**Odd-one-out style** (always 1 correct answer — the exception):
> "Which of these players did NOT win a Grand Slam title in the 2010s?"
> `correctAnswers: ["Maria Sharapova"]`, `wrongAnswers: ["Serena Williams", "Angelique Kerber", ...]`

**Open-ended style** (1–3 correct answers — any one satisfies the question):
> "Name a player who reached the Wimbledon semi-finals in 2023."
> `correctAnswers: ["Aryna Sabalenka", "Ons Jabeur"]`, `wrongAnswers: ["Naomi Osaka", "Emma Raducanu", ...]`
> The game may show either Sabalenka or Jabeur as the correct option on any given playthrough.

- Easy questions: always 1 correct answer
- Medium questions: 1–2 correct answers; open-ended framing where natural
- Hard questions: 1–3 correct answers; both styles encouraged
- Wrong answers must be plausible against all possible displayed correct answers, not just one

**Variety rules (enforced by validate):**
- No two questions in the same topic may share more than 80% of their `correctAnswers` and use the same question structure
- A topic with ≥ 10 questions must have at least one of each difficulty level
- `wrongAnswers`: minimum 4, target 8–12, maximum 20 — more options = more replay variety
- Wrong answers must be plausible (same category, era, scale as the correct answer) — implausible distractors are a validation warning

---

## Data Schemas (RDB-compatible)

### Question (maps to `questions` table)

```json
{
  "id": "tennis_007",
  "question": "Which player holds the Open Era record for most Grand Slam singles titles?",
  "correctAnswers": ["Serena Williams"],
  "wrongAnswers": [
    "Steffi Graf", "Martina Navratilova", "Chris Evert", "Monica Seles",
    "Venus Williams", "Maria Sharapova", "Justine Henin", "Billie Jean King"
  ],
  "funFact": "Serena Williams won 23 Grand Slam singles titles in the Open Era, surpassing Steffi Graf's record of 22.",
  "sourceId": "src_serena_williams",
  "topicId": "tennis",
  "topicCategoryId": "sport",
  "superCategoryId": "sports_recreation",
  "difficulty": "easy"
}
```

**Removed fields** (replaced by `sourceId` FK): `articleTitle`, `articleUrl` — both are now on the Source object.
**Field order for all writes**: `id, question, correctAnswers, wrongAnswers, funFact, sourceId, topicId, topicCategoryId, superCategoryId, difficulty`

### Source (maps to `sources` table)

```json
{
  "id": "src_serena_williams",
  "title": "Serena Williams",
  "url": "https://en.m.wikipedia.org/wiki/Serena_Williams",
  "summary": "Serena Williams is an American professional tennis player...",
  "categories": ["Women's tennis", "Grand Slam champions"],
  "topicIds": ["tennis"],
  "articleText": null,
  "facts": [
    {
      "id": "fact_serena_001",
      "text": "Serena Williams won 23 Grand Slam singles titles in the Open Era.",
      "verified": true,
      "verifiedAt": "2026-04-07",
      "relatedQuestionIds": ["tennis_009", "tennis_034"]
    }
  ],
  "questionIds": ["tennis_009", "tennis_013", "tennis_016"]
}
```

**`id` format**: `src_{slug}` where slug is the Wikipedia article title lowercased, spaces→underscores, non-alphanumeric stripped. E.g., `"Serena Williams"` → `src_serena_williams`.
**`articleText`**: null initially; populated later by `relearn` for offline caching.
**`topicIds`**: array — a source can span multiple topics (e.g., a tennis history article used by both `tennis` and `medieval_history`).

### Fact (maps to `facts` join table / sub-object of Source)

```json
{
  "id": "fact_serena_001",
  "text": "Serena Williams won 23 Grand Slam singles titles in the Open Era.",
  "verified": true,
  "verifiedAt": "2026-04-07",
  "relatedQuestionIds": ["tennis_009", "tennis_034"]
}
```

**`id` format**: `fact_{source_slug}_{NNN}` — unique within the source; globally unique by convention.

### Book Set (maps to future `book_sets` table)

Stored in `assets/questions/book_sets/{superCategoryId}.json` (array of sets).

```json
{
  "id": "bs_youngest_grand_slam_winners",
  "name": "Youngest Grand Slam Winners",
  "summary": "Sources tracing the youngest players to win Grand Slam titles across generations, from Martina Hingis to Coco Gauff.",
  "superCategoryId": "sports_recreation",
  "topicCategoryIds": ["sport"],
  "topicIds": ["tennis"],
  "sourceIds": ["src_martina_hingis", "src_coco_gauff", "src_youngest_grand_slam_singles_champions"],
  "createdAt": "2026-04-07"
}
```

---

## Order of Operations

1. `export_registry.py` → `registry.json`
2. `migrate_questions.py` — rename `articleTitle`/`articleUrl` → `sourceId`; add `topicCategoryId`, `superCategoryId`; add source IDs to sources files
3. `sync_sources.py` — rebuild `questionIds` in all sources files
4. Scripts: `audit_questions.py`, `validate_questions.py`
5. Update `generate-questions/SKILL.md`
6. Write `audit-questions/SKILL.md`
7. Write `add-topic/SKILL.md`
8. Write `relearn/SKILL.md`
9. Write `research-rabbit/SKILL.md`
10. Run migration scripts, verify, commit

---

## Scripts

All scripts live in `.claude/skills/generate-questions/scripts/` unless noted.
All scripts: validate CWD (`assets/questions/topics` must exist), write JSON with `indent=2, ensure_ascii=False` + trailing newline, errors → stderr, reports → stdout, `--topic TOPIC_ID` flag where applicable.

---

### `export_registry.py`

Parses `lib/features/gameplay/data/topic_registry.dart` via bracket-depth counting. Outputs `.claude/skills/generate-questions/data/registry.json`.

Key function — `extract_constructor_bodies(source, name)`:
- Scans for `name(`, tracks `()` depth, extracts body text
- SC bodies → within each, TC bodies → within each, Topic lines (single-line regex)

Topic regex: `r"Topic\(id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*categoryId:\s*'([^']+)',\s*emoji:\s*'([^']+)'\)"`

Output: `{ "superCategories": [...], "topicMap": { topicId: { superCategoryId, superCategoryName, topicCategoryId, topicCategoryName, name, emoji } } }`

Asserts 35 topics. Must be re-run whenever `topic_registry.dart` changes.

---

### `migrate_questions.py` *(replaces `enrich_questions.py`)*

One-time + idempotent migration. Handles all schema changes in one pass:

**Per question:**
1. If `articleTitle` / `articleUrl` present: derive `sourceId` = `src_{slugify(articleTitle)}`. Set `sourceId`. Remove `articleTitle`, `articleUrl`.
2. If `sourceId` already present and neither old field exists: skip (idempotent).
3. Add `topicCategoryId`, `superCategoryId` from `registry.json` if missing.
4. Rewrite question with canonical field order.

**Per sources file:**
1. For each source entry missing an `id`: derive and set `id` = `src_{slugify(title)}`.
2. Add `articleText: null` if missing.
3. Add `facts: []` if missing.
4. Add `topicIds: [topicId]` if missing (merge if already present).
5. Rewrite with canonical field order: `id, title, url, summary, categories, topicIds, articleText, facts, questionIds`.

Flags: `--topic TOPIC_ID`, `--dry-run`

`slugify(title)`: lowercase, replace spaces with `_`, strip non-`[a-z0-9_]`.

---

### `sync_sources.py`

Bidirectional sync between questions and sources files. Rebuilds `questionIds` from actual question data.

Per topic:
1. Build `{sourceId: [questionIds]}` index from all questions with a non-empty `sourceId`
2. Load sources file (or `[]`)
3. For each sourceId in index: find matching source entry by `id`, update `questionIds` (sorted), or create stub entry
4. Orphaned entries (in sources but no question references): warn, keep unless `--remove-orphans`
5. Write sorted by `title`; print added/updated/orphaned report

Flags: `--topic TOPIC_ID`, `--remove-orphans`, `--dry-run`

---

### `audit_questions.py`

Full health report, hierarchy-structured.

Per topic metrics: total, difficulty spread, health (`thin` < 10, `ok` 10–29, `full` ≥ 30), sources file exists, facts count, avg wrong answers count.

Rolled up per TopicCategory and SuperCategory.

Issues flagged:
- Thin topics (< 10 q)
- Missing sources files
- No difficulty variety (all same level, topic ≥ 3 q)
- Low wrong answer counts (avg < 6 — replay concern)
- Topics with 0 facts in sources

Output format (ASCII, ~70 cols):
```
======================================================================
MIND MAZEISH TRIVIA — Question Audit
======================================================================
[SPORTS & RECREATION] 🎾  total: 38 q  facts: 12
  easy:12  medium:17  hard:9

  [Sport]
    tennis  36 q  easy:11 med:16 hard:9  [FULL]  src:YES  facts:12
  [Games & Puzzles]
    puzzles  5 q  easy:1 med:3 hard:2  [THIN]  src:NO  facts:0  ⚠
...

======================================================================
GLOBAL SUMMARY
  Total: 256 q  |  easy:82  medium:104  hard:70
  Sources: 1/35 topics have sources files
  Facts: 12 total across 1 source
  full(≥30): 2  |  ok(10-29): 8  |  thin(<10): 25
  Avg wrong answers: 6.2 (target: 8–12)

ISSUES (30)
  ⚠ 25 topics THIN (< 10 q)
  ⚠ 34 topics have no sources file
  ⚠ 3 topics have no difficulty variety
  ⚠ 12 topics avg < 6 wrong answers
======================================================================
```

Always exits 0.

---

### `validate_questions.py`

Deep validation. Collects all violations, exits 0 (pass) or 1 (violations).

**Per question:**
- Required fields: `id, question, correctAnswers, wrongAnswers, funFact, sourceId, topicId, topicCategoryId, superCategoryId, difficulty`
- `id` format: `r'^[a-z_]+_\d{3}$'`
- `id` unique within topic AND globally
- `correctAnswers` not in `wrongAnswers`
- `wrongAnswers` count ≥ 4; warn if < 6
- `difficulty` in `{easy, medium, hard}`
- `sourceId` either empty string OR matches an entry `id` in `sources/{topicId}.json`
- `topicId` matches filename stem
- `topicCategoryId` / `superCategoryId` match `registry.json` for this topic

**Per topic:**
- If ≥ 10 questions: must have all three difficulty levels
- No two questions share > 80% of `correctAnswers` with identical question structure (similarity check)

**Sources cross-check:**
- Every non-empty `sourceId` resolves to an entry in the sources file
- Every `questionId` in sources exists in the question file
- Every fact `id` is unique within its source

Flags: `--topic TOPIC_ID`, `--strict` (treats warnings as errors)

---

## Skills

---

### `generate-questions` SKILL.md — Updates

**Fix stale paths** (3 occurrences): `.claude/generate-questions/scripts/` → `.claude/skills/generate-questions/scripts/`

**Updated question schema** — add `sourceId`, remove `articleTitle`/`articleUrl`, add `topicCategoryId`/`superCategoryId`, expand wrongAnswers guidance:
```json
{
  "id": "coffee_006",
  "question": "...",
  "correctAnswers": ["Ethiopia"],
  "wrongAnswers": ["Yemen", "Brazil", "Colombia", "Turkey", "Indonesia", "India", "Vietnam", "Mexico"],
  "funFact": "...",
  "sourceId": "src_history_of_coffee",
  "topicId": "coffee",
  "topicCategoryId": "beverages",
  "superCategoryId": "food_drink",
  "difficulty": "easy"
}
```

**Add facts-mode** (Step 0 clarification): Agent asks whether to generate from Wikipedia (default) or from existing source facts. In facts mode, sub-agents read `assets/questions/sources/{topicId}.json`, use the `facts` array as primary input, and set `sourceId` to the fact's source ID.

**Add difficulty criteria** block (verbatim from this plan's Difficulty Criteria section).

**Add wrongAnswers guidance**: target 8–12 wrong answers, max 20.

**Step 3.5**: replace manual sources block with:
```bash
python3 .claude/skills/generate-questions/scripts/sync_sources.py --topic {topicId}
```

**Step 4**: replace one-liner with:
```bash
python3 .claude/skills/generate-questions/scripts/validate_questions.py --topic {topicId}
```

---

### `audit-questions/SKILL.md` *(new)*

Steps:
1. Run `audit_questions.py` → display full output
2. Run `validate_questions.py` → display violations report
3. Synthesise prioritised action plan:
   - CRITICAL: structural validation errors (fix before anything else)
   - HIGH: thin topics sorted by count ascending
   - MEDIUM: missing sources / facts / sources sync issues
   - LOW: variety warnings (difficulty spread, wrong answer counts)
4. Offer to invoke `generate-questions` for the N thinnest topics (user specifies N, default 5)

Modular inputs: accepts `--topic`, `--category`, `--super-category` to scope the audit.

---

### `add-topic/SKILL.md` *(new)*

Steps:
0. Gather: `topicId`, name, emoji, SuperCategory, TopicCategory (or create new category)
1. Validate: not in registry, not in topics dir, matches `r'^[a-z][a-z0-9_]*$'`
2. Edit `topic_registry.dart` — append `Topic(...)` to correct category
3. Edit `question_repository.dart` — add `'{topicId}',` to `_allTopicIds` (alphabetical)
4. Create `assets/questions/topics/{topicId}.json` → `[]`
5. Create `assets/questions/sources/{topicId}.json` → `[]`
6. Run `export_registry.py` — confirm topic appears
7. Invoke `generate-questions` (target: 30 questions)
8. Run `sync_sources.py --topic {topicId}`
9. Run `validate_questions.py --topic {topicId}` — fix any violations
10. Commit: `topic_registry.dart`, `question_repository.dart`, topic json, sources json, `registry.json`

---

### `relearn/SKILL.md` *(new)*

Two modes (user selects):

**Mode A — Extract facts from article:**
For a given `sourceId` (or list):
1. Read source entry from `assets/questions/sources/{topicId}.json`
2. Run `fetch_wiki.py "{title}"` to get current article text
3. Agent reads full text alongside existing facts; extracts new atomic facts not already present
4. Assigns each new fact an ID: `fact_{source_slug}_{NNN}` counting from current max
5. Appends new facts to `source.facts[]`; marks `verified: true, verifiedAt: {today}`
6. Optionally caches full article text in `source.articleText` (flag: `--cache-text`)
7. For existing facts: re-verifies each against current article text; sets `verified: false` on any that contradict current article; adds a `verificationNote`
8. Writes updated sources file

**Mode B — Cross-reference related sources:**
Given a list of sourceIds (or a book set id):
1. Loads all specified source entries (summary + facts only — not full articles)
2. Agent compares facts across sources, identifies: contradictions, corroborations, gaps
3. For gaps (fact implied by one source but not recorded in another): proposes new facts for human review before writing
4. For contradictions: flags them as `verified: false` with a `verificationNote` citing the conflicting source
5. Writes updated sources files; prints cross-reference report

Modular: accepts sourceIds from stdin (pipe-friendly), from a book set file, or as CLI args.

---

### `research-rabbit/SKILL.md` *(new)*

Finds related Wikipedia sources for a topic/category and groups them into named book sets. **Light — uses summaries only, no full article fetches.**

Steps:
0. Gather: scope (topicId, topicCategoryId, or superCategoryId), optional search hint string
1. Load all existing sourceIds for the scope from sources files — skip re-searching these
2. For each topic in scope: run `search_wiki.py "{topicName}" --results 8`
   - Also run searches for adjacent angles: `"{topicName} history"`, `"{topicName} records"`, etc.
   - Collect all results (title, summary, url) — deduplicate by url
3. Agent reads summaries (only) and groups sources into thematic clusters:
   - Each cluster becomes a candidate book set
   - Name each cluster with a descriptive title (the "meta topic" it represents)
   - Write a 2–3 sentence summary of what story the cluster tells
4. For each book set: create/update entry in `assets/questions/book_sets/{superCategoryId}.json`
5. New source stubs (sources found but not yet in any sources file): write stub entries to the relevant `assets/questions/sources/{topicId}.json` with `summary`, `url`, `title`, `facts: []`, `questionIds: []`, `articleText: null`
6. Print report: N book sets created/updated, M new source stubs added

**Book set file location**: `assets/questions/book_sets/{superCategoryId}.json`
**Book set schema**: see Data Schemas section above.

Modularity: can accept a list of source stubs via stdin (output of `search_wiki.py`) to allow chaining.

---

## Files to Create / Modify Summary

| File | Action |
|------|--------|
| `.claude/skills/generate-questions/data/registry.json` | Create (generated) |
| `.claude/skills/generate-questions/scripts/export_registry.py` | Create |
| `.claude/skills/generate-questions/scripts/migrate_questions.py` | Create |
| `.claude/skills/generate-questions/scripts/sync_sources.py` | Create |
| `.claude/skills/generate-questions/scripts/audit_questions.py` | Create |
| `.claude/skills/generate-questions/scripts/validate_questions.py` | Create |
| `.claude/skills/generate-questions/SKILL.md` | Modify |
| `.claude/skills/audit-questions/SKILL.md` | Create |
| `.claude/skills/add-topic/SKILL.md` | Create |
| `.claude/skills/relearn/SKILL.md` | Create |
| `.claude/skills/research-rabbit/SKILL.md` | Create |
| `assets/questions/topics/*.json` (35 files) | Migrate via script |
| `assets/questions/sources/*.json` (35 files) | Migrate via script |
| `assets/questions/book_sets/` | Create directory + files (via research-rabbit) |
| `CLAUDE.md` | Update skills list |

---

## Common Script Conventions

- CWD guard: `if not Path("assets/questions/topics").is_dir(): sys.exit("Run from project root")`
- JSON writes: `json.dump(..., indent=2, ensure_ascii=False)` + `"\n"`
- stderr for errors; stdout for reports
- Exit codes: 0 = success, 1 = violations found, 3 = network unavailable
- `argparse` throughout; `--topic TOPIC_ID`, `--dry-run`, `--strict` consistent across all scripts
- Pipe-friendly where noted (accept stdin, produce stdout usable by next script)

---

## Verification

```bash
# 1. Export registry
python3 .claude/skills/generate-questions/scripts/export_registry.py
# Expected: "Exported 9 superCategories, 18 topicCategories, 35 topics"

# 2. Migrate all questions and sources
python3 .claude/skills/generate-questions/scripts/migrate_questions.py
# Expected: "Migrated 256 questions across 35 files. 1 sources file updated."

# 3. Spot-check question schema
python3 -c "import json; q=json.load(open('assets/questions/topics/tennis.json'))[6]; print(list(q.keys()))"
# Expected: ['id','question','correctAnswers','wrongAnswers','funFact','sourceId','topicId','topicCategoryId','superCategoryId','difficulty']

# 4. Spot-check source schema
python3 -c "import json; s=json.load(open('assets/questions/sources/tennis.json'))[0]; print(s.get('id'), list(s.keys()))"
# Expected: src_womens_tennis ['id','title','url','summary','categories','topicIds','articleText','facts','questionIds']

# 5. Sync sources (rebuilds questionIds for all 35 topics)
python3 .claude/skills/generate-questions/scripts/sync_sources.py
# Expected: 34 topics with new/updated source stubs

# 6. Validate (expect 0 hard violations; sourceId warnings for knowledge-only questions are OK)
python3 .claude/skills/generate-questions/scripts/validate_questions.py
# Expected: exit 0 or only warnings

# 7. Audit
python3 .claude/skills/generate-questions/scripts/audit_questions.py
# Expected: full hierarchy report, 25 thin topics flagged
```

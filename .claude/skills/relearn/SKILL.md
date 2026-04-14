---
name: relearn
description: Extract new facts from Wikipedia articles into source entries, or cross-reference facts across related sources. Use to enrich the sources knowledge base before generating more questions.
metadata:
  author: ariwoode
  version: "1.1"
---

# relearn

Two modes — user selects:

## Mode A — Extract facts from article

### Fast path (bulk)

For known topics in the TOPICS list, run the script directly — no sub-agents or file reading required:

```bash
python3 .claude/skills/generate-questions/scripts/relearn.py [topicId ...]
# Omit topic IDs to process all known topics
```

The script fetches each article, calls `claude -p` to extract facts, and writes them back to the sources file.

### Manual path (targeted)

For a sourceId not in the TOPICS list, or when AI judgment is needed during extraction.

**For multiple sourceIds: spawn one sub-agent per topic, in sequence.** Wait for each to complete before spawning the next. Sub-agents write directly to files — never return JSON blobs to the main context.

#### Step 1 — Identify source title and existing facts

Read `assets/questions/sources/{topicId}.json`. Note the `title` and `facts` fields for `{sourceId}`.

#### Step 2 — Fetch article text and cache it

```bash
python3 .claude/skills/generate-questions/scripts/fetch_wiki.py "{title}" \
  | tee /tmp/wiki_{slug}.txt
python3 .claude/skills/generate-questions/scripts/save_sources.py \
  --topic {topicId} --source-id {sourceId} --article-text < /tmp/wiki_{slug}.txt
```

The `tee` output is the article text — use it for Steps 3–4.
`save_sources.py` caches it to `articleText` (skips if already set).
If `fetch_wiki.py` exits 3 (network down): abort, suggest Mode B with existing facts.

#### Step 3 — Extract new facts and save

From the article text, compose a JSON array of fact objects for each atomic fact not already in `source.facts`. Then pipe to `save_sources.py`:

```bash
echo '<json array>' | python3 .claude/skills/generate-questions/scripts/save_sources.py \
  --topic {topicId} --source-id {sourceId} --facts
```

Fact object shape:
```json
{"id": "fact_{source_slug}_{NNN}", "text": "...", "verified": true, "verifiedAt": "{today ISO date}"}
```
Count `{NNN}` from the current max in `source.facts`. The script merges by id — new facts are appended, existing ones updated.

#### Step 4 — Re-verify existing facts

For each existing fact contradicted by the current article, pipe an updated array with those facts set to `verified: false` and a `verificationNote`:

```bash
echo '<json array of updated facts>' | python3 .claude/skills/generate-questions/scripts/save_sources.py \
  --topic {topicId} --source-id {sourceId} --facts
```

Only include the facts that changed — the script merges by id.

---

## Mode B — Cross-reference related sources

For a list of sourceIds (or a book set id):

### Step 1 — Load all specified source entries

Read `summary` and `facts` only — do not load `articleText` (too large).

### Step 2 — Compare across sources

Identify:
- **Contradictions**: fact A in source 1 contradicts fact B in source 2
- **Corroborations**: same fact confirmed by multiple sources
- **Gaps**: fact implied by one source but not recorded in another

### Step 3 — Handle findings

**Contradictions**: mark both facts `verified: false` with a `verificationNote` citing the conflicting source.

**Gaps**: propose new facts to the user for review before writing.

### Step 4 — Write updated sources files

For contradictions and approved gap facts, use `save_sources.py --facts` per source:
```bash
echo '<json array>' | python3 .claude/skills/generate-questions/scripts/save_sources.py \
  --topic {topicId} --source-id {sourceId} --facts
```

Print cross-reference report: contradictions found, facts added, sources updated.

---

## Modular inputs

Accepts sourceIds:
- As skill arguments (space-separated)
- From a book set file: `assets/questions/book_sets/{superCategoryId}.json`
- From stdin (pipe-friendly)

---

## Token efficiency rules
1. **Bulk runs → use `relearn.py`** — not sub-agents
2. **Multiple sourceIds (manual) → one sub-agent per topic, in sequence** — write to files directly, never return JSON blobs; no parallel agents
3. **Mode B → load only `summary` and `facts`**, never `articleText`
4. Verify writes by exit code, not by re-reading the file

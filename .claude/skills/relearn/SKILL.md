---
name: relearn
description: Extract new facts from Wikipedia articles into source entries, or cross-reference facts across related sources. Use to enrich the sources knowledge base before generating more questions.
metadata:
  author: ariwoode
  version: "1.0"
---

# relearn

Two modes — user selects:

## Mode A — Extract facts from article

For a given `sourceId` (or list of sourceIds):

### Step 1 — Load source entry

Read the source from `assets/questions/sources/{topicId}.json`. Identify `title` and existing `facts`.

### Step 2 — Fetch current article text

```bash
python3 .claude/skills/generate-questions/scripts/fetch_wiki.py "{title}"
```

If exit 3 (network down): abort Mode A, suggest Mode B with existing facts.

### Step 3 — Extract new facts

Read the full article text. For each atomic fact not already recorded in `source.facts`:
- Create a new fact entry with ID `fact_{source_slug}_{NNN}` (counting from current max)
- Set `verified: true`, `verifiedAt: {today ISO date}`
- Append to `source.facts[]`

### Step 4 — Re-verify existing facts

For each existing fact, check it against the current article. If contradicted:
- Set `verified: false`
- Add `verificationNote: "Contradicted by current article as of {date}"`

### Step 5 — Optionally cache article text

If `--cache-text` flag set: write full article text to `source.articleText`.

### Step 6 — Write updated sources file

---

## Mode B — Cross-reference related sources

For a list of sourceIds (or a book set id):

### Step 1 — Load all specified source entries

Read `summary` and `facts` only — do not fetch full articles.

### Step 2 — Compare across sources

Identify:
- **Contradictions**: fact A in source 1 contradicts fact B in source 2
- **Corroborations**: same fact confirmed by multiple sources
- **Gaps**: fact implied by one source but not recorded in another

### Step 3 — Handle findings

**Contradictions**: mark both facts `verified: false` with a `verificationNote` citing the conflicting source.

**Gaps**: propose new facts to the user for review before writing.

### Step 4 — Write updated sources files

Print cross-reference report: contradictions found, facts added, sources updated.

---

## Modular inputs

Accepts sourceIds:
- As skill arguments (space-separated)
- From a book set file: `assets/questions/book_sets/{superCategoryId}.json`
- From stdin (pipe-friendly)

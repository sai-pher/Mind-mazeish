---
name: research-rabbit
description: Find related Wikipedia sources for a topic or category, group them into named book sets, and create source stubs. Light — uses summaries only, no full article fetches.
metadata:
  author: ariwoode
  version: "1.0"
---

# research-rabbit

Discovers related Wikipedia sources and organises them into thematic book sets. **Light — summaries only, no full article fetches.**

## Step 0 — Gather scope

Ask the user (or read from context):
- Scope: `topicId`, `topicCategoryId`, or `superCategoryId`
- Optional: search hint string (e.g. "history", "records", "technique")

## Step 1 — Load existing sourceIds

Read all sources files for the scope to avoid re-searching known sources.

## Step 2 — Search Wikipedia

For each topic in scope:

```bash
python3 .claude/skills/generate-questions/scripts/search_wiki.py "{topicName}" --results 8
python3 .claude/skills/generate-questions/scripts/search_wiki.py "{topicName} history" --results 5
python3 .claude/skills/generate-questions/scripts/search_wiki.py "{topicName} records" --results 5
```

If exit 3 (network down): abort and report.

Collect all results (title, summary, url). Deduplicate by URL. Skip sources already in the sources files.

## Step 3 — Cluster into book sets

Read summaries only. Group sources into thematic clusters where each cluster:
- Has a descriptive name (the "meta topic" it represents)
- Has a 2–3 sentence summary of what story the cluster tells
- Contains 3–8 related sources

## Step 4 — Write book sets

For each cluster, create/update entry in `assets/questions/book_sets/{superCategoryId}.json`:

```json
{
  "id": "bs_{slug}",
  "name": "{Descriptive cluster name}",
  "summary": "{2–3 sentences describing what story this set tells}",
  "superCategoryId": "{superCategoryId}",
  "topicCategoryIds": ["{topicCategoryId}"],
  "topicIds": ["{topicId}"],
  "sourceIds": ["{src_id}", ...],
  "createdAt": "{ISO date}"
}
```

## Step 5 — Write source stubs

For each new source (not yet in any sources file), write a stub entry to `assets/questions/sources/{topicId}.json`:

```json
{
  "id": "src_{slug}",
  "title": "{Wikipedia article title}",
  "url": "{Wikipedia mobile URL}",
  "summary": "{summary from search result}",
  "categories": [],
  "topicIds": ["{topicId}"],
  "articleText": null,
  "facts": [],
  "questionIds": []
}
```

## Step 6 — Report

```
N book sets created/updated
M new source stubs added to sources files
Topics covered: {list}
```

## Modularity

Accepts source stubs from stdin (output of `search_wiki.py`) to allow chaining:
```bash
python3 .claude/skills/generate-questions/scripts/search_wiki.py "tennis" | # pipe to relearn or research-rabbit
```

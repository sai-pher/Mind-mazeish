# generate-questions: Examples & New-Topic Guide

## Example: expanding a single existing topic

User: `/generate-questions coffee`

1. Read `assets/questions/topics/coffee.json` → 5 questions, highest id `coffee_005`
2. Existing IDs: `coffee_001 … coffee_005`; need 5 more; start from `coffee_006`
3. Search: `python3 scripts/search_wiki.py "coffee" --results 5`
   → selects "Coffee" and "Coffee preparation"
4. Sub-agent receives titles → runs `fetch_wiki.py "Coffee"` and `fetch_wiki.py "Coffee preparation"` → generates 5 questions → appends to file → reports IDs + attribution
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
2. Search `therapy` → sub-agent fetches + writes → update sources → verify
3. Search `adhd` → sub-agent fetches + writes → update sources → verify
4. Search `autism` → sub-agent fetches + writes → update sources → verify
5. Commit: `content: expand mental_health questions (therapy, adhd, autism)`
6. Report table with per-topic article attribution

---

## Adding a brand-new topic

1. Check `assets/questions/topics/{topicId}.json` → doesn't exist yet
2. Ask user: which TopicCategory should it sit under?
3. Add `Topic(id: '{topicId}', ...)` to `lib/features/gameplay/data/topic_registry.dart`
4. Add `'{topicId}'` to `_allTopicIds` in `lib/features/gameplay/data/question_repository.dart`
5. Sub-agent creates the file with ≥ 30 questions
6. Commit after all topics done

---

## Notes
- **Never remove existing questions** — only append
- **No duplicate IDs** — always read the file first to find the current max suffix
- **Mobile Wikipedia URLs only** — `https://en.m.wikipedia.org/wiki/...`
- **One sub-agent at a time** — wait for completion before spawning the next
- **Commit after each TopicCategory** — prevents token-limit loss

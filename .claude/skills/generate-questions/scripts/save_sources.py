#!/usr/bin/env python3
"""
save_sources.py — Upsert search results or article text into a topic sources file.

Usage:
    # Upsert search results (pipe from search_wiki.py):
    python3 search_wiki.py "coffee" --results 5 | \\
        python3 save_sources.py --topic coffee

    # Save article text to an existing source entry:
    python3 fetch_wiki.py "Coffee" | \\
        python3 save_sources.py --topic coffee --source-id src_coffee --article-text

Exit code 0 on success, 1 on error.
"""

import argparse
import json
import re
import sys
from pathlib import Path

SOURCES_DIR = Path('assets/questions/sources')

SOURCE_FIELD_ORDER = [
    'id', 'title', 'url', 'summary', 'categories',
    'topicIds', 'articleText', 'facts', 'questionIds',
]


def slugify(title: str) -> str:
    # Normalise accented characters before stripping (é → e, ü → u, etc.)
    import unicodedata
    normalised = unicodedata.normalize('NFKD', title).encode('ascii', 'ignore').decode('ascii')
    return re.sub(r'[^a-z0-9]+', '_', normalised.lower()).strip('_')


def reorder(d: dict) -> dict:
    ordered = {k: d[k] for k in SOURCE_FIELD_ORDER if k in d}
    extras = {k: v for k, v in d.items() if k not in SOURCE_FIELD_ORDER}
    return {**ordered, **extras}


def load_sources(topic_id: str) -> list[dict]:
    path = SOURCES_DIR / f'{topic_id}.json'
    if path.exists():
        return json.loads(path.read_text(encoding='utf-8'))
    return []


def write_sources(topic_id: str, entries: list[dict]) -> None:
    SOURCES_DIR.mkdir(parents=True, exist_ok=True)
    path = SOURCES_DIR / f'{topic_id}.json'
    sorted_entries = sorted(
        [reorder(e) for e in entries],
        key=lambda e: e.get('title', '').lower(),
    )
    path.write_text(json.dumps(sorted_entries, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')


def upsert_search_results(topic_id: str, results: list[dict]) -> None:
    entries = load_sources(topic_id)
    entry_map = {e['id']: e for e in entries if e.get('id')}

    for result in results:
        source_id = f'src_{slugify(result["title"])}'
        if source_id not in entry_map:
            entry_map[source_id] = {
                'id': source_id,
                'title': '',
                'url': '',
                'summary': '',
                'categories': [],
                'topicIds': [],
                'articleText': None,
                'facts': [],
                'questionIds': [],
            }
        entry = entry_map[source_id]
        # Only fill empty/missing fields — never overwrite existing values
        if not entry.get('title'):
            entry['title'] = result.get('title', '')
        if not entry.get('url'):
            entry['url'] = result.get('url', '')
        if not entry.get('summary'):
            entry['summary'] = result.get('summary', '')
        if not entry.get('categories'):
            entry['categories'] = result.get('categories', [])
        topic_ids = entry.setdefault('topicIds', [])
        if topic_id not in topic_ids:
            topic_ids.append(topic_id)

    write_sources(topic_id, list(entry_map.values()))
    print(f'Saved {len(results)} source stub(s) to {topic_id}.json')


def save_facts(topic_id: str, source_id: str, facts: list[dict]) -> None:
    """Merge facts into source entry. Existing facts (matched by id) are updated;
    new facts are appended."""
    entries = load_sources(topic_id)
    entry_map = {e['id']: e for e in entries if e.get('id')}

    if source_id not in entry_map:
        print(f'WARNING: {source_id!r} not found in {topic_id}.json — skipping', file=sys.stderr)
        return

    entry = entry_map[source_id]
    existing = {f['id']: f for f in entry.get('facts', []) if f.get('id')}

    added = updated = 0
    for fact in facts:
        fid = fact.get('id')
        if not fid:
            continue
        if fid in existing:
            existing[fid].update(fact)
            updated += 1
        else:
            existing[fid] = fact
            added += 1

    entry['facts'] = list(existing.values())
    write_sources(topic_id, list(entry_map.values()))
    print(f'Saved facts to {source_id} in {topic_id}.json ({added} added, {updated} updated)')


def save_article_text(topic_id: str, source_id: str, text: str) -> None:
    entries = load_sources(topic_id)
    entry_map = {e['id']: e for e in entries if e.get('id')}

    if source_id not in entry_map:
        print(f'WARNING: {source_id!r} not found in {topic_id}.json — skipping', file=sys.stderr)
        return

    entry = entry_map[source_id]
    if not entry.get('articleText'):
        entry['articleText'] = text
        write_sources(topic_id, list(entry_map.values()))
        print(f'Saved articleText to {source_id} in {topic_id}.json')
    else:
        print(f'articleText already set for {source_id} — skipping')


def main() -> None:
    if not Path('assets').is_dir():
        sys.exit('Run from project root')

    parser = argparse.ArgumentParser(description='Write Wikipedia data to a topic sources file.')
    parser.add_argument('--topic', required=True, metavar='TOPIC_ID')
    parser.add_argument('--source-id', metavar='SOURCE_ID',
                        help='Entry to update (required with --article-text and --facts)')
    parser.add_argument('--article-text', action='store_true',
                        help='Read article text from stdin and save to --source-id')
    parser.add_argument('--facts', action='store_true',
                        help='Read JSON array of fact objects from stdin and merge into --source-id')
    args = parser.parse_args()

    if args.article_text:
        if not args.source_id:
            sys.exit('--source-id is required with --article-text')
        text = sys.stdin.read().strip()
        if not text:
            sys.exit('No article text on stdin')
        save_article_text(args.topic, args.source_id, text)
    elif args.facts:
        if not args.source_id:
            sys.exit('--source-id is required with --facts')
        try:
            facts = json.loads(sys.stdin.read())
        except json.JSONDecodeError as e:
            sys.exit(f'Invalid JSON on stdin: {e}')
        if not isinstance(facts, list):
            sys.exit('Expected a JSON array of fact objects on stdin')
        save_facts(args.topic, args.source_id, facts)
    else:
        try:
            results = json.loads(sys.stdin.read())
        except json.JSONDecodeError as e:
            sys.exit(f'Invalid JSON on stdin: {e}')
        if not isinstance(results, list):
            sys.exit('Expected a JSON array on stdin')
        upsert_search_results(args.topic, results)


if __name__ == '__main__':
    main()

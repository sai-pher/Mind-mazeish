#!/usr/bin/env python3
"""
sync_sources.py — Rebuild questionIds in all sources files from actual question data.

For each topic:
  1. Build {sourceId: [questionIds]} index from questions with a non-empty sourceId
  2. Load existing sources file (or start with [])
  3. For each sourceId in index: find matching source entry by id, update questionIds (sorted),
     or create a stub entry
  4. Orphaned entries (in sources but not referenced by any question): warn, keep unless --remove-orphans
  5. Write sorted by title

Usage:
  python3 .claude/skills/generate-questions/scripts/sync_sources.py [--topic TOPIC_ID] [--remove-orphans] [--dry-run]
"""

import argparse
import json
import sys
from pathlib import Path

TOPICS_DIR = Path('assets/questions/topics')
SOURCES_DIR = Path('assets/questions/sources')

SOURCE_FIELD_ORDER = [
    'id', 'title', 'url', 'summary', 'categories',
    'topicIds', 'articleText', 'facts', 'questionIds',
]


def reorder(d, field_order):
    ordered = {k: d[k] for k in field_order if k in d}
    extras = {k: v for k, v in d.items() if k not in field_order}
    return {**ordered, **extras}


def make_stub(source_id, topic_id):
    return reorder({
        'id': source_id,
        'title': source_id.removeprefix('src_').replace('_', ' ').title(),
        'url': '',
        'summary': '',
        'categories': [],
        'topicIds': [topic_id],
        'articleText': None,
        'facts': [],
        'questionIds': [],
    }, SOURCE_FIELD_ORDER)


def write_json(path, data, dry_run):
    text = json.dumps(data, indent=2, ensure_ascii=False) + '\n'
    if dry_run:
        print(f'  [dry-run] would write {path}')
    else:
        SOURCES_DIR.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding='utf-8')


def sync_topic(topic_id, remove_orphans, dry_run):
    topic_file = TOPICS_DIR / f'{topic_id}.json'
    if not topic_file.exists():
        return 0, 0, 0

    questions = json.loads(topic_file.read_text(encoding='utf-8'))

    # Build sourceId → questionIds index
    index: dict[str, list[str]] = {}
    for q in questions:
        sid = q.get('sourceId', '').strip()
        if sid:
            index.setdefault(sid, []).append(q['id'])

    if not index:
        return 0, 0, 0  # no sourced questions — nothing to sync

    # Load existing sources
    sources_file = SOURCES_DIR / f'{topic_id}.json'
    if sources_file.exists():
        entries = json.loads(sources_file.read_text(encoding='utf-8'))
    else:
        entries = []

    # Build id → entry map
    entry_map = {e.get('id', ''): e for e in entries if e.get('id')}
    referenced_ids = set(index.keys())

    added = updated = orphaned = 0

    for source_id, question_ids in sorted(index.items()):
        if source_id in entry_map:
            entry_map[source_id]['questionIds'] = sorted(question_ids)
            updated += 1
        else:
            stub = make_stub(source_id, topic_id)
            stub['questionIds'] = sorted(question_ids)
            entry_map[source_id] = stub
            added += 1

    # Orphaned entries
    for entry_id in list(entry_map.keys()):
        if entry_id not in referenced_ids:
            print(f'  ⚠ orphaned source {entry_id!r} in {topic_id} (no questions reference it)',
                  file=sys.stderr)
            orphaned += 1
            if remove_orphans:
                del entry_map[entry_id]

    # Sort by title and write
    sorted_entries = sorted(
        [reorder(e, SOURCE_FIELD_ORDER) for e in entry_map.values()],
        key=lambda e: e.get('title', '').lower(),
    )
    write_json(sources_file, sorted_entries, dry_run)

    return added, updated, orphaned


def main():
    if not TOPICS_DIR.is_dir():
        sys.exit('Run from project root')

    parser = argparse.ArgumentParser(description='Sync questionIds in sources files.')
    parser.add_argument('--topic', metavar='TOPIC_ID')
    parser.add_argument('--remove-orphans', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()

    topic_files = sorted(TOPICS_DIR.glob('*.json'))
    if args.topic:
        topic_files = [f for f in topic_files if f.stem == args.topic]

    total_added = total_updated = total_topics = 0
    for f in topic_files:
        added, updated, _ = sync_topic(f.stem, args.remove_orphans, args.dry_run)
        if added or updated:
            total_topics += 1
            total_added += added
            total_updated += updated

    verb = 'Would update' if args.dry_run else 'Updated'
    print(f'{verb} {total_topics} topics: {total_added} new source stubs, {total_updated} entries refreshed.')


if __name__ == '__main__':
    main()

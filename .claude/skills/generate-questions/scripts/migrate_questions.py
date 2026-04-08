#!/usr/bin/env python3
"""
migrate_questions.py — One-time (idempotent) schema migration for all question and sources JSON files.

Changes applied:
  Questions:
    - articleTitle / articleUrl → sourceId (derived via slugify)
    - Add topicCategoryId, superCategoryId from registry.json
    - Rewrite with canonical field order

  Sources:
    - Add id = src_{slugify(title)} if missing
    - Add articleText: null if missing
    - Add facts: [] if missing
    - Add topicIds: [topicId] if missing (merge if present)
    - Rewrite with canonical field order

Usage:
  python3 .claude/skills/generate-questions/scripts/migrate_questions.py [--topic TOPIC_ID] [--dry-run]
"""

import argparse
import json
import re
import sys
from pathlib import Path

TOPICS_DIR = Path('assets/questions/topics')
SOURCES_DIR = Path('assets/questions/sources')
REGISTRY_PATH = Path('.claude/skills/generate-questions/data/registry.json')

QUESTION_FIELD_ORDER = [
    'id', 'question', 'correctAnswers', 'wrongAnswers', 'funFact',
    'sourceId', 'topicId', 'topicCategoryId', 'superCategoryId', 'difficulty',
]

SOURCE_FIELD_ORDER = [
    'id', 'title', 'url', 'summary', 'categories',
    'topicIds', 'articleText', 'facts', 'questionIds',
]


def slugify(title):
    s = title.lower().replace(' ', '_')
    return re.sub(r'[^a-z0-9_]', '', s)


def reorder(d, field_order):
    ordered = {k: d[k] for k in field_order if k in d}
    extras = {k: v for k, v in d.items() if k not in field_order}
    return {**ordered, **extras}


def migrate_question(q, topic_id, registry):
    result = dict(q)

    # sourceId: derive from articleTitle if present and sourceId absent
    if 'sourceId' not in result or result['sourceId'] == '':
        article_title = result.get('articleTitle', '')
        result['sourceId'] = f'src_{slugify(article_title)}' if article_title else ''

    # Remove old fields
    result.pop('articleTitle', None)
    result.pop('articleUrl', None)

    # Add new denormalised fields from registry
    topic_info = registry.get('topicMap', {}).get(topic_id, {})
    if 'topicCategoryId' not in result:
        result['topicCategoryId'] = topic_info.get('topicCategoryId', '')
    if 'superCategoryId' not in result:
        result['superCategoryId'] = topic_info.get('superCategoryId', '')

    # Ensure topicId matches filename
    result['topicId'] = topic_id

    return reorder(result, QUESTION_FIELD_ORDER)


def migrate_source(src, topic_id):
    result = dict(src)

    # Add id if missing
    if 'id' not in result or not result['id']:
        title = result.get('title', '')
        result['id'] = f'src_{slugify(title)}'

    # Add missing fields
    if 'articleText' not in result:
        result['articleText'] = None
    if 'facts' not in result:
        result['facts'] = []
    if 'topicIds' not in result:
        result['topicIds'] = [topic_id]
    elif topic_id not in result['topicIds']:
        result['topicIds'] = sorted(set(result['topicIds']) | {topic_id})

    return reorder(result, SOURCE_FIELD_ORDER)


def write_json(path, data, dry_run):
    text = json.dumps(data, indent=2, ensure_ascii=False) + '\n'
    if dry_run:
        print(f'  [dry-run] would write {path}')
    else:
        path.write_text(text, encoding='utf-8')


def main():
    if not TOPICS_DIR.is_dir():
        sys.exit('Run from project root')

    parser = argparse.ArgumentParser(description='Migrate question and sources JSON files.')
    parser.add_argument('--topic', metavar='TOPIC_ID', help='Migrate a single topic only')
    parser.add_argument('--dry-run', action='store_true', help='Print what would change without writing')
    args = parser.parse_args()

    if not REGISTRY_PATH.exists():
        sys.exit(f'registry.json not found at {REGISTRY_PATH} — run export_registry.py first')

    registry = json.loads(REGISTRY_PATH.read_text(encoding='utf-8'))

    topic_files = sorted(TOPICS_DIR.glob('*.json'))
    if args.topic:
        topic_files = [f for f in topic_files if f.stem == args.topic]
        if not topic_files:
            sys.exit(f'Topic not found: {args.topic}')

    total_questions = 0
    total_sources = 0

    for topic_file in topic_files:
        topic_id = topic_file.stem

        # Migrate questions
        questions = json.loads(topic_file.read_text(encoding='utf-8'))
        migrated_questions = [migrate_question(q, topic_id, registry) for q in questions]
        write_json(topic_file, migrated_questions, args.dry_run)
        total_questions += len(migrated_questions)

        # Migrate sources (optional — not all topics have a sources file yet)
        sources_file = SOURCES_DIR / f'{topic_id}.json'
        if sources_file.exists():
            sources = json.loads(sources_file.read_text(encoding='utf-8'))
            migrated_sources = [migrate_source(s, topic_id) for s in sources]
            write_json(sources_file, migrated_sources, args.dry_run)
            total_sources += 1

    verb = 'Would migrate' if args.dry_run else 'Migrated'
    print(f'{verb} {total_questions} questions across {len(topic_files)} files. {total_sources} sources file(s) updated.')


if __name__ == '__main__':
    main()

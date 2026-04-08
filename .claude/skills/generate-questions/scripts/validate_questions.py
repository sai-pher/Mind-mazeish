#!/usr/bin/env python3
"""
validate_questions.py — Deep validation of all question and sources JSON files.

Exits 0 (pass / warnings only) or 1 (violations found).

Usage:
  python3 .claude/skills/generate-questions/scripts/validate_questions.py [--topic TOPIC_ID] [--strict]
"""

import argparse
import json
import re
import sys
from pathlib import Path

TOPICS_DIR = Path('assets/questions/topics')
SOURCES_DIR = Path('assets/questions/sources')
REGISTRY_PATH = Path('.claude/skills/generate-questions/data/registry.json')

REQUIRED_FIELDS = ['id', 'question', 'correctAnswers', 'wrongAnswers', 'funFact',
                   'sourceId', 'topicId', 'topicCategoryId', 'superCategoryId', 'difficulty']
ID_RE = re.compile(r'^[a-z_]+_\d{3}$')
VALID_DIFFICULTIES = {'easy', 'medium', 'hard'}


def load_registry():
    if not REGISTRY_PATH.exists():
        sys.exit(f'registry.json not found — run export_registry.py first')
    return json.loads(REGISTRY_PATH.read_text(encoding='utf-8'))


def validate_topic(topic_id, registry_map, global_ids, strict):
    errors = []
    warnings = []
    topic_file = TOPICS_DIR / f'{topic_id}.json'
    sources_file = SOURCES_DIR / f'{topic_id}.json'

    if not topic_file.exists():
        return errors, warnings

    questions = json.loads(topic_file.read_text(encoding='utf-8'))
    topic_info = registry_map.get(topic_id, {})

    # Load sources index
    sources_index = {}
    if sources_file.exists():
        for src in json.loads(sources_file.read_text(encoding='utf-8')):
            src_id = src.get('id', '')
            if src_id:
                sources_index[src_id] = src

    local_ids = set()
    difficulty_counts = {'easy': 0, 'medium': 0, 'hard': 0}

    for i, q in enumerate(questions):
        loc = f'{topic_id}[{i}]'

        # Required fields
        for field in REQUIRED_FIELDS:
            if field not in q:
                errors.append(f'{loc}: missing required field {field!r}')

        q_id = q.get('id', '')

        # ID format
        if not ID_RE.match(q_id):
            errors.append(f'{loc}: id {q_id!r} does not match pattern ^[a-z_]+_\\d{{3}}$')

        # ID uniqueness within topic
        if q_id in local_ids:
            errors.append(f'{loc}: duplicate id {q_id!r} within topic')
        local_ids.add(q_id)

        # ID uniqueness globally
        if q_id in global_ids:
            errors.append(f'{loc}: id {q_id!r} already used in another topic')
        global_ids.add(q_id)

        correct = q.get('correctAnswers', [])
        wrong = q.get('wrongAnswers', [])

        # correctAnswers not in wrongAnswers
        for c in correct:
            if c in wrong:
                errors.append(f'{loc}: correctAnswer {c!r} appears in wrongAnswers')

        # wrongAnswers count
        if len(wrong) < 4:
            errors.append(f'{loc}: only {len(wrong)} wrongAnswers (minimum 4)')
        elif len(wrong) < 6:
            warnings.append(f'{loc}: only {len(wrong)} wrongAnswers (target ≥6 for replay variety)')

        # difficulty
        diff = q.get('difficulty', '')
        if diff not in VALID_DIFFICULTIES:
            errors.append(f'{loc}: difficulty {diff!r} not in {{easy, medium, hard}}')
        else:
            difficulty_counts[diff] += 1

        # topicId matches filename
        if q.get('topicId') != topic_id:
            errors.append(f'{loc}: topicId {q.get("topicId")!r} does not match filename {topic_id!r}')

        # topicCategoryId / superCategoryId match registry
        if topic_info:
            if q.get('topicCategoryId') and q.get('topicCategoryId') != topic_info.get('topicCategoryId'):
                errors.append(f'{loc}: topicCategoryId mismatch (got {q.get("topicCategoryId")!r}, '
                               f'expected {topic_info.get("topicCategoryId")!r})')
            if q.get('superCategoryId') and q.get('superCategoryId') != topic_info.get('superCategoryId'):
                errors.append(f'{loc}: superCategoryId mismatch')

        # sourceId resolves
        src_id = q.get('sourceId', '')
        if src_id and src_id not in sources_index:
            warnings.append(f'{loc}: sourceId {src_id!r} not found in sources/{topic_id}.json')

    # Per-topic: difficulty variety (≥10 questions → must have all 3 levels)
    if len(questions) >= 10:
        missing = [d for d in ('easy', 'medium', 'hard') if difficulty_counts[d] == 0]
        if missing:
            errors.append(f'{topic_id}: missing difficulty levels: {missing} (required when ≥10 questions)')

    # Sources cross-check
    if sources_file.exists():
        q_id_set = {q.get('id') for q in questions}
        for src in sources_index.values():
            for qid in src.get('questionIds', []):
                if qid not in q_id_set:
                    warnings.append(f'{topic_id} source {src.get("id")!r}: questionId {qid!r} not in topic file')
            fact_ids = set()
            for fact in src.get('facts', []):
                fid = fact.get('id', '')
                if fid in fact_ids:
                    errors.append(f'{topic_id} source {src.get("id")!r}: duplicate fact id {fid!r}')
                fact_ids.add(fid)

    if strict:
        errors.extend(warnings)
        warnings.clear()

    return errors, warnings


def main():
    if not TOPICS_DIR.is_dir():
        sys.exit('Run from project root')

    parser = argparse.ArgumentParser()
    parser.add_argument('--topic')
    parser.add_argument('--strict', action='store_true', help='Treat warnings as errors')
    args = parser.parse_args()

    registry = load_registry()
    topic_map = registry.get('topicMap', {})

    topic_files = sorted(TOPICS_DIR.glob('*.json'))
    if args.topic:
        topic_files = [f for f in topic_files if f.stem == args.topic]

    all_errors = []
    all_warnings = []
    global_ids = set()

    for f in topic_files:
        errors, warnings = validate_topic(f.stem, topic_map, global_ids, args.strict)
        all_errors.extend(errors)
        all_warnings.extend(warnings)

    total = sum(1 for f in topic_files if (TOPICS_DIR / f.name).exists())
    q_total = sum(
        len(json.loads((TOPICS_DIR / f.name).read_text(encoding='utf-8')))
        for f in topic_files if (TOPICS_DIR / f.name).exists()
    )

    print(f'Validated {q_total} questions across {total} topic(s).')

    if all_warnings:
        print(f'\nWARNINGS ({len(all_warnings)}):')
        for w in all_warnings:
            print(f'  ⚠ {w}')

    if all_errors:
        print(f'\nERRORS ({len(all_errors)}):')
        for e in all_errors:
            print(f'  ✗ {e}')
        sys.exit(1)
    else:
        print('✓ No violations found.')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
audit_sources.py — Health report for all source files.

Checks:
  - Every topic in the registry has a sources file
  - Every source has a non-empty URL
  - Every source has a non-empty summary
  - Every source has ≥ MIN_FACTS facts (default 5)
  - All facts are verified (verified: true)
  - No duplicate source IDs within a topic file
  - questionIds in sources exist in the topic question file
  - Questions in topic file have at least one source referencing them

Usage:
  python3 .claude/skills/generate-questions/scripts/audit_sources.py
  python3 .claude/skills/generate-questions/scripts/audit_sources.py --topic bridges
  python3 .claude/skills/generate-questions/scripts/audit_sources.py --min-facts 3

Exit code 0 if only warnings; 1 if structural errors found.
"""

import argparse
import json
import sys
from pathlib import Path

TOPICS_DIR = Path('assets/questions/topics')
SOURCES_DIR = Path('assets/questions/sources')
REGISTRY_PATH = Path('.claude/skills/generate-questions/data/registry.json')
MIN_FACTS_DEFAULT = 5
W = 70


def load_registry():
    if not REGISTRY_PATH.exists():
        sys.exit('registry.json not found — run export_registry.py first')
    return json.loads(REGISTRY_PATH.read_text(encoding='utf-8'))


def audit_topic_sources(topic_id: str, min_facts: int) -> tuple[list[str], list[str]]:
    """Returns (errors, warnings) for a topic's sources file."""
    errors: list[str] = []
    warnings: list[str] = []

    sources_file = SOURCES_DIR / f'{topic_id}.json'
    topic_file = TOPICS_DIR / f'{topic_id}.json'

    if not sources_file.exists():
        errors.append('no sources file')
        return errors, warnings

    try:
        sources = json.loads(sources_file.read_text(encoding='utf-8'))
    except json.JSONDecodeError as e:
        errors.append(f'invalid JSON: {e}')
        return errors, warnings

    if not isinstance(sources, list):
        errors.append('sources file must be a JSON array')
        return errors, warnings

    # Load question IDs from topic file for cross-reference
    topic_qids: set[str] = set()
    if topic_file.exists():
        try:
            questions = json.loads(topic_file.read_text(encoding='utf-8'))
            topic_qids = {q.get('id', '') for q in questions if q.get('id')}
        except (json.JSONDecodeError, TypeError):
            pass

    # Collect all question IDs claimed by sources
    sourced_qids: set[str] = set()

    seen_source_ids: set[str] = set()
    seen_fact_ids: set[str] = set()

    for i, src in enumerate(sources):
        src_id = src.get('id', f'[index {i}]')
        label = f'source[{src_id}]'

        # Duplicate source IDs
        if src_id in seen_source_ids:
            errors.append(f'{label}: duplicate source id')
        seen_source_ids.add(src_id)

        # URL
        if not src.get('url'):
            warnings.append(f'{label}: missing url')

        # Summary
        if not src.get('summary'):
            warnings.append(f'{label}: missing summary')

        # Facts
        facts = src.get('facts', [])
        if len(facts) < min_facts:
            warnings.append(f'{label}: only {len(facts)} facts (target ≥{min_facts})')

        for fact in facts:
            fid = fact.get('id', '')
            if fid in seen_fact_ids:
                errors.append(f'{label}: duplicate fact id "{fid}"')
            seen_fact_ids.add(fid)

            if not fact.get('verified', True):
                warnings.append(f'{label}: fact "{fid}" is unverified')

            if not fact.get('text'):
                errors.append(f'{label}: fact "{fid}" has no text')

        # questionIds cross-reference
        for qid in src.get('questionIds', []):
            sourced_qids.add(qid)
            if topic_qids and qid not in topic_qids:
                warnings.append(f'{label}: questionId "{qid}" not found in topic file')

    # Questions with no source
    unsourced = topic_qids - sourced_qids
    for qid in sorted(unsourced):
        warnings.append(f'question "{qid}" has no source')

    return errors, warnings


def main():
    if not TOPICS_DIR.is_dir():
        sys.exit('Run from project root')

    parser = argparse.ArgumentParser(description='Audit source files for all topics.')
    parser.add_argument('--topic', help='Audit a single topic ID')
    parser.add_argument('--min-facts', type=int, default=MIN_FACTS_DEFAULT,
                        help=f'Minimum facts per source (default: {MIN_FACTS_DEFAULT})')
    args = parser.parse_args()

    registry = load_registry()
    topic_map = registry.get('topicMap', {})
    all_topic_ids = sorted(topic_map.keys())

    if args.topic:
        if args.topic not in topic_map:
            sys.exit(f'Unknown topic: {args.topic}')
        all_topic_ids = [args.topic]

    print('=' * W)
    print('MIND MAZEISH TRIVIA — Sources Audit')
    print('=' * W)

    total_errors = 0
    total_warnings = 0
    topics_ok = 0
    topics_with_issues = 0

    all_error_lines: list[str] = []
    all_warning_lines: list[str] = []

    for tid in all_topic_ids:
        errors, warnings = audit_topic_sources(tid, args.min_facts)
        total_errors += len(errors)
        total_warnings += len(warnings)

        sources_file = SOURCES_DIR / f'{tid}.json'
        src_count = 0
        fact_count = 0
        url_count = 0
        if sources_file.exists():
            try:
                srcs = json.loads(sources_file.read_text(encoding='utf-8'))
                src_count = len(srcs)
                fact_count = sum(len(s.get('facts', [])) for s in srcs)
                url_count = sum(1 for s in srcs if s.get('url'))
            except (json.JSONDecodeError, TypeError):
                pass

        has_issues = bool(errors or warnings)
        status = 'ERROR' if errors else ('WARN' if warnings else 'OK')
        warn_marker = '  ⚠' if has_issues else ''
        print(f"  {tid:<30} src:{src_count}  facts:{fact_count}  urls:{url_count}/{src_count}"
              f"  [{status}]{warn_marker}")

        if has_issues:
            topics_with_issues += 1
        else:
            topics_ok += 1

        for e in errors:
            all_error_lines.append(f'  ✗ {tid}: {e}')
        for w in warnings:
            all_warning_lines.append(f'  ⚠ {tid}: {w}')

    print(f'\n{"=" * W}')
    print('GLOBAL SUMMARY')
    total_topics = len(all_topic_ids)
    print(f'  Topics: {total_topics}  |  ok: {topics_ok}  |  with-issues: {topics_with_issues}')
    print(f'  Errors: {total_errors}  |  Warnings: {total_warnings}')

    if all_error_lines:
        print(f'\nERRORS ({len(all_error_lines)})')
        for line in all_error_lines:
            print(line)

    if all_warning_lines:
        print(f'\nWARNINGS ({len(all_warning_lines)})')
        for line in all_warning_lines:
            print(line)

    if not all_error_lines and not all_warning_lines:
        print('\n✓ All sources are healthy.')

    print('=' * W)

    if total_errors:
        sys.exit(1)


if __name__ == '__main__':
    main()

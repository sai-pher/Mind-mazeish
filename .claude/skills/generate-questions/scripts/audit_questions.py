#!/usr/bin/env python3
"""
audit_questions.py — Full health report for all questions, hierarchy-structured.

Usage:
  python3 .claude/skills/generate-questions/scripts/audit_questions.py [--topic TOPIC_ID]
  [--category CATEGORY_ID] [--super-category SUPER_CATEGORY_ID]

Always exits 0.
"""

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

TOPICS_DIR = Path('assets/questions/topics')
SOURCES_DIR = Path('assets/questions/sources')
REGISTRY_PATH = Path('.claude/skills/generate-questions/data/registry.json')
W = 70


def load_registry():
    if not REGISTRY_PATH.exists():
        sys.exit(f'registry.json not found — run export_registry.py first')
    return json.loads(REGISTRY_PATH.read_text(encoding='utf-8'))


def topic_health(count):
    if count < 10:
        return 'THIN'
    if count < 30:
        return 'OK'
    return 'FULL'


def audit_topic(topic_id, registry_map):
    topic_file = TOPICS_DIR / f'{topic_id}.json'
    sources_file = SOURCES_DIR / f'{topic_id}.json'

    questions = []
    if topic_file.exists():
        questions = json.loads(topic_file.read_text(encoding='utf-8'))

    diff = defaultdict(int)
    for q in questions:
        diff[q.get('difficulty', 'unknown')] += 1

    wrong_counts = [len(q.get('wrongAnswers', [])) for q in questions]
    avg_wrong = sum(wrong_counts) / len(wrong_counts) if wrong_counts else 0

    sources = []
    facts_count = 0
    if sources_file.exists():
        sources = json.loads(sources_file.read_text(encoding='utf-8'))
        for s in sources:
            facts_count += len(s.get('facts', []))

    info = registry_map.get(topic_id, {})
    return {
        'topic_id': topic_id,
        'name': info.get('name', topic_id),
        'emoji': info.get('emoji', ''),
        'topicCategoryId': info.get('topicCategoryId', ''),
        'superCategoryId': info.get('superCategoryId', ''),
        'count': len(questions),
        'easy': diff.get('easy', 0),
        'medium': diff.get('medium', 0),
        'hard': diff.get('hard', 0),
        'health': topic_health(len(questions)),
        'has_sources': sources_file.exists(),
        'facts': facts_count,
        'avg_wrong': round(avg_wrong, 1),
    }


def issues_for(t):
    issues = []
    if t['health'] == 'THIN':
        issues.append(f"THIN ({t['count']} q)")
    if not t['has_sources']:
        issues.append('no sources file')
    if t['count'] >= 3:
        levels = sum(1 for k in ('easy', 'medium', 'hard') if t[k] > 0)
        if levels < 2:
            issues.append('no difficulty variety')
    if t['avg_wrong'] < 6 and t['count'] > 0:
        issues.append(f"avg {t['avg_wrong']} wrong answers (target ≥6)")
    if t['facts'] == 0:
        issues.append('0 facts')
    return issues


def main():
    if not TOPICS_DIR.is_dir():
        sys.exit('Run from project root')

    parser = argparse.ArgumentParser()
    parser.add_argument('--topic')
    parser.add_argument('--category')
    parser.add_argument('--super-category')
    args = parser.parse_args()

    registry = load_registry()
    topic_map = registry.get('topicMap', {})
    super_cats = registry.get('superCategories', [])

    all_topics = [audit_topic(tid, topic_map) for tid in sorted(topic_map.keys())]

    # Apply filters
    if args.topic:
        all_topics = [t for t in all_topics if t['topic_id'] == args.topic]
    if args.category:
        all_topics = [t for t in all_topics if t['topicCategoryId'] == args.category]
    if args.super_category:
        all_topics = [t for t in all_topics if t['superCategoryId'] == args.super_category]

    topic_index = {t['topic_id']: t for t in all_topics}

    print('=' * W)
    print('MIND MAZEISH TRIVIA — Question Audit')
    print('=' * W)

    all_issues = []

    for sc in super_cats:
        sc_topics = []
        for cat in sc.get('categories', []):
            for topic_stub in cat.get('topics', []):
                tid = topic_stub['id']
                if tid in topic_index:
                    sc_topics.append(topic_index[tid])

        if not sc_topics:
            continue

        sc_total = sum(t['count'] for t in sc_topics)
        sc_facts = sum(t['facts'] for t in sc_topics)
        sc_emoji = sc.get('emoji', '')
        print(f"\n[{sc['name'].upper()}] {sc_emoji}  total: {sc_total} q  facts: {sc_facts}")
        sc_easy = sum(t['easy'] for t in sc_topics)
        sc_med = sum(t['medium'] for t in sc_topics)
        sc_hard = sum(t['hard'] for t in sc_topics)
        print(f"  easy:{sc_easy}  medium:{sc_med}  hard:{sc_hard}")

        for cat in sc.get('categories', []):
            cat_topics_here = [topic_index[t['id']] for t in cat.get('topics', []) if t['id'] in topic_index]
            if not cat_topics_here:
                continue
            print(f"\n  [{cat['name']}]")
            for t in cat_topics_here:
                src_flag = 'YES' if t['has_sources'] else 'NO'
                warn = '  ⚠' if issues_for(t) else ''
                line = (f"    {t['topic_id']:<28} {t['count']:>3} q  "
                        f"easy:{t['easy']} med:{t['medium']} hard:{t['hard']}  "
                        f"[{t['health']}]  src:{src_flag}  facts:{t['facts']}{warn}")
                print(line)
                all_issues.extend([(t['topic_id'], iss) for iss in issues_for(t)])

    # Global summary
    total = sum(t['count'] for t in all_topics)
    easy = sum(t['easy'] for t in all_topics)
    med = sum(t['medium'] for t in all_topics)
    hard = sum(t['hard'] for t in all_topics)
    src_count = sum(1 for t in all_topics if t['has_sources'])
    total_facts = sum(t['facts'] for t in all_topics)
    full_n = sum(1 for t in all_topics if t['health'] == 'FULL')
    ok_n = sum(1 for t in all_topics if t['health'] == 'OK')
    thin_n = sum(1 for t in all_topics if t['health'] == 'THIN')
    wrong_avgs = [t['avg_wrong'] for t in all_topics if t['count'] > 0]
    global_avg_wrong = round(sum(wrong_avgs) / len(wrong_avgs), 1) if wrong_avgs else 0

    print(f'\n{"=" * W}')
    print('GLOBAL SUMMARY')
    print(f"  Total: {total} q  |  easy:{easy}  medium:{med}  hard:{hard}")
    print(f"  Sources: {src_count}/{len(all_topics)} topics have sources files")
    print(f"  Facts: {total_facts} total")
    print(f"  full(≥30): {full_n}  |  ok(10-29): {ok_n}  |  thin(<10): {thin_n}")
    print(f"  Avg wrong answers: {global_avg_wrong} (target: 8–12)")

    if all_issues:
        print(f'\nISSUES ({len(all_issues)})')
        for topic_id, iss in all_issues:
            print(f'  ⚠ {topic_id}: {iss}')
    else:
        print('\nNo issues found.')

    print('=' * W)


if __name__ == '__main__':
    main()

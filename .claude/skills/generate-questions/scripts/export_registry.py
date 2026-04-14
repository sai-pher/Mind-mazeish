#!/usr/bin/env python3
"""
export_registry.py — Parse topic_registry.dart and export registry.json.

Usage:
  python3 .claude/skills/generate-questions/scripts/export_registry.py

Output: .claude/skills/generate-questions/data/registry.json

Re-run whenever topic_registry.dart changes.
"""

import json
import re
import sys
from pathlib import Path

REGISTRY_DART = Path('lib/features/gameplay/data/topic_registry.dart')
OUTPUT = Path('.claude/skills/generate-questions/data/registry.json')

TOPIC_RE = re.compile(
    r"Topic\s*\(\s*id:\s*'([^']+)',\s*name:\s*'([^']+)',\s*categoryId:\s*'([^']+)',\s*emoji:\s*'([^']+)'\s*\)"
)
ID_RE = re.compile(r"\bid:\s*'([^']+)'")
NAME_RE = re.compile(r"(?<!\w)name:\s*'([^']+)'")


def extract_between_parens(text, start_pos):
    """Return (content, end_pos) for balanced parens starting at start_pos (the opening '(')."""
    assert text[start_pos] == '('
    depth = 0
    for i in range(start_pos, len(text)):
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0:
                return text[start_pos + 1:i], i + 1
    return text[start_pos + 1:], len(text)


def find_constructor_bodies(text, name):
    """Return list of body strings for all `name(...)` constructor calls in text."""
    bodies = []
    search = name + '('
    pos = 0
    while True:
        idx = text.find(search, pos)
        if idx == -1:
            break
        open_paren = idx + len(name)
        body, end_pos = extract_between_parens(text, open_paren)
        bodies.append(body)
        pos = end_pos
    return bodies


def parse_registry(dart_text):
    super_categories = []
    topic_map = {}

    for sc_body in find_constructor_bodies(dart_text, 'SuperCategory'):
        sc_id_m = ID_RE.search(sc_body)
        sc_name_m = NAME_RE.search(sc_body)
        if not sc_id_m or not sc_name_m:
            continue
        sc_id = sc_id_m.group(1)
        sc_name = sc_name_m.group(1)

        topic_categories = []
        for tc_body in find_constructor_bodies(sc_body, 'TopicCategory'):
            tc_id_m = ID_RE.search(tc_body)
            tc_name_m = NAME_RE.search(tc_body)
            if not tc_id_m or not tc_name_m:
                continue
            tc_id = tc_id_m.group(1)
            tc_name = tc_name_m.group(1)

            topics = []
            for m in TOPIC_RE.finditer(tc_body):
                topic_id, topic_name, _cat_id, emoji = m.groups()
                topics.append({'id': topic_id, 'name': topic_name, 'emoji': emoji})
                topic_map[topic_id] = {
                    'superCategoryId': sc_id,
                    'superCategoryName': sc_name,
                    'topicCategoryId': tc_id,
                    'topicCategoryName': tc_name,
                    'name': topic_name,
                    'emoji': emoji,
                }

            topic_categories.append({'id': tc_id, 'name': tc_name, 'topics': topics})

        super_categories.append({
            'id': sc_id,
            'name': sc_name,
            'categories': topic_categories,
        })

    return super_categories, topic_map


def main():
    if not Path('assets/questions/topics').is_dir():
        sys.exit('Run from project root')

    dart_text = REGISTRY_DART.read_text(encoding='utf-8')
    super_categories, topic_map = parse_registry(dart_text)

    n_sc = len(super_categories)
    n_tc = sum(len(sc['categories']) for sc in super_categories)
    n_topics = len(topic_map)

    assert n_topics == 36, f'Expected 36 topics, got {n_topics}'

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    result = {'superCategories': super_categories, 'topicMap': topic_map}
    OUTPUT.write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + '\n',
        encoding='utf-8',
    )

    print(f'Exported {n_sc} superCategories, {n_tc} topicCategories, {n_topics} topics → {OUTPUT}')


if __name__ == '__main__':
    main()

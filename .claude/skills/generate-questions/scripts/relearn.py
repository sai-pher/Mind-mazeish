#!/usr/bin/env python3
"""
relearn.py — Fetch Wikipedia articles and extract facts into source JSON files.

Usage:
    python3 .claude/skills/generate-questions/scripts/relearn.py [topicId ...]

    If no topic IDs are given, processes ALL topics in TOPICS list.
    If topic IDs are given, processes only those topics.

Each topic entry maps a topicId → primary source title to fetch.
Facts are appended to the matching source entry's `facts` array and written
back to assets/questions/sources/{topicId}.json without reading the whole
file into another tool's context.
"""

from __future__ import annotations

import datetime
import json
import subprocess
import sys
from pathlib import Path

# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────

SOURCES_DIR = Path("assets/questions/sources")
TODAY = datetime.date.today().isoformat()
MAX_WIKI_CHARS = 6000
MAX_FACTS_PER_SOURCE = 30

# (topicId, primary_source_title)
TOPICS: list[tuple[str, str]] = [
    ("coffee",                "History of coffee"),
    ("coffee_brewing",        "Espresso"),
    ("deep_sea",              "Mariana Trench"),
    ("crocheting",            "Crochet"),
    ("water_bodies",          "Ocean"),
    ("socks",                 "Sock"),
    ("adhd",                  "Attention Deficit Hyperactivity Disorder"),
    ("therapy",               "Cognitive Behavioral Therapy"),
    ("pharmaceutical_drugs",  "Pharmacology"),
    ("recreational_drugs",    "Cannabis (drug)"),
    ("medicine",              "Antibiotic"),
    ("countries",             "United Nations Member States"),
    ("dictionaries",          "Oxford English Dictionary"),
    ("linguistics",           "Linguistics"),
    ("theology",              "Five Pillars of Islam"),
    ("medieval_history",      "Magna Carta"),
    ("footwear",              "Shoe"),
    ("perfumes",              "Perfume"),
    ("plastics",              "Plastic pollution"),
    ("handheld_devices",      "Smartphone"),
    ("human_geography",       "Urbanization"),
    ("tennis",                "Tennis"),
    ("puzzles",               "Rubiks Cube"),
    ("west_african_history",  "Mali Empire"),
    ("french_literature",     "Albert Camus"),
    ("lily_mayne",            "Romance novel"),
    ("rocks",                 "Rock Cycle"),
    ("agatha_christie",       "Agatha Christie"),
    ("anatomy",               "Human skeleton"),
    ("autism",                "Autism Spectrum"),
    ("bridges",               "Suspension Bridge"),
]

EXTRACT_PROMPT_TEMPLATE = """\
You are a trivia fact extractor for a medieval castle trivia game called Mind Mazeish.

Given the Wikipedia article text below, extract up to {max_facts} atomic, trivia-worthy facts.

Rules:
- Each fact must be a single, self-contained statement (no compound facts joined by "and")
- Facts must be specific enough to base a multiple-choice trivia question on
- Prefer surprising, memorable, or counter-intuitive facts
- Avoid vague generalities ("it is popular worldwide") or completely obvious facts
- Output ONLY a JSON array of strings — one string per fact
- No markdown fences, no explanation, no preamble — raw JSON array only

Article text:
{article_text}

Output (raw JSON array of strings only):"""


# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

def fetch_article(title: str) -> str | None:
    result = subprocess.run(
        [
            sys.executable,
            ".claude/skills/generate-questions/scripts/fetch_wiki.py",
            title,
            "--max-chars", str(MAX_WIKI_CHARS),
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0 and result.stdout.strip():
        return result.stdout.strip()
    code_msg = {2: "article not found", 3: "network unavailable"}.get(
        result.returncode, f"exit {result.returncode}"
    )
    print(f"    ✗ fetch_wiki '{title}': {code_msg}", file=sys.stderr)
    return None


def extract_facts_via_claude(article_text: str, max_facts: int = MAX_FACTS_PER_SOURCE) -> list[str]:
    prompt = EXTRACT_PROMPT_TEMPLATE.format(
        max_facts=max_facts,
        article_text=article_text,
    )
    result = subprocess.run(
        ["claude", "-p", prompt],
        capture_output=True,
        text=True,
        timeout=180,
    )
    if result.returncode != 0:
        print(f"    ✗ claude extract failed (exit {result.returncode}): {result.stderr[:300]}", file=sys.stderr)
        return []
    output = result.stdout.strip()
    # Locate the JSON array in output (claude may emit leading/trailing text)
    start = output.find("[")
    end   = output.rfind("]") + 1
    if start == -1 or end <= 0:
        print(f"    ✗ no JSON array in claude output; snippet: {output[:200]}", file=sys.stderr)
        return []
    try:
        facts = json.loads(output[start:end])
        if isinstance(facts, list):
            return [f for f in facts if isinstance(f, str) and f.strip()]
    except json.JSONDecodeError as exc:
        print(f"    ✗ JSON parse error: {exc}", file=sys.stderr)
    return []


def slug_from_source_id(source_id: str) -> str:
    """'src_rock_cycle' → 'rock_cycle'"""
    return source_id.removeprefix("src_")


def next_fact_num(existing_facts: list[dict]) -> int:
    if not existing_facts:
        return 1
    nums = []
    for f in existing_facts:
        parts = f.get("id", "").rsplit("_", 1)
        if len(parts) == 2 and parts[1].isdigit():
            nums.append(int(parts[1]))
    return (max(nums) + 1) if nums else (len(existing_facts) + 1)


def process_topic(topic_id: str, source_title: str) -> bool:
    sources_file = SOURCES_DIR / f"{topic_id}.json"
    if not sources_file.exists():
        print(f"    ✗ {sources_file} not found", file=sys.stderr)
        return False

    sources: list[dict] = json.loads(sources_file.read_text(encoding="utf-8"))

    # Find the target source entry (case-insensitive title match)
    target: dict | None = None
    for src in sources:
        if src.get("title", "").lower() == source_title.lower():
            target = src
            break

    if target is None:
        print(f"    ✗ source '{source_title}' not found in {sources_file}", file=sys.stderr)
        return False

    existing_facts: list[dict] = target.get("facts", [])
    existing_count = len(existing_facts)

    if existing_count >= MAX_FACTS_PER_SOURCE:
        print(f"    ✓ already {existing_count} facts — skipping")
        return True

    want = MAX_FACTS_PER_SOURCE - existing_count

    # Fetch article
    article_text = fetch_article(source_title)
    if not article_text:
        return False

    # Extract facts
    new_fact_texts = extract_facts_via_claude(article_text, max_facts=want)
    if not new_fact_texts:
        print(f"    ✗ no facts extracted", file=sys.stderr)
        return False

    # Cap to what we want
    new_fact_texts = new_fact_texts[:want]

    slug      = slug_from_source_id(target["id"])
    start_num = next_fact_num(existing_facts)

    new_facts = [
        {
            "id":         f"fact_{slug}_{start_num + i:03d}",
            "text":       text,
            "verified":   True,
            "verifiedAt": TODAY,
        }
        for i, text in enumerate(new_fact_texts)
    ]

    target["facts"] = existing_facts + new_facts

    sources_file.write_text(
        json.dumps(sources, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"    ✓ wrote {len(new_facts)} new facts (total: {len(target['facts'])})")
    return True


# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────

def main() -> None:
    # Filter to requested topics if args given
    requested = set(sys.argv[1:])
    work = [(t, s) for t, s in TOPICS if not requested or t in requested]

    if not work:
        print(f"No matching topics for: {requested}", file=sys.stderr)
        sys.exit(1)

    print(f"Relearn: {len(work)} topic(s)\n")
    success = 0
    for topic_id, source_title in work:
        print(f"→ {topic_id}  ({source_title})")
        ok = process_topic(topic_id, source_title)
        if ok:
            success += 1

    print(f"\nDone: {success}/{len(work)} succeeded")
    if success < len(work):
        sys.exit(1)


if __name__ == "__main__":
    main()
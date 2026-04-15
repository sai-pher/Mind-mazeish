#!/usr/bin/env python3
"""
relearn.py — Fetch Wikipedia articles and extract facts into source JSON files.

Usage:
    python3 .claude/skills/generate-questions/scripts/relearn.py [topicId ...]

    If no topic IDs are given, processes ALL topics in TOPICS list.
    If topic IDs are given, processes those topics — any topic with a sources
    file in assets/questions/sources/ is accepted, not just those in TOPICS.

For each topic, ALL source entries in its sources file are processed.
Facts are appended to each source entry's `facts` array and written back
to assets/questions/sources/{topicId}.json after each source so partial
progress is preserved if the script is interrupted.
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
MAX_WIKI_CHARS = 20000
MAX_FACTS_PER_SOURCE = 30

# Default topics to process when no topic IDs are given on the command line.
# Any topic with a sources file can be passed as an argument regardless of
# whether it appears in this list.
TOPICS: list[str] = [
    "coffee",
    "coffee_brewing",
    "deep_sea",
    "crocheting",
    "water_bodies",
    "socks",
    "adhd",
    "therapy",
    "pharmaceutical_drugs",
    "recreational_drugs",
    "medicine",
    "countries",
    "dictionaries",
    "linguistics",
    "theology",
    "medieval_history",
    "footwear",
    "perfumes",
    "plastics",
    "handheld_devices",
    "human_geography",
    "tennis",
    "puzzles",
    "west_african_history",
    "french_literature",
    "lily_mayne",
    "rocks",
    "agatha_christie",
    "anatomy",
    "autism",
    "bridges",
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


def process_topic(topic_id: str, only_sources: set[str] | None = None, max_facts: int = MAX_FACTS_PER_SOURCE) -> bool:
    """Process every source entry in a topic's sources file.

    Skips entries that already have max_facts or more facts.
    Writes the file back after each successful extraction so partial
    progress is preserved if the script is interrupted.

    Returns True if at least one source was processed without error.
    """
    sources_file = SOURCES_DIR / f"{topic_id}.json"
    if not sources_file.exists():
        print(f"  ✗ {sources_file} not found", file=sys.stderr)
        return False

    sources: list[dict] = json.loads(sources_file.read_text(encoding="utf-8"))
    any_success = False

    for src in sources:
        source_id = src.get("id", "")
        title     = src.get("title", "").strip()

        if only_sources and source_id not in only_sources:
            continue

        if not title:
            print(f"  ✗ {source_id}: no title — skipping", file=sys.stderr)
            continue

        existing_facts: list[dict] = src.get("facts", [])
        existing_count = len(existing_facts)

        if existing_count >= max_facts:
            print(f"  ✓ {source_id}: already {existing_count} facts — skipping")
            any_success = True
            continue

        want = max_facts - existing_count
        print(f"  → {source_id}  ({title})")

        article_text = fetch_article(title)
        if not article_text:
            continue

        new_fact_texts = extract_facts_via_claude(article_text, max_facts=want)
        if not new_fact_texts:
            print(f"    ✗ no facts extracted", file=sys.stderr)
            continue

        new_fact_texts = new_fact_texts[:want]
        slug      = slug_from_source_id(source_id)
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

        src["facts"] = existing_facts + new_facts

        # Write after each source so progress survives interruption
        sources_file.write_text(
            json.dumps(sources, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(f"    ✓ wrote {len(new_facts)} new facts (total: {len(src['facts'])})")
        any_success = True

    return any_success


# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────

def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(
        description="Fetch Wikipedia articles and extract facts into source JSON files.",
        epilog=(
            "Examples:\n"
            "  %(prog)s                                         # all default topics\n"
            "  %(prog)s french_literature                       # all sources in topic\n"
            "  %(prog)s french_literature --sources src_albert_camus src_victor_hugo\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "topics",
        nargs="*",
        help="Topic IDs to process (default: all topics in TOPICS list)",
    )
    parser.add_argument(
        "--sources", "-s",
        nargs="+",
        metavar="SOURCE_ID",
        help="Process only these source IDs within the specified topic(s)",
    )
    parser.add_argument(
        "--count", "-n",
        type=int,
        default=MAX_FACTS_PER_SOURCE,
        metavar="N",
        help=f"Target number of facts per source (default: {MAX_FACTS_PER_SOURCE})",
    )
    args = parser.parse_args()

    work = args.topics if args.topics else TOPICS
    only_sources = set(args.sources) if args.sources else None

    # Validate: every requested topic must have a sources file
    missing = [t for t in work if not (SOURCES_DIR / f"{t}.json").exists()]
    if missing:
        print(f"No sources file found for: {', '.join(missing)}", file=sys.stderr)
        print(f"Expected: {SOURCES_DIR}/{{topicId}}.json", file=sys.stderr)
        sys.exit(1)

    scope = f" (sources: {', '.join(sorted(only_sources))})" if only_sources else ""
    print(f"Relearn: {len(work)} topic(s){scope}\n")

    success = 0
    for topic_id in work:
        print(f"→ {topic_id}")
        ok = process_topic(topic_id, only_sources=only_sources, max_facts=args.count)
        if ok:
            success += 1

    print(f"\nDone: {success}/{len(work)} succeeded")
    if success < len(work):
        sys.exit(1)


if __name__ == "__main__":
    main()
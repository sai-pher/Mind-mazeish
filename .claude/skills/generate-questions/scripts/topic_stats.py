#!/usr/bin/env python3
"""
topic_stats.py — Print lightweight metadata about a topic file.

Returns only what's needed for ID dedup and next-ID calculation, without
loading the full file into any agent's context window.

Usage:
  python3 .claude/skills/generate-questions/scripts/topic_stats.py --topic TOPIC_ID

Output (JSON):
  {
    "count": 25,
    "nextId": "coffee_026",
    "existingIds": ["coffee_001", ...]
  }

If the topic file does not exist yet, count is 0 and nextId is "{topicId}_001".
"""

import argparse
import json
import sys
from pathlib import Path

TOPICS_DIR = Path("assets/questions/topics")


def main() -> None:
    if not Path("assets").is_dir():
        sys.exit("Run from project root")

    parser = argparse.ArgumentParser(description="Print topic metadata without loading the full file.")
    parser.add_argument("--topic", required=True, metavar="TOPIC_ID")
    args = parser.parse_args()

    path = TOPICS_DIR / f"{args.topic}.json"

    if not path.exists():
        result = {"count": 0, "nextId": f"{args.topic}_001", "existingIds": []}
        print(json.dumps(result, indent=2))
        return

    questions = json.loads(path.read_text(encoding="utf-8"))
    existing_ids = [q["id"] for q in questions if q.get("id")]

    prefix = args.topic + "_"
    max_n = 0
    for qid in existing_ids:
        if qid.startswith(prefix):
            try:
                max_n = max(max_n, int(qid[len(prefix):]))
            except ValueError:
                pass

    next_id = f"{args.topic}_{max_n + 1:03d}"

    print(json.dumps({"count": len(questions), "nextId": next_id, "existingIds": existing_ids}, indent=2))


if __name__ == "__main__":
    main()

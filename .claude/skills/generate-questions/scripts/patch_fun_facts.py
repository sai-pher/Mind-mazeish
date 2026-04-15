#!/usr/bin/env python3
"""
Patch funFact fields into existing questions from a JSON patch file.

Usage:
    echo '[{"id": "deep_sea_001", "funFact": "..."}]' \
      | python3 patch_fun_facts.py --topic deep_sea

The patch file is a JSON array of objects with 'id' and 'funFact' keys.
Only questions matching the given IDs are updated; all others are left unchanged.
"""

import argparse
import json
import sys
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Patch funFact fields into topic questions.")
    parser.add_argument("--topic", required=True, help="Topic ID (e.g. deep_sea)")
    args = parser.parse_args()

    topic_path = Path("assets/questions/topics") / f"{args.topic}.json"
    if not topic_path.exists():
        print(f"ERROR: {topic_path} not found", file=sys.stderr)
        sys.exit(1)

    patches = json.loads(sys.stdin.read())
    patch_map = {p["id"]: p["funFact"] for p in patches}

    with open(topic_path) as f:
        questions = json.load(f)

    updated = 0
    for q in questions:
        if q["id"] in patch_map:
            q["funFact"] = patch_map[q["id"]]
            updated += 1

    with open(topic_path, "w") as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"Patched {updated} question(s) in {topic_path}")


if __name__ == "__main__":
    main()

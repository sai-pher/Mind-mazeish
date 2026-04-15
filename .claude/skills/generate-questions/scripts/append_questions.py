#!/usr/bin/env python3
"""
append_questions.py — Append new questions from stdin to a topic JSON file.

Reads a JSON array from stdin and appends it to
assets/questions/topics/{topicId}.json, creating the file if it doesn't exist.
Duplicate IDs are skipped with a warning. The existing file is opened for
reading only to check for duplicates; the full contents are never passed back
through an agent's context window.

Usage:
  echo '[{...}]' | python3 .claude/skills/generate-questions/scripts/append_questions.py --topic TOPIC_ID
  python3 generate.py | python3 append_questions.py --topic coffee

Exit: 0 on success, 1 on error.
"""

import argparse
import json
import sys
from pathlib import Path

TOPICS_DIR = Path("assets/questions/topics")


def main() -> None:
    if not Path("assets").is_dir():
        sys.exit("Run from project root")

    parser = argparse.ArgumentParser(description="Append new questions to a topic JSON file.")
    parser.add_argument("--topic", required=True, metavar="TOPIC_ID")
    parser.add_argument("--dry-run", action="store_true", help="Validate and report without writing")
    args = parser.parse_args()

    try:
        new_questions = json.loads(sys.stdin.read())
    except json.JSONDecodeError as e:
        sys.exit(f"Invalid JSON on stdin: {e}")

    if not isinstance(new_questions, list):
        sys.exit("Expected a JSON array on stdin")

    if not new_questions:
        print("Nothing to append — empty array received.")
        return

    path = TOPICS_DIR / f"{args.topic}.json"
    existing: list[dict] = []
    if path.exists():
        existing = json.loads(path.read_text(encoding="utf-8"))

    existing_ids = {q["id"] for q in existing if q.get("id")}

    accepted: list[dict] = []
    skipped: list[str] = []
    for q in new_questions:
        qid = q.get("id", "")
        if qid in existing_ids:
            skipped.append(qid)
        else:
            accepted.append(q)
            existing_ids.add(qid)

    if skipped:
        print(f"Skipped {len(skipped)} duplicate ID(s): {', '.join(skipped)}", file=sys.stderr)

    if not accepted:
        print("No new questions to append (all were duplicates).")
        return

    if args.dry_run:
        print(f"[dry-run] Would append {len(accepted)} question(s) to {args.topic}.json")
        return

    TOPICS_DIR.mkdir(parents=True, exist_ok=True)
    merged = existing + accepted
    path.write_text(json.dumps(merged, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Appended {len(accepted)} question(s) to {args.topic}.json (total now: {len(merged)})")


if __name__ == "__main__":
    main()

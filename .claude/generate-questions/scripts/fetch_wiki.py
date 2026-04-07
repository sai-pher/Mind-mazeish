#!/usr/bin/env python3
from __future__ import annotations
"""
Fetch a Wikipedia article (or specific sections) as plain text.

Usage:
    python3 scripts/fetch_wiki.py "Coffee"
    python3 scripts/fetch_wiki.py "Coffee" --sections "History" "Chemistry"
    python3 scripts/fetch_wiki.py "Coffee" --summary-only
    python3 scripts/fetch_wiki.py "Coffee" --max-chars 3000

Output: plain text, ≤ max-chars (default 4000), suitable for trivia generation.
Exit code 0 on success, 2 if article not found, 3 if network unavailable.

When exit code 3 is returned, fall back to built-in knowledge for question generation.
"""

import argparse
import sys

CHAR_LIMIT_DEFAULT = 4000
CHAR_LIMIT_PER_SECTION = 1200


def _truncate(text: str, limit: int) -> str:
    if len(text) <= limit:
        return text
    return text[:limit].rsplit(" ", 1)[0] + " [...]"


def fetch(title: str, sections: list[str] | None, summary_only: bool, max_chars: int) -> str:
    try:
        import wikipediaapi
    except ImportError:
        print("ERROR: Wikipedia-API not installed. Run: pip install Wikipedia-API", file=sys.stderr)
        sys.exit(3)

    try:
        wiki = wikipediaapi.Wikipedia(
            user_agent="mind-mazeish-trivia/1.0 (https://github.com/sai-pher)",
            language="en",
        )
        page = wiki.page(title)

        if not page.exists():
            print(f"ERROR: Wikipedia article not found: '{title}'", file=sys.stderr)
            sys.exit(2)

    except Exception as e:
        print(f"NETWORK_UNAVAILABLE: {e}", file=sys.stderr)
        sys.exit(3)

    parts: list[str] = []

    summary = _truncate(page.summary, CHAR_LIMIT_PER_SECTION)
    parts.append(f"== Summary ==\n{summary}")

    if summary_only:
        return "\n\n".join(parts)

    if sections:
        section_map = {s.title: s for s in page.sections}
        for sec_title in sections:
            sec = section_map.get(sec_title)
            if not sec:
                # Try case-insensitive match
                for s in page.sections:
                    if s.title.lower() == sec_title.lower():
                        sec = s
                        break
            if sec:
                text = _truncate(sec.text, CHAR_LIMIT_PER_SECTION)
                parts.append(f"== {sec.title} ==\n{text}")
    else:
        # Include all top-level sections up to max_chars
        budget = max_chars - len(parts[0])
        for sec in page.sections:
            if budget <= 0:
                break
            text = _truncate(sec.text, min(CHAR_LIMIT_PER_SECTION, budget))
            chunk = f"== {sec.title} ==\n{text}"
            parts.append(chunk)
            budget -= len(chunk)

    return _truncate("\n\n".join(parts), max_chars)


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch Wikipedia article text for trivia generation.")
    parser.add_argument("title", help="Wikipedia article title (e.g. 'Coffee')")
    parser.add_argument("--sections", nargs="+", metavar="SECTION",
                        help="Only include these section titles (e.g. 'History' 'Chemistry')")
    parser.add_argument("--summary-only", action="store_true",
                        help="Return only the intro/summary paragraph")
    parser.add_argument("--max-chars", type=int, default=CHAR_LIMIT_DEFAULT,
                        help=f"Hard cap on output length (default: {CHAR_LIMIT_DEFAULT})")
    args = parser.parse_args()

    print(fetch(args.title, args.sections, args.summary_only, args.max_chars))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Search Wikipedia for articles relevant to a topic.

Usage:
    python3 scripts/search_wiki.py "coffee brewing" [--results 5]

Output: JSON array to stdout, one object per article:
    [{"title": "...", "summary": "...", "categories": [...], "url": "..."}]

Exit code 0 on success (even empty []), 3 if network unavailable.
"""

import argparse
import json
import sys

USER_AGENT = "mind-mazeish-trivia/1.0 (https://github.com/sai-pher)"
SUMMARY_TRUNCATE = 300
MAX_RESULTS_CAP = 8


def _is_disambiguation(title: str, summary: str, categories: list[str]) -> bool:
    if any("disambiguation" in c.lower() for c in categories):
        return True
    if summary.lstrip().startswith("may refer to"):
        return True
    if title.endswith("(disambiguation)"):
        return True
    return False


def _search_via_opensearch(query: str, n: int) -> list[str]:
    """Fallback: use the Wikipedia OpenSearch API directly via requests."""
    import urllib.request
    import urllib.parse

    url = (
        "https://en.wikipedia.org/w/api.php"
        f"?action=opensearch&search={urllib.parse.quote(query)}"
        f"&limit={n}&format=json"
    )
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode())
    # OpenSearch returns [query, [titles], [descriptions], [urls]]
    return data[1] if len(data) > 1 else []


def search(query: str, n: int) -> list[dict]:
    try:
        import wikipediaapi
    except ImportError:
        print("ERROR: Wikipedia-API not installed. Run: pip install Wikipedia-API", file=sys.stderr)
        sys.exit(3)

    try:
        wiki = wikipediaapi.Wikipedia(user_agent=USER_AGENT, language="en")

        # Try wikipediaapi's search; fall back to OpenSearch if missing
        try:
            titles = wiki.search(query, results=n)  # type: ignore[attr-defined]
        except (AttributeError, NotImplementedError):
            titles = _search_via_opensearch(query, n)

    except Exception as e:
        print(f"NETWORK_UNAVAILABLE: {e}", file=sys.stderr)
        sys.exit(3)

    results: list[dict] = []
    for raw_title in titles:
        if len(results) >= n:
            break
        try:
            page = wiki.page(raw_title)
            if not page.exists():
                continue

            cats = list(page.categories.keys())[:5]
            summary = page.summary[:SUMMARY_TRUNCATE]
            if len(page.summary) > SUMMARY_TRUNCATE:
                summary = summary.rsplit(" ", 1)[0] + " [...]"

            if _is_disambiguation(page.title, summary, cats):
                continue

            url = "https://en.m.wikipedia.org/wiki/" + page.title.replace(" ", "_")
            results.append({
                "title": page.title,
                "summary": summary,
                "categories": cats,
                "url": url,
            })
        except Exception:
            # Skip individual failures silently
            continue

    return results


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Search Wikipedia for articles relevant to a trivia topic."
    )
    parser.add_argument("query", help="Search query (e.g. 'coffee brewing')")
    parser.add_argument(
        "--results",
        type=int,
        default=5,
        metavar="N",
        help="Maximum number of results to return (default: 5, hard cap: 8)",
    )
    args = parser.parse_args()

    n = min(args.results, MAX_RESULTS_CAP)
    results = search(args.query, n)
    print(json.dumps(results, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Archive the ## Unreleased section of release_notes.md after a release.

Usage:
    python3 scripts/archive_release_notes.py <version>   e.g. 1.0.36

What it does:
  1. Extracts the current ## Unreleased content.
  2. Inserts it as ## v<version> immediately after the --- separator.
  3. Resets ## Unreleased to empty section stubs.

The file is rewritten in-place.
"""

import re
import sys


FRESH_UNRELEASED = (
    "## Unreleased\n\n"
    "### Features\n- (none)\n\n"
    "### Fixes\n- (none)\n\n"
    "### Content\n- (none)\n\n"
    "### Other\n- (none)\n"
)


def archive(content: str, version: str) -> str:
    """Return rewritten release_notes.md content with Unreleased archived."""
    # Match the Unreleased block up to (but not including) the --- separator.
    m = re.search(r"## Unreleased\n(.*?)(?=\n---)", content, re.DOTALL)
    if not m:
        raise ValueError("No '## Unreleased' section followed by '---' found")

    unreleased_body = m.group(1).strip()
    archived_block = f"## v{version}\n{unreleased_body}\n"

    # Replace the Unreleased block with fresh stubs.
    new_content = re.sub(
        r"## Unreleased\n.*?(?=\n---)",
        FRESH_UNRELEASED.rstrip(),
        content,
        flags=re.DOTALL,
    )

    # Insert the archived block immediately after the first --- separator.
    new_content = new_content.replace("\n---\n", f"\n---\n\n{archived_block}", 1)

    return new_content


def main() -> None:
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <version>", file=sys.stderr)
        sys.exit(1)

    version = sys.argv[1]
    path = "release_notes.md"

    with open(path) as f:
        content = f.read()

    new_content = archive(content, version)

    with open(path, "w") as f:
        f.write(new_content)

    print(f"Archived ## Unreleased as ## v{version} and reset to empty stubs")


if __name__ == "__main__":
    main()

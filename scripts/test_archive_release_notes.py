"""
Regression tests for scripts/archive_release_notes.py

Run with:  python3 scripts/test_archive_release_notes.py
"""

import sys
import textwrap
import unittest

sys.path.insert(0, "scripts")
from archive_release_notes import archive, FRESH_UNRELEASED  # noqa: E402


SAMPLE = textwrap.dedent("""\
    # Release Notes

    ## Unreleased

    ### Features
    - Some cool feature (#10)

    ### Fixes
    - A bug fix (#11)

    ### Content
    - (none)

    ### Other
    - (none)

    ---

    ## v1.0.25 — 2026-02-01
    ### Other
    - Dependency bumps
""")


class TestArchive(unittest.TestCase):
    def _run(self, version="1.0.36"):
        return archive(SAMPLE, version)

    # --- reset behaviour ---

    def test_unreleased_resets_to_empty_stubs(self):
        result = self._run()
        # The fresh block must appear before the --- separator
        unreleased_idx = result.index("## Unreleased")
        sep_idx = result.index("\n---\n")
        self.assertLess(unreleased_idx, sep_idx)
        # Each section stub must be present
        for stub in ("### Features\n- (none)", "### Fixes\n- (none)",
                     "### Content\n- (none)", "### Other\n- (none)"):
            self.assertIn(stub, result[:sep_idx])

    def test_shipped_bullets_absent_from_new_unreleased_block(self):
        result = self._run()
        sep_idx = result.index("\n---\n")
        unreleased_section = result[:sep_idx]
        self.assertNotIn("Some cool feature", unreleased_section)
        self.assertNotIn("A bug fix", unreleased_section)

    # --- archive behaviour ---

    def test_archived_block_present_after_separator(self):
        result = self._run("1.0.36")
        sep_idx = result.index("\n---\n")
        after_sep = result[sep_idx:]
        self.assertIn("## v1.0.36", after_sep)

    def test_archived_block_contains_shipped_bullets(self):
        result = self._run("1.0.36")
        sep_idx = result.index("\n---\n")
        after_sep = result[sep_idx:]
        self.assertIn("Some cool feature (#10)", after_sep)
        self.assertIn("A bug fix (#11)", after_sep)

    def test_archived_block_appears_before_older_versions(self):
        result = self._run("1.0.36")
        new_idx = result.index("## v1.0.36")
        old_idx = result.index("## v1.0.25")
        self.assertLess(new_idx, old_idx)

    def test_version_string_used_verbatim(self):
        result = archive(SAMPLE, "2.0.0")
        self.assertIn("## v2.0.0", result)

    # --- idempotency / structure ---

    def test_original_versioned_section_preserved(self):
        result = self._run()
        self.assertIn("## v1.0.25 — 2026-02-01", result)
        self.assertIn("Dependency bumps", result)

    def test_only_one_unreleased_heading_in_output(self):
        result = self._run()
        self.assertEqual(result.count("## Unreleased"), 1)

    def test_raises_when_no_unreleased_section(self):
        bad = "# Release Notes\n\n## v1.0.0\n- stuff\n"
        with self.assertRaises(ValueError):
            archive(bad, "1.0.36")


if __name__ == "__main__":
    unittest.main(verbosity=2)

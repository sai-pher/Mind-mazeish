# Proposal 02: Release Pipeline

## Goal
Introduce `release_notes.md` as the single source of truth for release notes; wire it into CD; add a CI check that enforces it is updated in every PR to main.

---

## 1. `release_notes.md` (repo root)

Template structure (established at creation, maintained per release):

```markdown
# Release Notes

## Unreleased

### Features
- (none)

### Fixes
- (none)

### Content
- (none)

### Other
- (none)

---

## v1.0.{N} — YYYY-MM-DD
### Features
- …
### Fixes
- …
```

- The `## Unreleased` section is what gets written before a release.
- The CD workflow reads this section and promotes it to the versioned entry.
- After promotion, `## Unreleased` is reset to empty stubs.
- The `release_notes.md` in the repo at merge time always has human-readable notes at the top.

---

## 2. CD workflow changes (`.github/workflows/cd.yml`)

Replace the git-log-based `Generate release body` step:

```yaml
- name: Read release notes
  id: release_body
  env:
    BUILD_NUMBER: ${{ github.run_number }}
  run: |
    # Extract content between ## Unreleased and the next ## heading
    python3 - <<'PYEOF'
    import re, os, sys
    with open('release_notes.md') as f:
        content = f.read()
    m = re.search(r'## Unreleased\n(.*?)(?=\n## |\Z)', content, re.DOTALL)
    notes = m.group(1).strip() if m else ''
    version = f"1.0.{os.environ['BUILD_NUMBER']}"
    body = f"## Mind Mazeish — v{version}\n\n{notes}\n\n---\n### Installation\n1. Download the APK below\n2. Settings → Apps → Install unknown apps\n3. Open APK to install/update"
    with open('release_body.md', 'w') as f:
        f.write(body)
    PYEOF
```

Keep `body_path: release_body.md` in the `Publish GitHub Release` step (unchanged).

Remove the `workflow_dispatch` `release_notes` input — notes now come from the file.

---

## 3. CI check: `check-release-notes.yml`

New file: `.github/workflows/check-release-notes.yml`

```yaml
name: Check Release Notes

on:
  pull_request:
    branches:
      - main

jobs:
  check:
    name: Release notes updated
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0

      - name: Check release_notes.md modified
        run: |
          BASE=${{ github.event.pull_request.base.sha }}
          HEAD=${{ github.event.pull_request.head.sha }}
          if git diff --name-only "$BASE" "$HEAD" | grep -q "^release_notes.md$"; then
            echo "release_notes.md updated — OK"
          else
            echo "ERROR: release_notes.md was not updated in this PR."
            echo "Run /release-notes to generate the update, or edit release_notes.md manually."
            exit 1
          fi
```

---

## 4. CONTRIBUTING.md update

Add a section:

```markdown
## Release notes

Every PR to `main` must include an update to `release_notes.md`.

- Add your changes under `## Unreleased` using the Features / Fixes / Content / Other sections.
- Focus on **user-facing** changes. Summarise internal/CI changes briefly under "Other".
- Run `/release-notes` (Claude skill) to auto-generate a draft from the current branch diff.
- The CI `Check Release Notes` action will fail if `release_notes.md` is not modified.
```

---

## Files to create / modify
| File | Action |
|------|--------|
| `release_notes.md` | Create — initial content with Unreleased stub |
| `.github/workflows/cd.yml` | Modify — replace inline note generation with `release_notes.md` reader |
| `.github/workflows/check-release-notes.yml` | Create — new CI check |
| `CONTRIBUTING.md` | Modify — add release notes section |

#!/usr/bin/env bash
# Ensures Flutter FLUTTER_VERSION is available at /opt/flutter on Linux.
# Safe to run repeatedly — exits early if the correct version is already present.
# Runs automatically via the SessionStart hook in .claude/settings.json.

set -euo pipefail

FLUTTER_VERSION="3.41.6"
FLUTTER_DIR="/opt/flutter"
FLUTTER_BIN="$FLUTTER_DIR/bin/flutter"

is_correct_version() {
  "$FLUTTER_BIN" --version --suppress-analytics 2>/dev/null \
    | grep -q "Flutter $FLUTTER_VERSION"
}

if [ -f "$FLUTTER_BIN" ] && is_correct_version; then
  echo "Flutter $FLUTTER_VERSION already installed at $FLUTTER_DIR"
else
  echo "Flutter $FLUTTER_VERSION not found — installing..."
  ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/$ARCHIVE"
  TMP="/tmp/$ARCHIVE"

  echo "Downloading $URL ..."
  curl -fSL "$URL" -o "$TMP"

  echo "Extracting to /opt/ ..."
  rm -rf "$FLUTTER_DIR"
  tar xf "$TMP" -C /opt/
  rm -f "$TMP"

  echo "Flutter $FLUTTER_VERSION installed."
fi

# Allow git operations inside the SDK when running as root.
git config --global --add safe.directory "$FLUTTER_DIR" 2>/dev/null || true

echo "Running flutter pub get..."
"$FLUTTER_BIN" pub get
echo "Flutter ready."

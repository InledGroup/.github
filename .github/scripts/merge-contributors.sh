#!/usr/bin/env bash
set -euo pipefail

CONTRIBUTORS_FILE="contributors.md"
README_FILE="${1:-profile/README.md}"
START_MARKER="<!-- CONTRIBUTORS-START -->"
END_MARKER="<!-- CONTRIBUTORS-END -->"

if [ ! -f "$CONTRIBUTORS_FILE" ]; then
  echo "Error: $CONTRIBUTORS_FILE not found"
  exit 1
fi

if [ ! -f "$README_FILE" ]; then
  echo "Error: $README_FILE not found"
  exit 1
fi

CONTRIBUTORS_CONTENT=$(cat "$CONTRIBUTORS_FILE")

if grep -q "$START_MARKER" "$README_FILE"; then
  awk -v start="$START_MARKER" -v end="$END_MARKER" -v content="$CONTRIBUTORS_CONTENT" '
    $0 ~ start { print; print content; skip=1; next }
    $0 ~ end { skip=0 }
    !skip { print }
  ' "$README_FILE" > "${README_FILE}.tmp"
  mv "${README_FILE}.tmp" "$README_FILE"
  echo "Updated existing contributors section in $README_FILE"
else
  {
    cat "$README_FILE"
    echo ""
    echo "$START_MARKER"
    echo "$CONTRIBUTORS_CONTENT"
    echo "$END_MARKER"
  } > "${README_FILE}.tmp"
  mv "${README_FILE}.tmp" "$README_FILE"
  echo "Appended contributors section to $README_FILE"
fi

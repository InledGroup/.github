#!/usr/bin/env bash
set -euo pipefail

JSON_FILE="contributors.json"
README_FILE="${1:-profile/README.md}"
START_MARKER="<!-- CONTRIBUTORS-START -->"
END_MARKER="<!-- CONTRIBUTORS-END -->"

if [ ! -f "$JSON_FILE" ]; then
  echo "Error: $JSON_FILE not found"
  exit 1
fi

if [ ! -f "$README_FILE" ]; then
  echo "Error: $README_FILE not found"
  exit 1
fi

TOTAL=$(jq -r '.totalContributors' "$JSON_FILE")
UPDATED=$(jq -r '.lastUpdated' "$JSON_FILE")

CONTENT="Updated: \`$UPDATED\` · Total: **$TOTAL** contributors\n\n"
CONTENT+="<div align=\"center\">\n<table width=\"100%\"><tr>"
COL=0

while IFS=$'\t' read -r LOGIN AVATAR; do
  CONTENT+="<td align=\"center\" width=\"14%\" style=\"padding:8px 0\"><a href=\"https://github.com/$LOGIN\" target=\"_blank\"><img src=\"${AVATAR}?s=80&v=4\" width=\"50\" alt=\"@$LOGIN\" loading=\"lazy\" style=\"border-radius:50%\"><br><sub><b>@$LOGIN</b></sub></a></td>"
  COL=$((COL + 1))
  if [ $COL -eq 6 ]; then
    CONTENT+="</tr><tr>"
    COL=0
  fi
done < <(jq -r '.contributors | sort_by(-.contributions) | .[] | [.login, .avatar_url] | @tsv' "$JSON_FILE")

if [ $COL -gt 0 ] && [ $COL -lt 6 ]; then
  for _ in $(seq $COL 5); do
    CONTENT+="<td></td>"
  done
fi

CONTENT+="</tr></table>\n</div>"

if grep -q "$START_MARKER" "$README_FILE"; then
  awk -v start="$START_MARKER" -v end="$END_MARKER" -v content="$(echo -e "$CONTENT")" '
    $0 ~ start { print; print content; skip=1; next }
    $0 ~ end { skip=0 }
    !skip { print }
  ' "$README_FILE" > "${README_FILE}.tmp"
  mv "${README_FILE}.tmp" "$README_FILE"
  echo "Updated contributors section in $README_FILE"
else
  {
    cat "$README_FILE"
    echo ""
    echo "$START_MARKER"
    echo -e "$CONTENT"
    echo "$END_MARKER"
  } > "${README_FILE}.tmp"
  mv "${README_FILE}.tmp" "$README_FILE"
  echo "Appended contributors section to $README_FILE"
fi

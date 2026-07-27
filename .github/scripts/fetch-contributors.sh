#!/usr/bin/env bash
set -euo pipefail

ORG="${1:?Usage: $0 <organization> <output.json>}"
OUTPUT="${2:?Usage: $0 <organization> <output.json>}"

echo "Fetching repositories for $ORG..."

REPO_DATA=$(mktemp)
trap 'rm -f "$REPO_DATA"' EXIT

gh api --paginate "/orgs/$ORG/repos?type=public&per_page=100" > "$REPO_DATA"

FORKS=$(cat "$REPO_DATA" | jq -r '.[] | select(.fork == true) | .full_name')
REPOS=$(cat "$REPO_DATA" | jq -r '.[] | select(.fork == false) | .full_name')

TOTAL_REPOS=$(cat "$REPO_DATA" | jq 'length')
TOTAL_FORKS=$(echo "$FORKS" | grep -c . || echo 0)
echo "Found $TOTAL_REPOS repos, $TOTAL_FORKS forks (excluded), $((TOTAL_REPOS - TOTAL_FORKS)) originals"

TMPFILE=$(mktemp)
trap 'rm -f "$REPO_DATA" "$TMPFILE"' EXIT

for REPO in $REPOS; do
  echo "  Scanning $REPO..."
  gh api --paginate "/repos/$REPO/contributors?per_page=100" \
    --jq '.[] | select(.type == "User") | "\(.login)\t\(.contributions)\t\(.avatar_url)"' 2>/dev/null >> "$TMPFILE" || true
done

echo "Aggregating contributions..."

declare -A AVATARS
declare -A COUNTS

while IFS=$'\t' read -r LOGIN COUNT AVATAR; do
  [ -z "$LOGIN" ] && continue
  COUNTS[$LOGIN]=$(( ${COUNTS[$LOGIN]:-0} + COUNT ))
  AVATARS[$LOGIN]="$AVATAR"
done < "$TMPFILE"

TOTAL=${#COUNTS[@]}
echo "Found $TOTAL unique contributors"

echo "Building contributors.json..."

{
  printf '{\n'
  printf '  "organization": "%s",\n' "$ORG"
  printf '  "lastUpdated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '  "totalContributors": %d,\n' "$TOTAL"
  printf '  "contributors": [\n'

  FIRST=true
  for LOGIN in "${!COUNTS[@]}"; do
    if [ "$FIRST" = true ]; then
      FIRST=false
    else
      printf ',\n'
    fi
    printf '    {"login":"%s","contributions":%s,"avatar_url":"%s","profile":"https://github.com/%s"}' \
      "$LOGIN" "${COUNTS[$LOGIN]}" "${AVATARS[$LOGIN]}" "$LOGIN"
  done

  printf '\n  ]\n'
  printf '}\n'
} > "$OUTPUT"

echo "Done: $OUTPUT"

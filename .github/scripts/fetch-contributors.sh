#!/usr/bin/env bash
set -euo pipefail

ORG="${1:?Usage: $0 <organization> <owner-username> <output.json>}"
OWNER="${2:?Usage: $0 <organization> <owner-username> <output.json>}"
OUTPUT="${3:?Usage: $0 <organization> <owner-username> <output.json>}"

echo "Fetching repositories for $ORG..."

REPO_DATA=$(mktemp)
trap 'rm -f "$REPO_DATA"' EXIT

gh api --paginate "/orgs/$ORG/repos?type=public&per_page=100" > "$REPO_DATA"

REPOS=$(cat "$REPO_DATA" | jq -r '.[] | select(.fork == false) | .full_name')
FORKS=$(cat "$REPO_DATA" | jq -r '.[] | select(.fork == true) | .full_name')

TOTAL_REPOS=$(cat "$REPO_DATA" | jq 'length')
TOTAL_FORKS=$(echo "$FORKS" | grep -c . || echo 0)
echo "Found $TOTAL_REPOS repos, $TOTAL_FORKS forks (excluded), $((TOTAL_REPOS - TOTAL_FORKS)) originals"

TMPFILE=$(mktemp)
trap 'rm -f "$REPO_DATA" "$TMPFILE"' EXIT

declare -A AVATARS
declare -A COUNTS

scan_repo() {
  local REPO="$1"
  local SINCE=""

  echo "  $REPO: finding $OWNER's latest commit..."
  SINCE=$(gh api "/repos/$REPO/commits?author=$OWNER&per_page=1" --jq '.[0].commit.committer.date' 2>/dev/null || echo "")

  if [ -z "$SINCE" ] || [ "$SINCE" = "null" ]; then
    echo "    No commits by $OWNER found, skipping"
    return
  fi

  echo "    Since $SINCE - fetching commits..."
  gh api --paginate "/repos/$REPO/commits?since=$SINCE&per_page=100" \
    --jq '.[] | select(.author != null) | "\(.author.login)\t\(.author.avatar_url)"' 2>/dev/null > "$TMPFILE" || true

  declare -A REPO_COUNTS
  while IFS=$'\t' read -r LOGIN AVATAR; do
    [ -z "$LOGIN" ] && continue
    REPO_COUNTS[$LOGIN]=$(( ${REPO_COUNTS[$LOGIN]:-0} + 1 ))
    AVATARS[$LOGIN]="$AVATAR"
  done < "$TMPFILE"

  for LOGIN in "${!REPO_COUNTS[@]}"; do
    COUNTS[$LOGIN]=$(( ${COUNTS[$LOGIN]:-0} + ${REPO_COUNTS[$LOGIN]} ))
  done
  unset REPO_COUNTS
}

echo "Scanning original repos..."
for REPO in $REPOS; do
  scan_repo "$REPO"
done

TOTAL=${#COUNTS[@]}
echo "Found $TOTAL contributors"

if [ "$TOTAL" -eq 0 ]; then
  echo "Warning: No contributors found"
  echo '{"organization":"'"$ORG"'","lastUpdated":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","totalContributors":0,"contributors":[]}' > "$OUTPUT"
  exit 0
fi

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

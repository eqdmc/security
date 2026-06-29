#!/usr/bin/env bash
# Scored 6: OpenSSF Scorecard >= 5.0
# Input: metadata JSON
# Output: {"id":"scorecard","result":"PASS|FAIL|N/A","evidence":"Score: X.X"}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

gh_slug=$(echo "$meta" | jq -r '.metadata.gh_slug // ""')
FLOOR=5.0

result="N/A"
score="n/a"

if [ -n "$gh_slug" ]; then
  sc=$(curl -sf "https://api.scorecard.dev/projects/github.com/${gh_slug}" 2>/dev/null || echo '{}')
  score=$(echo "$sc" | jq -r '.score // "n/a"')
  if [ "$score" != "n/a" ] && [ "$score" != "null" ]; then
    result=$(awk "BEGIN {print ($score >= $FLOOR) ? \"PASS\" : \"FAIL\"}")
  fi
fi

jq -n --arg result "$result" --arg score "$score" \
  '{id: "scorecard", result: $result, evidence: "Score: \($score)"}'

#!/usr/bin/env bash
# Gate 5: Registry metadata matches source repo
# Input: metadata JSON
# Output: {"id":"registry_repo_match","result":"PASS|N/A","evidence":"..."}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

gh_slug=$(echo "$meta" | jq -r '.metadata.gh_slug // ""')
repo_url=$(echo "$meta" | jq -r '.metadata.repo_url // ""')
pkg=$(echo "$meta" | jq -r '.package // ""')
eco=$(echo "$meta" | jq -r '.ecosystem // ""')

result="N/A"
evidence="no GitHub slug available"

if [ -n "$gh_slug" ]; then
  # Verify the GitHub repo actually exists
  if gh api "repos/${gh_slug}" --jq '.full_name' &>/dev/null 2>&1; then
    result="PASS"
    evidence="${eco} → ${gh_slug}"
  else
    result="FAIL"
    evidence="${eco} → ${gh_slug} (repo not found or inaccessible)"
  fi
fi

jq -n --arg result "$result" --arg evidence "$evidence" \
  '{id: "registry_repo_match", result: $result, evidence: $evidence}'

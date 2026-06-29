#!/usr/bin/env bash
# Scored 7: Multiple maintainers (>= 2)
# Input: metadata JSON
# Output: {"id":"maintainers","result":"PASS|FAIL","evidence":"N maintainers"}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

count=$(echo "$meta" | jq -r '.metadata.maintainer_count // 0')
MIN=2

result="FAIL"
[ "$count" -ge "$MIN" ] && result="PASS"

jq -n --arg result "$result" --argjson count "$count" \
  '{id: "maintainers", result: $result, evidence: ($count | tostring) + " maintainer(s)"}'

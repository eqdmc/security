#!/usr/bin/env bash
# Gate 3: No install scripts
# Input: metadata JSON
# Output: {"id":"install_scripts","result":"PASS|FAIL","evidence":"..."}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

has_scripts=$(echo "$meta" | jq -r '.metadata.has_install_scripts // 0')
result="PASS"
[ "$has_scripts" -gt 0 ] && result="FAIL"

jq -n --arg result "$result" --argjson has_scripts "$has_scripts" \
  '{id: "install_scripts", result: $result, evidence: ($has_scripts | tostring) + " install hook(s) found"}'

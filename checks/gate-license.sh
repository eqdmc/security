#!/usr/bin/env bash
# Gate 1: License is permissive
# Input: metadata JSON (stdin or file arg)
# Output: {"id":"license","result":"PASS|FAIL","evidence":"..."}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

license=$(echo "$meta" | jq -r '.metadata.license // "unknown"')
PERMISSIVE="MIT|Apache-2.0|Apache-1.1|ISC|BSD-2-Clause|BSD-3-Clause|0BSD|BlueOak-1.0.0|Unlicense|CC0-1.0|CC-BY-3.0|CC-BY-4.0|Zlib|PSF-2.0|Python-2.0|BSL-1.0|MPL-2.0|WTFPL|Artistic-2.0|PostgreSQL|X11|NCSA|ECL-2.0"

all_permissive=true
for part in $(echo "$license" | tr ' ' '\n' | grep -v -E '^(OR|AND|WITH)$'); do
  if ! echo "$part" | grep -qE "^($PERMISSIVE)$"; then
    all_permissive=false
    break
  fi
done

result="FAIL"
[ "$all_permissive" = "true" ] && [ -n "$license" ] && result="PASS"

jq -n --arg result "$result" --arg license "$license" \
  '{id: "license", result: $result, evidence: $license}'

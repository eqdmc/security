#!/usr/bin/env bash
# Scored 10: Transitive dep count <= 500
# Input: metadata JSON
# Output: {"id":"dep_depth","result":"PASS|FAIL|N/A","evidence":"N transitive deps"}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

pkg=$(echo "$meta" | jq -r '.package // ""')
version=$(echo "$meta" | jq -r '.version // ""')
eco=$(echo "$meta" | jq -r '.ecosystem // ""')
MAX=500

result="N/A"
dep_count=-1

# Only npm and crates.io have reliable dep depth APIs
case "$eco" in
  npm)
    deps_json=$(curl -sf "https://api.deps.dev/v3alpha/systems/npm/packages/$(echo "$pkg" | sed 's|/|%2F|g')/versions/${version}:dependencies" 2>/dev/null || echo '{}')
    dep_count=$(echo "$deps_json" | jq '[.nodes // [] | .[]] | length' 2>/dev/null || echo -1)
    ;;
  crates)
    deps_json=$(curl -sf "https://api.deps.dev/v3alpha/systems/cargo/packages/${pkg}/versions/${version}:dependencies" 2>/dev/null || echo '{}')
    dep_count=$(echo "$deps_json" | jq '[.nodes // [] | .[]] | length' 2>/dev/null || echo -1)
    ;;
  flathub)
    # Flatpak apps use shared runtimes — deps are managed by the runtime, not the app
    dep_count=0
    ;;
  *)
    dep_count=-1
    ;;
esac

if [ "$dep_count" -ge 0 ]; then
  result="FAIL"
  [ "$dep_count" -le "$MAX" ] && result="PASS"
fi

jq -n --arg result "$result" --argjson dep_count "$dep_count" --argjson max "$MAX" \
  '{id: "dep_depth", result: $result, evidence: ($dep_count | tostring) + " transitive deps (max \($max))"}'

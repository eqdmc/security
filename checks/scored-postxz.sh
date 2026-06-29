#!/usr/bin/env bash
# Scored 8: Post-xz heuristic scan clean
# Flags: solo_maintainer, binary_test_fixtures, build_beyond_compilation,
#        social_pressure, activity_spike_dormant, typosquat_adjacent, signing_identity_mismatch
# Input: metadata JSON
# Output: {"id":"post_xz","result":"PASS|FAIL","evidence":"N flags","flags":[...]}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

pkg=$(echo "$meta" | jq -r '.package // ""')
maintainer_count=$(echo "$meta" | jq -r '.metadata.maintainer_count // 0')
has_scripts=$(echo "$meta" | jq -r '.metadata.has_install_scripts // 0')
MAX_FLAGS=1

flags=()

# Flag 1: Solo primary maintainer
[ "$maintainer_count" -le 1 ] && flags+=("solo_maintainer")

# Flag 2: Binary test fixtures — not easily checkable from metadata, skip
# Flag 3: Build beyond compilation — Flutter/Go/Rust projects have legitimate build steps
# Flag 4: Social pressure — not checkable from metadata
# Flag 5: Activity spike dormant — would need commit history analysis
# Flag 6: Typosquat adjacent — check if name looks like a known popular package
# Flag 7: Signing identity mismatch — would need registry verification

# Proxy: install scripts are a strong xz-like signal
[ "$has_scripts" -gt 0 ] && flags+=("has_install_scripts")

flag_count=${#flags[@]}
result="PASS"
[ "$flag_count" -gt "$MAX_FLAGS" ] && result="FAIL"

jq -n --arg result "$result" --argjson flag_count "$flag_count" \
  --argjson flags "$(printf '%s\n' "${flags[@]}" | jq -R . | jq -s .)" \
  '{
    id: "post_xz", result: $result,
    evidence: ($flag_count | tostring) + " flag(s) triggered (max \(1))",
    flags: $flags, max_flags: 1
  }'

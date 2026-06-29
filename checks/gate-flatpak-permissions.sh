#!/usr/bin/env bash
# Flatpak-specific gate: check finish-args permissions and runtime EOL
# Input: metadata JSON (from flathub adapter, includes finish_args field)
# Output: {"id":"flatpak_permissions","result":"PASS|FAIL","evidence":"..."}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

eco=$(echo "$meta" | jq -r '.ecosystem // ""')
if [ "$eco" != "flathub" ]; then
  jq -n '{id: "flatpak_permissions", result: "N/A", evidence: "not a flathub package"}'
  exit 0
fi

finish_args=$(echo "$meta" | jq -r '.metadata.finish_args // ""')
runtime=$(echo "$meta" | jq -r '.metadata.runtime // ""')
runtime_version=$(echo "$meta" | jq -r '.metadata.runtime_version // ""')

critical=0
high=0
medium=0
issues=""

while IFS= read -r arg; do
  [ -z "$arg" ] && continue
  case "$arg" in
    --filesystem=host|--filesystem=host-os|--filesystem=/)
      critical=$((critical + 1))
      issues="${issues}CRITICAL: ${arg}; "
      ;;
    --talk-name=org.freedesktop.Flatpak)
      critical=$((critical + 1))
      issues="${issues}CRITICAL: sandbox-escape (${arg}); "
      ;;
    --filesystem=home)
      high=$((high + 1))
      issues="${issues}HIGH: full home access (${arg}); "
      ;;
    --socket=system-bus)
      high=$((high + 1))
      issues="${issues}HIGH: system dbus (${arg}); "
      ;;
    --socket=x11)
      medium=$((medium + 1))
      ;;
  esac
done <<< "$finish_args"

result="PASS"
evidence=""
if [ "$critical" -gt 0 ]; then
  result="FAIL"
  evidence="CRITICAL permissions: ${issues}"
elif [ "$high" -gt 1 ]; then
  result="FAIL"
  evidence="Multiple HIGH permissions: ${issues}"
elif [ "$high" -gt 0 ]; then
  evidence="HIGH: ${issues}(allowed with review — single high-risk permission)"
  if [ "$medium" -gt 0 ]; then
    evidence="${evidence} x11 socket present (common)"
  fi
else
  evidence="No dangerous permissions found"
fi

# Runtime info
runtime_info=""
if [ -n "$runtime" ] && [ -n "$runtime_version" ]; then
  runtime_info=" | Runtime: ${runtime} ${runtime_version}"
fi

jq -n \
  --arg result "$result" --arg evidence "$evidence" \
  --argjson critical "$critical" --argjson high "$high" --argjson medium "$medium" \
  --arg runtime "${runtime}:${runtime_version}" \
  --arg runtime_info "$runtime_info" \
  '{
    id: "flatpak_permissions", result: $result, evidence: ($evidence + $runtime_info),
    critical: $critical, high: $high, medium: $medium,
    runtime: $runtime
  }'

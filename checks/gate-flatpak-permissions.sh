#!/usr/bin/env bash
# Flatpak gate: check finish-args permissions and runtime EOL
# Input: metadata JSON (from flathub adapter, includes finish_args/runtime fields)
# Output: {"id":"flatpak_permissions","result":"PASS|FAIL","evidence":"..."}
#
# Dangerous permission categories:
#   CRITICAL (automatic FAIL): --filesystem=host, --filesystem=/,
#     --talk-name=org.freedesktop.Flatpak (sandbox escape),
#     --filesystem=home (full home access — read SSH keys, dotfiles, browser profiles)
#   HIGH (FAIL if 2+): --socket=system-bus
#   MEDIUM (info only): --socket=x11
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

eco=$(echo "$meta" | jq -r '.ecosystem // ""')
if [ "$eco" != "flathub" ]; then
  jq -n '{id: "flatpak_permissions", result: "N/A", evidence: "not a flathub package"}'
  exit 0
fi

finish_args=$(echo "$meta" | jq -r '.metadata.finish_args // ""')
app_id=$(echo "$meta" | jq -r '.metadata.app_id // ""')
runtime=$(echo "$meta" | jq -r '.metadata.runtime // ""')
runtime_version=$(echo "$meta" | jq -r '.metadata.runtime_version // ""')

# ── Manifest fetch validation ────────────────────────────────────────
# If finish_args is empty AND we have an app_id, the fetch likely failed.
# Fail-closed: we can't verify permissions → BLOCK.
manifest_fetch_ok=true
if [ -z "$finish_args" ] && [ -n "$app_id" ]; then
  manifest_fetch_ok=false
fi

# ── Permission analysis ──────────────────────────────────────────────
critical=0
high=0
medium=0
issues=""

while IFS= read -r arg; do
  [ -z "$arg" ] && continue
  case "$arg" in
    # CRITICAL: sandbox escape or full filesystem access
    --filesystem=host|--filesystem=host-os|--filesystem=/)
      critical=$((critical + 1))
      issues="${issues}CRITICAL: full host access (${arg}); "
      ;;
    --talk-name=org.freedesktop.Flatpak)
      critical=$((critical + 1))
      issues="${issues}CRITICAL: sandbox-escape (${arg}); "
      ;;
    --filesystem=home)
      critical=$((critical + 1))
      issues="${issues}CRITICAL: full home access (${arg}); "
      ;;
    # HIGH: system-level access
    --socket=system-bus)
      high=$((high + 1))
      issues="${issues}HIGH: system dbus (${arg}); "
      ;;
    # MEDIUM: common, informational only
    --socket=x11)
      medium=$((medium + 1))
      ;;
  esac
done <<< "$finish_args"

# ── Verdict ──────────────────────────────────────────────────────────
result="PASS"
evidence=""

if [ "$manifest_fetch_ok" = "false" ]; then
  result="FAIL"
  evidence="Cannot verify permissions — failed to fetch manifest for ${app_id}"
elif [ "$critical" -gt 0 ]; then
  result="FAIL"
  evidence="CRITICAL permissions: ${issues}"
elif [ "$high" -gt 1 ]; then
  result="FAIL"
  evidence="Multiple HIGH permissions: ${issues}"
elif [ "$high" -gt 0 ]; then
  evidence="HIGH: ${issues}(allowed with review)"
elif [ -z "$finish_args" ]; then
  # Empty but app_id was also empty or metadata didn't include finish_args
  # This could happen with an older adapter version — PASS with note
  evidence="No finish-args available in metadata"
else
  evidence="No dangerous permissions found"
fi

if [ "$medium" -gt 0 ]; then
  evidence="${evidence} | x11 socket present (common)"
fi

# ── Runtime EOL check ────────────────────────────────────────────────
# Flathub only keeps active runtime branches. If the app's runtime-version
# is not available in the remote index, it's likely EOL.
runtime_ok="unknown"
runtime_note=""
if [ -n "$runtime" ] && [ -n "$runtime_version" ]; then
  runtime_ok="checking"
  # Check if runtime is still available in flathub remote
  runtime_ref="runtime/${runtime}/aarch64/${runtime_version}"
  if flatpak remote-ls flathub --runtime --columns=ref 2>/dev/null \
    | grep -qF "$runtime_ref"; then
    runtime_ok="current"
  else
    runtime_ref_alt="runtime/${runtime}/x86_64/${runtime_version}"
    if flatpak remote-ls flathub --runtime --columns=ref 2>/dev/null \
      | grep -qF "$runtime_ref_alt"; then
      runtime_ok="current"
    else
      runtime_ok="eol"
      runtime_note="WARNING: ${runtime} ${runtime_version} not available in flathub — likely EOL"
    fi
  fi
fi

if [ -n "$runtime" ] && [ -n "$runtime_version" ]; then
  evidence="${evidence} | Runtime: ${runtime} ${runtime_version}"
  if [ "$runtime_ok" = "eol" ]; then
    evidence="${evidence} [EOL]"
  fi
fi

jq -n \
  --arg result "$result" --arg evidence "$evidence" \
  --argjson critical "$critical" --argjson high "$high" --argjson medium "$medium" \
  --arg runtime_ok "$runtime_ok" \
  --arg runtime "${runtime}:${runtime_version}" \
  --arg app_id "$app_id" \
  '{
    id: "flatpak_permissions", result: $result, evidence: $evidence,
    critical: $critical, high: $high, medium: $medium,
    runtime: $runtime, runtime_status: $runtime_ok,
    app_id: $app_id
  }'

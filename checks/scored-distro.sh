#!/usr/bin/env bash
# Scored 9: Included in well-known registry
# Input: metadata JSON
# Output: {"id":"distro_inclusion","result":"PASS|FAIL","evidence":"..."}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

eco=$(echo "$meta" | jq -r '.ecosystem // ""')

# All supported ecosystems count as "included in well-known registry"
case "$eco" in
  npm|pypi|crates|flathub|github)
    result="PASS"
    evidence="Available on ${eco}"
    ;;
  *)
    result="FAIL"
    evidence="Ecosystem ${eco} not in known registries"
    ;;
esac

jq -n --arg result "$result" --arg evidence "$evidence" \
  '{id: "distro_inclusion", result: $result, evidence: $evidence}'

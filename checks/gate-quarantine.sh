#!/usr/bin/env bash
# Gate 4: Published >= 7 days ago (quarantine)
# Input: metadata JSON
# Output: {"id":"quarantine","result":"PASS|FAIL|N/A","evidence":"..."}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

pub_time=$(echo "$meta" | jq -r '.metadata.publish_time // "unknown"')
MIN_AGE_DAYS=7
now_epoch=$(date +%s)

result="N/A"
age_days=-1
evidence="publish_time unknown, quarantine N/A"

if [ "$pub_time" != "unknown" ] && [ -n "$pub_time" ]; then
  pub_epoch=$(date -d "$pub_time" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${pub_time%%.*}" +%s 2>/dev/null || echo 0)
  if [ "$pub_epoch" -gt 0 ]; then
    age_days=$(( (now_epoch - pub_epoch) / 86400 ))
    result="FAIL"
    [ "$age_days" -ge "$MIN_AGE_DAYS" ] && result="PASS"
    evidence="Published ${pub_time} (${age_days}d ago), quarantine ≥ ${MIN_AGE_DAYS}d: $result"
  fi
fi

jq -n --arg result "$result" --arg evidence "$evidence" --argjson age_days "$age_days" \
  '{id: "quarantine", result: $result, evidence: $evidence, age_days: $age_days}'

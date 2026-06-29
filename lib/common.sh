# Common library for eqdmc/security vetting system
# Source: . lib/common.sh

BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}➜${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }
step()  { echo; echo -e "${BOLD}━━━ $* ━━━${NC}"; }
ok()    { echo -e "  ${GREEN}✔${NC} $*"; }
skip()  { echo -e "  ${DIM}─ $*${NC}"; }
die()   { error "$*"; exit 1; }

# Temp dir for current vet run (cleaned up on exit)
VET_TEMP=$(mktemp -d /tmp/eqdmc-vet-XXXXXX)
trap 'rm -rf "$VET_TEMP"' EXIT

# Run a single check script and aggregate results
# Usage: run_check <check-type> <check-id> <script-path> <metadata-file>
#   check-type: "gate" or "scored"
#   check-id: unique identifier matching vetting.yaml
#   script-path: path to the check script
#   metadata-file: JSON file with package metadata
# Output: JSON line to stdout
run_check() {
  local type="$1" cid="$2" script="$3" meta="$4"
  if [ ! -x "$script" ]; then
    echo "{\"type\":\"$type\",\"id\":\"$cid\",\"result\":\"N/A\",\"evidence\":\"check script not found: $script\"}"
    return 0
  fi
  local result
  result=$("$script" "$meta" 2>/dev/null) || true
  if [ -z "$result" ] || ! echo "$result" | jq -e . >/dev/null 2>&1; then
    echo "{\"type\":\"$type\",\"id\":\"$cid\",\"result\":\"ERROR\",\"evidence\":\"check script failed or produced invalid output\"}"
    return 0
  fi
  echo "$result" | jq --arg type "$type" '.type = $type' -c
}

# Determine verdict from results JSON array
# Usage: compute_verdict <results-json-array>
compute_verdict() {
  local results="$1"
  local gates_pass=0 gates_total=0 scored_pass=0 scored_total=0

  while IFS= read -r line; do
    local r_type r_id r_result
    r_type=$(echo "$line" | jq -r '.type')
    r_id=$(echo "$line" | jq -r '.id')
    r_result=$(echo "$line" | jq -r '.result')
    [ "$r_result" = "N/A" ] && continue
    if [ "$r_type" = "gate" ]; then
      gates_total=$((gates_total + 1))
      [ "$r_result" = "PASS" ] && gates_pass=$((gates_pass + 1))
    elif [ "$r_type" = "scored" ]; then
      scored_total=$((scored_total + 1))
      [ "$r_result" = "PASS" ] && scored_pass=$((scored_pass + 1))
    fi
  done <<< "$(echo "$results" | jq -c '.[]')"

  local all_gates=false scored_met=false verdict="BLOCKED"
  [ "$gates_pass" -eq "$gates_total" ] && [ "$gates_total" -gt 0 ] && all_gates=true
  [ "$scored_pass" -ge 3 ] || [ "$scored_total" -lt 3 ] && scored_met=true
  [ "$all_gates" = "true" ] && [ "$scored_met" = "true" ] && verdict="APPROVED"

  jq -n \
    --argjson gates_pass "$gates_pass" --argjson gates_total "$gates_total" \
    --argjson scored_pass "$scored_pass" --argjson scored_total "$scored_total" \
    --arg verdict "$verdict" \
    '{gates_pass: $gates_pass, gates_total: $gates_total,
      scored_pass: $scored_pass, scored_total: $scored_total,
      verdict: $verdict}'
}

# Current timestamp in ISO-8601
now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Current date in YYYY-MM-DD
now_date() {
  date -u +"%Y-%m-%d"
}

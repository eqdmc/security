#!/usr/bin/env bash
# Gate 2: Zero P1+/P1 CVEs (multi-signal CVE prioritization)
# Uses OSV.dev + CISA KEV + FIRST EPSS
# Input: metadata JSON with gh_slug or package name
# Output: {"id":"cve","result":"PASS|FAIL","evidence":"...","details":[...]}
set -euo pipefail

META="${1:-/dev/stdin}"
meta=$(cat "$META")

pkg=$(echo "$meta" | jq -r '.package // ""')
eco=$(echo "$meta" | jq -r '.ecosystem // ""')
gh_slug=$(echo "$meta" | jq -r '.metadata.gh_slug // ""')
version=$(echo "$meta" | jq -r '.version // ""')

EPSS_THRESHOLD=0.2
CVSS_THRESHOLD=6.0

# Map ecosystem to OSV ecosystem name
osv_eco=""
case "$eco" in
  npm)    osv_eco="npm" ;;
  pypi)   osv_eco="PyPI" ;;
  flathub) osv_eco="GitHub" ;;
  crates) osv_eco="crates.io" ;;
  *)      osv_eco="" ;;
esac

# Query OSV
osv_query='{}'
if [ -n "$osv_eco" ] && [ -n "$pkg" ]; then
  osv_query=$(curl -sf -X POST "https://api.osv.dev/v1/query" \
    -H "Content-Type: application/json" \
    -d "{\"package\":{\"name\":\"${pkg}\",\"ecosystem\":\"${osv_eco}\"}}" 2>/dev/null || echo '{}')
fi

# Also try GitHub slug if available
if [ "$(echo "$osv_query" | jq '.vulns // [] | length')" = "0" ] && [ -n "$gh_slug" ]; then
  osv_query=$(curl -sf -X POST "https://api.osv.dev/v1/query" \
    -H "Content-Type: application/json" \
    -d "{\"package\":{\"name\":\"${gh_slug}\",\"ecosystem\":\"GitHub\"}}" 2>/dev/null || echo '{}')
fi

vuln_total=$(echo "$osv_query" | jq '[.vulns // [] | .[]] | length')

# Load KEV
kev_json=$(curl -sf "https://www.cisa.gov/sites/default/files/feeds/known-exploited-vulnerabilities.json" 2>/dev/null || echo '{}')
kev_loaded=false
echo "$kev_json" | jq -e '.vulnerabilities' >/dev/null 2>&1 && kev_loaded=true

p1_plus=0; p1=0; p2=0; p3=0; p4=0; unscoped=0
vuln_details="[]"

severity_to_cvss() {
  case "${1^^}" in
    CRITICAL) echo "9.5" ;;
    HIGH)     echo "7.5" ;;
    MODERATE|MEDIUM) echo "5.5" ;;
    LOW)      echo "2.5" ;;
    *)        echo "none" ;;
  esac
}

if [ "$vuln_total" -gt 0 ]; then
  details_arr="["
  first=true
  vuln_count=$(echo "$osv_query" | jq '[.vulns // [] | .[]] | length')

  for i in $(seq 0 $((vuln_count - 1))); do
    vuln=$(echo "$osv_query" | jq ".vulns[$i]")
    ghsa_id=$(echo "$vuln" | jq -r '.id')
    cve_id=$(echo "$vuln" | jq -r '[.aliases // [] | .[] | select(startswith("CVE-"))] | first // ""')
    severity=$(echo "$vuln" | jq -r '.database_specific.severity // "unknown"' | tr '[:lower:]' '[:upper:]')
    summary=$(echo "$vuln" | jq -r '.summary // ""' | tr '"' "'")
    cvss_score=$(severity_to_cvss "$severity")

    epss_score="none"
    if [ -n "$cve_id" ]; then
      epss_resp=$(curl -sf "https://api.first.org/data/v1/epss?cve=${cve_id}" 2>/dev/null || echo '{}')
      epss_score=$(echo "$epss_resp" | jq -r '.data[0].epss // "none"' 2>/dev/null)
    fi

    in_kev=false
    if [ "$kev_loaded" = "true" ] && [ -n "$cve_id" ]; then
      kev_match=$(echo "$kev_json" | jq -r ".vulnerabilities[] | select(.cveID == \"${cve_id}\") | .cveID" 2>/dev/null)
      [ -n "$kev_match" ] && in_kev=true
    fi

    priority="P4"
    if [ "$in_kev" = "true" ]; then
      priority="P1+"; p1_plus=$((p1_plus + 1))
    elif [ "$cvss_score" != "none" ] && [ "$epss_score" != "none" ]; then
      cvss_high=$(awk "BEGIN {print ($cvss_score >= $CVSS_THRESHOLD) ? 1 : 0}")
      epss_high=$(awk "BEGIN {print ($epss_score >= $EPSS_THRESHOLD) ? 1 : 0}")
      if [ "$cvss_high" -eq 1 ] && [ "$epss_high" -eq 1 ]; then
        priority="P1"; p1=$((p1 + 1))
      elif [ "$cvss_high" -eq 1 ] && [ "$epss_high" -eq 0 ]; then
        priority="P2"; p2=$((p2 + 1))
      elif [ "$cvss_high" -eq 0 ] && [ "$epss_high" -eq 1 ]; then
        priority="P3"; p3=$((p3 + 1))
      else
        priority="P4"; p4=$((p4 + 1))
      fi
    elif [ "$cvss_score" != "none" ]; then
      # EPSS unavailable — conservative default:
      # CRITICAL (cvss >= 9.0) with unknown EPSS → P1 (assume exploited)
      # HIGH (cvss >= 6.0) with unknown EPSS → P2 (current behavior)
      # LOW (cvss < 6.0) with unknown EPSS → P4
      cvss_critical=$(awk "BEGIN {print ($cvss_score >= 9.0) ? 1 : 0}")
      if [ "$cvss_critical" -eq 1 ]; then
        priority="P1"; p1=$((p1 + 1))
      else
        cvss_high=$(awk "BEGIN {print ($cvss_score >= $CVSS_THRESHOLD) ? 1 : 0}")
        [ "$cvss_high" -eq 1 ] && priority="P2" && p2=$((p2 + 1)) || { priority="P4"; p4=$((p4 + 1)); }
      fi
    else
      priority="unscored"; unscoped=$((unscoped + 1))
    fi

    [ "$first" = "true" ] && first=false || details_arr="${details_arr},"
    details_arr="${details_arr}{\"id\":\"${ghsa_id}\",\"cve\":\"${cve_id}\",\"severity\":\"${severity}\",\"cvss_est\":\"${cvss_score}\",\"epss\":\"${epss_score}\",\"kev\":${in_kev},\"priority\":\"${priority}\",\"summary\":\"${summary}\"}"
  done
  details_arr="${details_arr}]"
  vuln_details="$details_arr"
fi

blocking=$((p1_plus + p1))
result="PASS"
[ "$blocking" -gt 0 ] && result="FAIL"

jq -n \
  --arg result "$result" --argjson vuln_total "$vuln_total" \
  --argjson p1_plus "$p1_plus" --argjson p1 "$p1" \
  --argjson p2 "$p2" --argjson p3 "$p3" --argjson p4 "$p4" \
  --argjson blocking "$blocking" --argjson vuln_details "$vuln_details" \
  '{
    id: "cve", result: $result,
    evidence: ($vuln_total | tostring) + " total vulns, " + ($blocking | tostring) + " blocking",
    quadrant: {"P1+_kev": $p1_plus, "P1_high_likely": $p1, "P2_high_unlikely": $p2, "P3_low_likely": $p3, "P4_low_unlikely": $p4},
    blocking: $blocking,
    details: $vuln_details
  }'

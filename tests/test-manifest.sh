#!/usr/bin/env bash
# test-manifest.sh — Integration tests for the SSOT manifest system.
# Tests: JSON validity, field presence, ADR cross-reference, CRUD lifecycle.
# Usage: bash tests/test-manifest.sh
set -uo pipefail  # no -e: we handle individual test failures manually

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$SCRIPT_DIR/packages/manifest.json"
VET_MANIFEST="$SCRIPT_DIR/bin/vet-manifest"

PASS=0 FAIL=0
pass() { PASS=$((PASS+1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

echo "=== Manifest integration tests ==="
echo ""

# Test 1: Manifest is valid JSON
echo "T1: manifest.json is valid JSON"
jq '.' "$MANIFEST" > /dev/null 2>&1 && pass "valid JSON" || fail "invalid JSON"

# Test 2: Required top-level fields
echo "T2: required fields"
for field in version updated_at vetted; do
  jq -e ".$field" "$MANIFEST" > /dev/null 2>&1 && pass "has field: $field" || fail "missing: $field"
done

# Test 3: Each vetted entry has required fields
echo "T3: required fields on vetted entries"
jq -r '.vetted[] | "\(.id):\(.version):\(.ecosystem):\(.adr):\(.pinned)"' "$MANIFEST" | while IFS=: read -r id ver eco adr pinned; do
  [ -n "$id" ] && pass "$id: id present" || fail "$id: missing id"
  [ "$pinned" = "true" ] && pass "$id: pinned=true" || fail "$id: not pinned"
done

# Test 4: No duplicate IDs
echo "T4: no duplicate IDs"
total=$(jq '[.vetted[].id] | length' "$MANIFEST" 2>/dev/null || echo 0)
unique=$(jq '[.vetted[].id] | unique | length' "$MANIFEST" 2>/dev/null || echo 0)
dupes=$((total - unique))
[ "$dupes" -eq 0 ] && pass "no duplicate IDs" || fail "$dupes duplicate ID(s)"

# Test 5: ADR files exist
echo "T5: ADR file references exist"
jq -r '.vetted[] | .adr' "$MANIFEST" | while read adr; do
  [ -f "$SCRIPT_DIR/$adr" ] && pass "ADR exists: $adr" || fail "ADR missing: $adr"
done

# Test 6: vet-manifest list returns JSON
echo "T6: vet-manifest list"
result=$("$VET_MANIFEST" list 2>&1)
echo "$result" | jq 'empty' > /dev/null 2>&1 && pass "list returns JSON array" || fail "list not JSON: $result"

# Test 7: vet-manifest search
echo "T7: vet-manifest search"
result=$("$VET_MANIFEST" search "LocalSend" 2>&1)
count=$(echo "$result" | jq 'length' 2>/dev/null || echo 0)
[ "$count" -ge 1 ] && pass "search found $count result(s)" || fail "search returned no results"

# Test 8: vet-manifest info
echo "T8: vet-manifest info"
result=$("$VET_MANIFEST" info "org.localsend.localsend_app" 2>&1)
name=$(echo "$result" | jq -r '.name // "empty"' 2>/dev/null)
[ "$name" = "LocalSend" ] && pass "info returned correct name" || fail "info wrong: $name"

# Test 9: vet-manifest status (approved)
echo "T9: vet-manifest status approved"
result=$("$VET_MANIFEST" status "org.localsend.localsend_app" 2>&1)
echo "$result" | head -1 | grep -q "APPROVED" && pass "status shows APPROVED" || fail "status not APPROVED"

# Test 10: Request → Pending → Reject lifecycle
echo "T10: request lifecycle"
result=$("$VET_MANIFEST" request "test-pkg-lifecycle" --eco flathub --reason "Integration test" 2>&1)
echo "$result" | grep -q "REQUEST_SUBMITTED" && pass "request submitted" || fail "request failed: $result"

result=$("$VET_MANIFEST" status "test-pkg-lifecycle" 2>&1)
echo "$result" | head -1 | grep -q "PENDING" && pass "status shows PENDING" || fail "status not PENDING"

result=$("$VET_MANIFEST" reject "test-pkg-lifecycle" "Integration test cleanup" 2>&1)
echo "$result" | grep -q "REJECTED" && pass "rejected" || fail "reject failed: $result"

result=$("$VET_MANIFEST" status "test-pkg-lifecycle" 2>&1)
echo "$result" | head -1 | grep -q "REJECTED" && pass "status shows REJECTED" || fail "status not REJECTED"

# Test 11: vetting-policy.json is valid JSON
echo "T11: vetting-policy.json is valid"
POLICY="$SCRIPT_DIR/packages/vetting-policy.json"
jq '.' "$POLICY" > /dev/null 2>&1 && pass "valid JSON" || fail "invalid JSON"
for section in blocked_commands_patterns allowed_commands ecosystem_adapters; do
  jq -e ".$section" "$POLICY" > /dev/null 2>&1 && pass "has section: $section" || fail "missing: $section"
done

echo ""
echo "=== Results: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ] || exit 1

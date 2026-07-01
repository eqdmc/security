# ADR-0017: `npm/@anthropic-ai/claude-code` — BLOCKED

- **Status:** Proposed
- **Date:** 2026-06-30
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** BLOCKED (gates: 1/4, scored: 4/4)

## 1. Package

- **Name:** `@anthropic-ai/claude-code`
- **Ecosystem:** npm
- **Canonical source:** 
- **Version adopted:** `2.1.186`
- **License:** SEE LICENSE IN README.md

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | FAIL | `SEE LICENSE IN README.md` |
| 2 | Zero P1+/P1 CVEs | FAIL | 27 total vulns, 1 blocking |
| 3 | No install scripts | FAIL | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2026-06-22T18:03:48.955Z (7d ago) |
| 5 | Registry-repo match | N/A | npm ->  |

### CVE quadrant breakdown (CVSS + EPSS + KEV)

| Priority | Count | Action | Description |
|---|---|---|---|
| P1+ (KEV) | 0 | BLOCK | Confirmed exploited in the wild |
| P1 (high/likely) | 0 | BLOCK | CVSS >= 6.0 AND EPSS >= 0.2 |
| P2 (high/unlikely) | 20 | WARN | CVSS >= 6.0, EPSS < 0.2 |
| P3 (low/likely) | 1 | WARN | CVSS < 6.0, EPSS >= 0.2 |
| P4 (low/unlikely) | 5 | ACCEPT | CVSS < 6.0, EPSS < 0.2 |

### Scored checks (>= 3 must PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 6 | OpenSSF Scorecard >= 5.0 | N/A | Score: n/a |
| 7 | Multiple maintainers | PASS | 13 maintainer(s): benjmann, dylanc-anthropic, ejlangev-ant, felixrieseberg-anthropic, joan-anthropic, jv-anthropic, nikhil-anthropic, noahz-anthropic, ollie-ant-2025, packy-anthropic, sbidasaria, wolffiex, zak-anthropic |
| 8 | Post-xz heuristic clean | PASS | < 2 flags triggered |
| 9 | Distro inclusion | PASS | Available on npm |
| 10 | Dep depth <= 500 | PASS | -1 transitive deps |

## 3. Post-xz heuristic scan

- [ ] Solo primary maintainer
- [ ] Binary test fixtures with no human-readable origin
- [ ] Build system doing work beyond compilation
- [ ] Social pressure to merge quickly
- [ ] Suspicious activity spike on previously-dormant package
- [ ] Typosquat-adjacent name
- [ ] Mismatched signing identity

## 4. References

- Upstream: 
- OSV: https://osv.dev/list?ecosystem=npm&q=@anthropic-ai/claude-code


## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-30 | Initial ADR (automated via vet) | @eqdmc/security-review |

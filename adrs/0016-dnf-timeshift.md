# ADR-0016: `dnf/timeshift` — BLOCKED

- **Status:** Proposed
- **Date:** 2026-06-30
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** BLOCKED (gates: 3/4, scored: 1/3)

## 1. Package

- **Name:** `timeshift`
- **Ecosystem:** dnf
- **Canonical source:** https://github.com/linuxmint/timeshift
- **Version adopted:** `25.12.4-2.fc44`
- **License:** GPL-3.0-or-later OR LGPL-3.0-or-later

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | FAIL | `GPL-3.0-or-later OR LGPL-3.0-or-later` |
| 2 | Zero P1+/P1 CVEs | PASS | 0 total vulns, 0 blocking |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | N/A | Published  (N/A) |
| 5 | Registry-repo match | PASS | dnf -> linuxmint/timeshift |

### CVE quadrant breakdown (CVSS + EPSS + KEV)

| Priority | Count | Action | Description |
|---|---|---|---|
| P1+ (KEV) | 0 | BLOCK | Confirmed exploited in the wild |
| P1 (high/likely) | 0 | BLOCK | CVSS >= 6.0 AND EPSS >= 0.2 |
| P2 (high/unlikely) | 0 | WARN | CVSS >= 6.0, EPSS < 0.2 |
| P3 (low/likely) | 0 | WARN | CVSS < 6.0, EPSS >= 0.2 |
| P4 (low/unlikely) | 0 | ACCEPT | CVSS < 6.0, EPSS < 0.2 |

### Scored checks (>= 3 must PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 6 | OpenSSF Scorecard >= 5.0 | N/A | Score: n/a |
| 7 | Multiple maintainers | FAIL | 1 maintainer(s): Fedora Project |
| 8 | Post-xz heuristic clean | PASS | < 2 flags triggered |
| 9 | Distro inclusion | FAIL | Available on dnf |
| 10 | Dep depth <= 500 | N/A | -1 transitive deps |

## 3. Post-xz heuristic scan

- [x] Solo primary maintainer
- [ ] Binary test fixtures with no human-readable origin
- [ ] Build system doing work beyond compilation
- [ ] Social pressure to merge quickly
- [ ] Suspicious activity spike on previously-dormant package
- [ ] Typosquat-adjacent name
- [ ] Mismatched signing identity

## 4. References

- Upstream: https://github.com/linuxmint/timeshift
- OSV: https://osv.dev/list?ecosystem=dnf&q=timeshift
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/linuxmint/timeshift

## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-30 | Initial ADR (automated via vet) | @eqdmc/security-review |

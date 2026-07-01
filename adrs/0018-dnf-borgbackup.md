# ADR-0018: `dnf/borgbackup` — BLOCKED

- **Status:** Proposed
- **Date:** 2026-06-30
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** BLOCKED (gates: 2/3, scored: 1/3)

## 1. Package

- **Name:** `borgbackup`
- **Ecosystem:** dnf
- **Canonical source:** https://borgbackup.readthedocs.org
- **Version adopted:** `1.4.4-1.fc44`
- **License:** BSD-3-clause AND zlib AND Apache-2.0 AND PSF-2.0

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | FAIL | `BSD-3-clause AND zlib AND Apache-2.0 AND PSF-2.0` |
| 2 | Zero P1+/P1 CVEs | PASS | 0 total vulns, 0 blocking |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | N/A | Published  (N/A) |
| 5 | Registry-repo match | N/A | dnf ->  |

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

- Upstream: https://borgbackup.readthedocs.org
- OSV: https://osv.dev/list?ecosystem=dnf&q=borgbackup


## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-30 | Initial ADR (automated via vet) | @eqdmc/security-review |

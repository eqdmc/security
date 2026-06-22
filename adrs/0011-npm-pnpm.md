# ADR-0011: `npm/pnpm` — APPROVED

- **Status:** Proposed
- **Date:** 2026-06-22
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** APPROVED (gates: 5/5, scored: 5/5)

## 1. Package

- **Name:** `pnpm`
- **Ecosystem:** npm
- **Canonical source:** https://github.com/pnpm/pnpm
- **Version adopted:** `11.6.0`
- **License:** MIT

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | PASS | `MIT` |
| 2 | Zero P1+/P1 CVEs | PASS | 0 total vulns, 0 blocking (P1+: 0, P1: 0) |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2026-06-11T23:06:54.463Z (10d ago) |
| 5 | Registry-repo match | PASS | npm -> pnpm/pnpm |

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
| 6 | OpenSSF Scorecard >= 5.0 | PASS | Score: 6.6 |
| 7 | Multiple maintainers | PASS | 2 maintainer(s): pnpmuser, zkochan |
| 8 | Post-xz heuristic clean | PASS | < 2 flags triggered |
| 9 | Distro inclusion | PASS | npm registry |
| 10 | Dep depth <= 500 | PASS | 0 transitive deps |

## 3. Post-xz heuristic scan

- [ ] Solo primary maintainer
- [ ] Binary test fixtures with no human-readable origin
- [ ] Build system doing work beyond compilation
- [ ] Social pressure to merge quickly
- [ ] Suspicious activity spike on previously-dormant package
- [ ] Typosquat-adjacent name
- [ ] Mismatched signing identity

## 4. References

- Upstream: https://github.com/pnpm/pnpm
- npm: https://www.npmjs.com/package/pnpm/v/11.6.0
- OSV: https://osv.dev/list?ecosystem=npm&q=pnpm
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/pnpm/pnpm
- deps.dev: https://deps.dev/npm/pnpm/11.6.0

## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-22 | Initial ADR (automated via vet-package v2) | @eqdmc/security-review |

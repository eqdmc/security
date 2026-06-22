# ADR-0004: `npm/drizzle-kit` — APPROVED

- **Status:** Proposed
- **Date:** 2026-06-21
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** APPROVED (gates: 5/5, scored: 4/4)

## 1. Package

- **Name:** `drizzle-kit`
- **Ecosystem:** npm
- **Canonical source:** https://github.com/drizzle-team/drizzle-orm
- **Version adopted:** `0.31.10`
- **License:** MIT

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | PASS | `MIT` |
| 2 | Zero high/critical CVEs | PASS | osv.dev: 0 vulns found |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2026-03-17T09:31:40.190Z (96d ago) |
| 5 | Registry-repo match | PASS | npm → drizzle-team/drizzle-orm |

### Scored checks (>= 3 must PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 6 | OpenSSF Scorecard >= 5.0 | N/A | Score: n/a |
| 7 | Multiple maintainers | PASS | 4 maintainer(s): alexblokh, dankochetov, kyrylo_usichenko, sheriman |
| 8 | Post-xz heuristic clean | PASS | < 2 flags triggered |
| 9 | Distro inclusion | PASS | npm registry |
| 10 | Dep depth <= 500 | PASS | 88 transitive deps |

## 3. Post-xz heuristic scan

- [ ] Solo primary maintainer
- [ ] Binary test fixtures with no human-readable origin
- [ ] Build system doing work beyond compilation
- [ ] Social pressure to merge quickly
- [ ] Suspicious activity spike on previously-dormant package
- [ ] Typosquat-adjacent name
- [ ] Mismatched signing identity

## 4. References

- Upstream: https://github.com/drizzle-team/drizzle-orm
- npm: https://www.npmjs.com/package/drizzle-kit/v/0.31.10
- OSV: https://osv.dev/list?ecosystem=npm&q=drizzle-kit
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/drizzle-team/drizzle-orm
- deps.dev: https://deps.dev/npm/drizzle-kit/0.31.10

## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-21 | Initial ADR (automated via vet-package) | @eqdmc/security-review |

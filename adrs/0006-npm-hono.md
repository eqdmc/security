# ADR-0006: `npm/hono` — APPROVED

- **Status:** Proposed
- **Date:** 2026-06-21
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** APPROVED (gates: 5/5, scored: 3/4)

## 1. Package

- **Name:** `hono`
- **Ecosystem:** npm
- **Canonical source:** https://github.com/honojs/hono
- **Version adopted:** `4.12.25`
- **License:** MIT

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | PASS | `MIT` |
| 2 | Zero high/critical CVEs | PASS | osv.dev: 0 vulns found |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2026-06-09T03:28:50.819Z (12d ago) |
| 5 | Registry-repo match | PASS | npm → honojs/hono |

### Scored checks (>= 3 must PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 6 | OpenSSF Scorecard >= 5.0 | N/A | Score: n/a |
| 7 | Multiple maintainers | FAIL | 1 maintainer(s): yusukebe |
| 8 | Post-xz heuristic clean | PASS | < 2 flags triggered |
| 9 | Distro inclusion | PASS | npm registry |
| 10 | Dep depth <= 500 | PASS | 1 transitive deps |

## 3. Post-xz heuristic scan

- [x] Solo primary maintainer
- [ ] Binary test fixtures with no human-readable origin
- [ ] Build system doing work beyond compilation
- [ ] Social pressure to merge quickly
- [ ] Suspicious activity spike on previously-dormant package
- [ ] Typosquat-adjacent name
- [ ] Mismatched signing identity

## 4. References

- Upstream: https://github.com/honojs/hono
- npm: https://www.npmjs.com/package/hono/v/4.12.25
- OSV: https://osv.dev/list?ecosystem=npm&q=hono
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/honojs/hono
- deps.dev: https://deps.dev/npm/hono/4.12.25

## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-21 | Initial ADR (automated via vet-package) | @eqdmc/security-review |

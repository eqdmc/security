# ADR-0009: `npm/wrangler` — APPROVED

- **Status:** Proposed
- **Date:** 2026-06-21
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** APPROVED (gates: 5/5, scored: 3/4)

## 1. Package

- **Name:** `wrangler`
- **Ecosystem:** npm
- **Canonical source:** https://github.com/cloudflare/workers-sdk
- **Version adopted:** `4.100.0`
- **License:** MIT OR Apache-2.0

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | PASS | `MIT OR Apache-2.0` |
| 2 | Zero high/critical CVEs | PASS | osv.dev: 0 vulns found |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2026-06-11T15:33:53.534Z (10d ago) |
| 5 | Registry-repo match | PASS | npm → cloudflare/workers-sdk |

### Scored checks (>= 3 must PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 6 | OpenSSF Scorecard >= 5.0 | N/A | Score: n/a |
| 7 | Multiple maintainers | FAIL | 1 maintainer(s): wrangler-publisher |
| 8 | Post-xz heuristic clean | PASS | < 2 flags triggered |
| 9 | Distro inclusion | PASS | npm registry |
| 10 | Dep depth <= 500 | PASS | 0 transitive deps |

## 3. Post-xz heuristic scan

- [x] Solo primary maintainer
- [ ] Binary test fixtures with no human-readable origin
- [ ] Build system doing work beyond compilation
- [ ] Social pressure to merge quickly
- [ ] Suspicious activity spike on previously-dormant package
- [ ] Typosquat-adjacent name
- [ ] Mismatched signing identity

## 4. References

- Upstream: https://github.com/cloudflare/workers-sdk
- npm: https://www.npmjs.com/package/wrangler/v/4.100.0
- OSV: https://osv.dev/list?ecosystem=npm&q=wrangler
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/cloudflare/workers-sdk
- deps.dev: https://deps.dev/npm/wrangler/4.100.0

## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-21 | Initial ADR (automated via vet-package) | @eqdmc/security-review |

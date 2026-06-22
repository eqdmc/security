# ADR-0003: `npm/@cloudflare/workers-types` — APPROVED

- **Status:** Proposed
- **Date:** 2026-06-21
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** APPROVED (gates: 5/5, scored: 4/4)

## 1. Package

- **Name:** `@cloudflare/workers-types`
- **Ecosystem:** npm
- **Canonical source:** https://github.com/cloudflare/workerd
- **Version adopted:** `4.20260613.1`
- **License:** MIT OR Apache-2.0

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | PASS | `MIT OR Apache-2.0` |
| 2 | Zero high/critical CVEs | PASS | osv.dev: 0 vulns found |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2026-06-13T01:41:29.469Z (8d ago) |
| 5 | Registry-repo match | PASS | npm → cloudflare/workerd |

### Scored checks (>= 3 must PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 6 | OpenSSF Scorecard >= 5.0 | N/A | Score: n/a |
| 7 | Multiple maintainers | PASS | 37 maintainer(s): celso, cf-ci-write, cf-ci2, cf-media-manager, cf-npm-publish, cf-radar, cms1919, dash_service_account, dcruz_cf, eduardo-vargas, g4brym, gabivlj-cf, ganders-cloudflare, gregbrimble, ichernetsky-cf, jasnell, jculvey, lvalenta, mgirouard-cf, mikenomitch, musa-cf, nafeezcf, nsharma-cf, segments-write, sejoker, sergeychernyshev, simonabadoiu, terinjokes, thibmeu, third774, threepointone, tlefebvre_cf, vaishakpdinesh, worenga, wrangler-publisher, xortive, xtuc |
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

- Upstream: https://github.com/cloudflare/workerd
- npm: https://www.npmjs.com/package/@cloudflare/workers-types/v/4.20260613.1
- OSV: https://osv.dev/list?ecosystem=npm&q=@cloudflare/workers-types
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/cloudflare/workerd
- deps.dev: https://deps.dev/npm/@cloudflare/workers-types/4.20260613.1

## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-21 | Initial ADR (automated via vet-package) | @eqdmc/security-review |

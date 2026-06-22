# ADR-0007: `npm/typescript` — APPROVED

- **Status:** Proposed
- **Date:** 2026-06-21
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** APPROVED (gates: 5/5, scored: 5/5)

## 1. Package

- **Name:** `typescript`
- **Ecosystem:** npm
- **Canonical source:** https://github.com/microsoft/TypeScript
- **Version adopted:** `6.0.3`
- **License:** Apache-2.0

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | PASS | `Apache-2.0` |
| 2 | Zero high/critical CVEs | PASS | osv.dev: 0 vulns found |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2026-04-16T23:38:27.905Z (65d ago) |
| 5 | Registry-repo match | PASS | npm → microsoft/TypeScript |

### Scored checks (>= 3 must PASS)

| # | Check | Result | Evidence |
|---|---|---|---|
| 6 | OpenSSF Scorecard >= 5.0 | PASS | Score: 7.9 |
| 7 | Multiple maintainers | PASS | 7 maintainer(s): andrewbranch, jakebailey, microsoft-oss-releases, microsoft1es, typescript-bot, typescript-deploys, weswigham |
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

- Upstream: https://github.com/microsoft/TypeScript
- npm: https://www.npmjs.com/package/typescript/v/6.0.3
- OSV: https://osv.dev/list?ecosystem=npm&q=typescript
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/microsoft/TypeScript
- deps.dev: https://deps.dev/npm/typescript/6.0.3

## 5. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-21 | Initial ADR (automated via vet-package) | @eqdmc/security-review |

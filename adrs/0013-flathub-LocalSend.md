# ADR-0013: `flathub/LocalSend` — APPROVED

- **Status:** Proposed
- **Date:** 2026-06-29
- **Approved by:** pending (`@eqdmc/security-review`)
- **Verdict:** APPROVED (gates: 5/5, scored: 4/4)

## 1. Package

- **Name:** `LocalSend`
- **Ecosystem:** flathub
- **Canonical source:** https://localsend.org/
- **Version adopted:** `latest`
- **License:** Apache-2.0

## 2. Binary vetting results

### Hard gates (all must PASS)

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | License is permissive | PASS | `Apache-2.0` |
| 2 | Zero P1+/P1 CVEs | PASS | 0 total vulns, 0 blocking |
| 3 | No install scripts | PASS | preinstall/postinstall/install checked |
| 4 | Quarantine >= 7 days | PASS | Published 2022-12-16T00:46:07Z (N/A) |
| 5 | Registry-repo match | PASS | flathub -> localsend/localsend |

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
| 7 | Multiple maintainers | PASS | 30 maintainer(s): Tienisto, ShlomoCode, sergd88, TheGB0077, gidano, nkh0472, soya-daizu, Arvanta, Matthaiks, Neo1102 |
| 8 | Post-xz heuristic clean | PASS | < 2 flags triggered |
| 9 | Distro inclusion | PASS | Available on flathub |
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

- Upstream: https://localsend.org/
- OSV: https://osv.dev/list?ecosystem=flathub&q=LocalSend
- Scorecard: https://scorecard.dev/viewer/?uri=github.com/localsend/localsend

## 5. Deployment

### Fedora Linux (this machine)

```bash
flatpak install flathub org.localsend.localsend_app
```

Firewall: port `53317` TCP+UDP for device discovery and transfer.

### Android / GrapheneOS (Pixel 8a)

GrapheneOS users should install via **F-Droid** (recommended for sandboxed,
audited builds):

1. Install F-Droid client from https://f-droid.org
2. Search for "LocalSend" or scan: `org.localsend.localsend_app`
3. Install v1.17.0 (latest on F-Droid)

Alternative: **Aurora Store** (Google Play frontend) — same app ID.

Direct APK: https://github.com/localsend/localsend/releases/latest

### macOS (previous install)

```bash
brew install --cask localsend
```

## 6. Change log

| Date | Change | By |
|---|---|---|
| 2026-06-29 | Initial ADR (automated via vet) | @eqdmc/security-review |

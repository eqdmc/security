# eqdmc/security

Security-as-code: automated vetting, policy engines, continuous scanning, agent governance.

## Structure

```
bin/
  vet              — universal package vetting (any ecosystem: npm, pypi, flathub, crates, github)
  vet-adr          — auto-generate ADR from vet result JSON
  vet-package      — DEPRECATED: use `vet` instead (npm-only legacy)
  vet-batch        — batch processor for package.json
  render-adr       — DEPRECATED: use `vet --adr` instead
checks/
  adapters/
    npm.sh         — npm registry adapter
    pypi.sh        — PyPI adapter (TODO)
    flathub.sh     — Flathub adapter (enriches from GitHub API)
    crates.sh      — crates.io adapter (TODO)
    github.sh      — GitHub releases adapter (TODO)
  gate-license.sh          — Gate 1: permissive license
  gate-cve.sh              — Gate 2: multi-signal CVE quadrant (OSV + EPSS + KEV)
  gate-install-scripts.sh  — Gate 3: no install hooks
  gate-quarantine.sh       — Gate 4: ≥ 7 days since publish
  gate-registry-repo.sh    — Gate 5: registry ↔ GitHub identity match
  scored-scorecard.sh      — Scored 6: OpenSSF Scorecard ≥ 5.0
  scored-maintainers.sh    — Scored 7: ≥ 2 maintainers
  scored-postxz.sh         — Scored 8: post-xz heuristic scan
  scored-distro.sh         — Scored 9: included in well-known registry
  scored-depdepth.sh       — Scored 10: ≤ 500 transitive deps
lib/
  common.sh        — shared logging, run_check(), compute_verdict()
policy/
  vetting.yaml     — binary checklist definition (5 hard gates + 5 scored checks)
adrs/
  0013-flathub-LocalSend.md  — example auto-generated ADR
```

## Universal vetting CLI (`bin/vet`)

Works for any ecosystem. Auto-detects or accepts explicit `--eco` flag.

```bash
# Auto-detect ecosystem (tries adapters in order)
bin/vet localsend

# Explicit ecosystem + version
bin/vet org.localsend.localsend_app --eco flathub
bin/vet @cloudflare/workers-types --eco npm

# Generate ADR automatically
bin/vet org.localsend.localsend_app --eco flathub --adr

# Skip install prompt (ADR-only mode)
bin/vet org.localsend.localsend_app --eco flathub --adr --no-install
```

## Adding a new ecosystem adapter

1. Create `checks/adapters/<eco>.sh`
2. Must output JSON with this schema:
   ```json
   {
     "ecosystem": "flathub",
     "package": "org.localsend.localsend_app",
     "version": "1.17.0",
     "metadata": {
       "license": "Apache-2.0",
       "repo_url": "https://github.com/...",
       "gh_slug": "owner/repo",
       "publish_time": "2022-12-16T00:46:07Z",
       "maintainer_count": 220,
       "maintainers": ["user1", "user2"],
       "has_install_scripts": false
     }
   }
   ```
3. Add auto-detection heuristic to the `auto_detect()` function in `bin/vet`

## Vetting workflow (git-managed, atomic)

### Branch naming
```
vet/{eco}-{package}          e.g. vet/flathub-localsend
```

### Atomic commit scope
Each vetting produces one atomic commit containing:
1. `adrs/XXXX-{eco}-{package}.md` — auto-generated ADR
2. `packages/{manifest}.txt` — manifest entry with ADR reference
3. `packages/VETTING.md` — updated approval log
4. `packages/install.sh` — installer support (only if new ecosystem)

### PR process
1. Create branch: `git checkout -b vet/flathub-localsend`
2. Run vet: `bin/vet <package> --eco <eco> --adr`
3. Add to manifest: edit `packages/{manifest}.txt`
4. Commit: `git add -A && git commit -m "feat(vet): approve {package} v{version} for {eco}"`
5. Open PR using `.github/PULL_REQUEST_TEMPLATE/vetting.md`
6. After merge: install on target machines

### Rollback
Revert the atomic commit: `git revert <sha>` removes ADR + manifest change.

## Vetting model

Binary pass/fail. No advisory-only.

**5 hard gates (ALL must PASS):**
1. License is permissive
2. Zero P1+/P1 CVEs (multi-signal: KEV → EPSS → CVSS)
3. No install scripts
4. Published >= 7 days ago (quarantine)
5. Registry-repo identity match

**5 scored checks (>= 3 must PASS):**
6. OpenSSF Scorecard >= 5.0
7. Multiple maintainers
8. Post-xz heuristic clean
9. Distro inclusion
10. Transitive dep count <= 500

**Verdict:** all gates PASS + scored threshold met = APPROVED. Any gate FAIL = BLOCKED.

## Sovereignty principle

Prefer open-source, auditable components. Closed-source accepted only
when 10x better (e.g., Cloudflare, GitHub). All vetting tooling is
itself open-source and auditable — no opaque binaries.

## CVE model

Uses CVE_Prioritizer quadrant model (arxiv:2506.01220):
- Signal chain: KEV (exploited) → EPSS (probability) → CVSS (severity)
- P1+/P1 = BLOCK. P2/P3 = WARN. P4 = ACCEPT.

## Repo governance

- Derived from eqdmc/repo-template (governance v1.0)
- Labels, rulesets, and workflows managed centrally via eqdmc/.github
- ADR results feed into eqdmc/.github/vetting/approved.yml

## Style

- Conventional commits: feat/fix/refactor/docs/test/chore
- All changes go through PRs to main

# eqdmc/security

Security-as-code: automated vetting, policy engines, continuous scanning, agent governance.

## Build & test

```bash
# Vet a single package
bin/vet-package <package> <version>

# Batch vet from package.json
bin/vet-batch <path-to-package.json>

# Render ADR from vet result
bin/render-adr <vet-result.json> <sequence-number>
```

## Structure

```
bin/
  vet-package      — binary pass/fail vetting (queries npm, Scorecard, osv.dev, deps.dev)
  vet-batch        — batch processor for package.json
  render-adr       — ADR markdown renderer from vet JSON
policy/
  vetting.yaml     — binary checklist definition (5 hard gates + 5 scored checks)
```

## Vetting model

Binary pass/fail. No advisory-only.

**5 hard gates (ALL must PASS):**
1. License is permissive
2. Zero high/critical CVEs (osv.dev)
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

## Repo governance

- Derived from eqdmc/repo-template (governance v1.0)
- Labels, rulesets, and workflows managed centrally via eqdmc/.github
- ADR results feed into eqdmc/.github/vetting/approved.yml

## Style

- Conventional commits: feat/fix/refactor/docs/test/chore
- All changes go through PRs to main

---
name: Package vetting
about: Request approval for a new package/tool/dependency
title: 'vet: `{ecosystem}/{package}` v{version}'
labels: vetting, security-review
assignees: eqdmc/security-review
---

## Package

- **Name:** `{package}`
- **Ecosystem:** `{ecosystem}`
- **Version:** `{version}`
- **License:** `{license}`
- **Source:** `{repo_url}`

## Vetting result

```json
{vet_result_json}
```

**Verdict:** `{verdict}` (gates: {gates_pass}/{gates_total}, scored: {scored_pass}/{scored_total})

## Manifest change

- [ ] Added to `packages/{manifest}.txt`
- [ ] ADR generated at `adrs/{adr_filename}`

## Checklist

- [ ] `bin/vet {package} {version} --eco {ecosystem}` passed with APPROVED verdict
- [ ] ADR reviewed for accuracy
- [ ] Manifest entry includes reference comment to ADR
- [ ] `bash packages/install.sh` confirms successful install
- [ ] Branch follows `vet/{ecosystem}-{package}` naming convention

## Post-merge

- [ ] Install on target machines via `bash packages/install.sh`
- [ ] For Android/iOS: install from F-Droid/App Store (documented in ADR)

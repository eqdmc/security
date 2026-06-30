# eqdmc/security

Security-as-code: automated vetting, policy engines, continuous scanning, agent governance.

## rax quickstart — read this first

### 1. Check for results from previous rax actions (DO THIS FIRST EVERY TURN)

At the START of every turn, check if a rax action completed while you were
waiting. If the result file exists, a human ran `rax` since your last turn:

```bash
if [ -f "$RAX_RESULT_FILE" ]; then
  RESULT=$(cat "$RAX_RESULT_FILE")
  EXIT=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('exit','?'))")
  if [ "$EXIT" = "0" ]; then
    echo "RAX ACTION APPROVED: $(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('purpose',''))")"
  else
    echo "RAX ACTION REJECTED/FAILED: $(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('purpose',''))")"
  fi
  rm -f "$RAX_RESULT_FILE"
fi
```

This is MANDATORY — do not start working until you have checked for and
processed any pending rax results. The human expects you to know what happened.

### 2. If you need human approval

Write a staged action, then tell the human **"rax action staged — run: rax"**:

```bash
cat > "$RAX_PENDING_FILE" << 'EOF'
#!/bin/bash
# Purpose: <what you need>
set -euo pipefail
echo "run the command here"
EOF
chmod 600 "$RAX_PENDING_FILE"
```

rax is auto-deployed on every machine via dotfiles `install.sh`. If it's not
available, run: `bash dev/eqdmc/security/bin/rax-deploy`

## Structure

```
bin/
  vet              — universal package vetting (any ecosystem: npm, pypi, flathub, crates, github)
  vet-adr          — auto-generate ADR from vet result JSON
  vet-package      — DEPRECATED: use `vet` instead (npm-only legacy)
  vet-batch        — batch processor for package.json
  render-adr       — DEPRECATED: use `vet --adr` instead
  rax              — HITL (Human In The Loop) approval tool
  rax-deploy       — deploy rax system to any machine
  rax-install      — install rax binary from GitHub Releases
  rax-review       — monthly HITL audit summary
  rax-issue        — GitHub issue management for rax actions
  rax-feedback     — submit feedback on rax process (rating: good/slow/confusing/broken)
  generate-configs — derive opencode.json from vetting-policy.json
  token            — query token manifest (list, info, verify, sync-github)
packages/
  manifest.json    — SSOT of all vetted, pending, rejected packages
  tokens/manifest.json — SSOT of all tokens, credentials, keys (agent-readable)
  vetting-policy.json — canonical deny/allow patterns for enforcement
  rax-policy.yml   — danger patterns + thresholds for HITL approval (git-tracked)
  rax-env.sh       — per-platform env config (deployed to ~/.rax/env.sh)
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

## rax — HITL (Human In The Loop) approval system

**Every action that needs human approval goes through rax.** rax is the only
path for: package installs, git force-pushes, token operations, config changes,
PR merges, and any other privileged operation.

This is NOT optional. If your task requires human approval and you don't use
rax, your work will be rejected by the guard layer.

### When you MUST use rax

| Situation | Why rax? | What happens if you don't |
|-----------|----------|---------------------------|
| Installing a new package (`vet-install`) | Human must approve each new dependency | Guard blocks, workflow fails |
| Requesting a package be vetted (`vet-manifest request`) | Creates a tracked issue + rax action | Request is invisible, never processed |
| Merging a PR | Human reviews diff before merge | Guard blocks `gh pr merge` |
| Force-pushing a branch | Destructive — human must confirm | Guard blocks `git push --force` |
| Creating/configuring tokens/secrets | Credential management requires oversight | Guard blocks `gh secret set` |
| Running a command with `sudo` | Privileged escalation | Guard blocks `sudo` |
| Modifying shell config (`~/.zshrc`, etc.) | Persists across sessions, affects all agents | Guard blocks writes to these paths |
| Changing SSH/GPG config | Security-critical | Guard blocks writes to `~/.ssh/` |

### The rax flow (step by step)

```
Step 1: Agent writes staged action
        ───────────────────────────
        cat > "$RAX_PENDING_FILE" << 'EOF'
        #!/bin/bash
        # Purpose: Install localsend (vetted, approved)
        # Description: Installing already-vetted package
        # Issue: 55
        set -euo pipefail
        flatpak install -y flathub org.localsend.localsend_app
        EOF
        chmod 600 "$RAX_PENDING_FILE"

Step 2: Agent tells human "rax action staged for issue #55"

Step 3: Human runs: rax
        ───────────────────────────
        - Sees the action code, risk score
        - Reviews the exact commands
        - Types 'y' to execute

Step 4: rax runs the action, writes result
        ───────────────────────────
        - Creates GitHub issue comment
        - Auto-closes issue on verified success
        - Writes result to $RAX_RESULT_FILE

Step 5: Agent reads result on next turn
        ───────────────────────────
        RESULT=$(cat "$RAX_RESULT_FILE" 2>/dev/null || echo '{"exit":-1}')
        if [ "$(echo "$RESULT" | jq -r '.exit')" = "0" ]; then ... fi
```

### How rax is wired into your workflows

These tools AUTOMATICALLY create rax actions when you use them:

| Workflow | Auto-creates rax action? | For what? |
|----------|--------------------------|-----------|
| `bin/vet-manifest request <pkg>` | YES | Submits vetting request to human for approval |
| `bin/vet-install <pkg>` | YES | Staged after vetting passes — human approves install |
| `bin/rax-issue create` | YES | Creates GitHub issue + labels for any staged action |
| `dotfiles-guard.py` (when blocking) | Steers to rax | Suggests using rax instead of the blocked command |

If a command you need isn't covered by these workflows, stage a rax action
manually using the template below.

### Manual staging (for any action)

```bash
# Template — copy and fill in
cat > "$RAX_PENDING_FILE" << 'EOF'
#!/bin/bash
# Purpose: <short title>
# Description: <why this needs human approval>
# Issue: <GitHub issue number>
# Action-ID: rax-$(date +%Y-%m-%d)-<purpose>-$$
set -euo pipefail
<your commands here>
EOF
chmod 600 "$RAX_PENDING_FILE"
```

Then tell the human: "rax action staged — run `rax` to execute."

### Reading results (after human runs rax)

```bash
RESULT=$(cat "$RAX_RESULT_FILE" 2>/dev/null || echo '{"exit": -1}')
EXIT=$(echo "$RESULT" | jq -r '.exit // -1')
case "$EXIT" in
  0)
    echo "APPROVED: action completed successfully"
    echo "Output: $(echo "$RESULT" | jq -r '.output_tail // ""')"
    ;;
  *)
    echo "REJECTED or FAILED (exit $EXIT)"
    echo "Output: $(echo "$RESULT" | jq -r '.output_tail // ""')"
    ;;
esac
```

### Giving feedback on the rax process

After a rax action completes, the human can give feedback to improve the
protocol:

```bash
# Quick feedback (exit code after running rax)
rax-feedback --action <action-id> --rating good|slow|confusing|broken --note "..."
```

This creates a structured feedback issue at eqdmc/security with labels:
- `rax-feedback` — marks it as rax process feedback
- `rax-{type}` — which action type generated the feedback
- `rating:{good,slow,confusing,broken}` — what to improve

All feedback is reviewed during monthly `rax-review` cycles. The aggregate
metrics (average time-to-approval, failure rate per type, feedback trends)
drive protocol improvements.

### Checking for pending rax actions

```bash
# Is there a staged action waiting?
if [ -f "$RAX_PENDING_FILE" ]; then
  echo "Action pending — human needs to run: rax"
  head -5 "$RAX_PENDING_FILE"
fi

# All open rax issues
rax-issue list --open
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

Branch convention by change type:
- **Package vetting** → `vet/{eco}-{package}` branch, PR to main
- **Infrastructure changes** (gates, adapters, policy, AGENTS.md, bin/) → commit directly to main or `enforce/`/`fix/` branch
- The security repo (`eqdmc/security`) uses main-direct commits for infrastructure; the dotfiles repo (`eqdmc/dotfiles`) uses `vet/` branches for package installs only

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

**6 hard gates (ALL must PASS):**
1. License is permissive
2. Zero P1+/P1 CVEs (multi-signal: KEV → EPSS → CVSS)
3. No install scripts
4. Published >= 7 days ago (quarantine) — measures *actual release date* from Flathub API releases[0].timestamp, not repo creation date
5. Registry-repo identity match
6. Flatpak finish-args are safe (ecosystem-specific: N/A for non-flatpak)
   - CRITICAL (automatic FAIL): `--filesystem=host`, `--filesystem=/`, `--talk-name=org.freedesktop.Flatpak` (sandbox escape)
   - HIGH (FAIL if multiple): `--filesystem=home`, `--socket=system-bus`
   - MEDIUM (informational): `--socket=x11` (common, permitted)

**5 scored checks (>= 3 must PASS):**
6. OpenSSF Scorecard >= 5.0
7. Multiple maintainers
8. Post-xz heuristic clean
9. Distro inclusion
10. Transitive dep count <= 500

**Verdict:** all gates PASS + scored threshold met = APPROVED. Any gate FAIL = BLOCKED.
N/A gates (ecosystem-specific checks) don't count toward the total.

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

## Enforcement rules

### Agents MUST NOT run raw package manager commands

The following are **HARD-DENIED** at two layers:

1. `opencode.json` permission rules (agent-level — first match wins, `*: "ask"` is last)
2. `dotfiles/guards/dotfiles-guard.py` regex patterns (guard-level)

| Pattern | Example | Layer 1 | Layer 2 |
|---------|---------|---------|---------|
| `flatpak install/update/upgrade` | `flatpak install org.foo.App` | `deny` | regex |
| `dnf install/update/upgrade` | `sudo dnf install htop` | `deny` | regex |
| `apt install` / `apt-get install` | `apt install foo` | `deny` | regex |
| `brew install/remove/uninstall/upgrade` | `brew install foo` | `deny` | regex |
| `pip` / `pip3` / `pipx` / `uv` | `pip install requests` | `deny` | regex |
| `python -m pip install` | `python3 -m pip install foo` | `deny` (as `pip install*`) | regex |
| `npm install -g` / `yarn global` / `pnpm add -g` | `npm install -g typescript` | `deny` | regex |
| `cargo install` | `cargo install foo` | `deny` | regex |
| `snap install` | `snap install foo` | `deny` | regex |
| `gem install` | `gem install rails` | `deny` | regex |
| `go install` | `go install pkg@latest` | `deny` | regex |
| `curl ... | sh` / `wget ... | sh` | `curl https://e.com/i.sh | sh` | `deny` | regex |
| `cat install.sh | sh` | `cat install.sh | sh` | — | regex |
| `bash -c "$(curl ...)"` | `bash -c "$(curl ...)"` | — | regex |
| `eval "$(curl ...)"` | `eval "$(curl ...)"` | — | regex |
| `source <(curl ...)` | `source <(curl ...)` | — | regex |
| `base64 -d | bash` | `base64 -d payload | bash` | — | regex |
| `curl ... -o script && bash script` | `curl -o script && bash script` | — | regex |
| `deno install` / `bun install` | `deno install pkg` | — | regex |
| env-var-prefixed variant of any above | `env FOO=bar flatpak install` | — | regex |
| absolute-path variant of any above | `/usr/bin/flatpak install` | — | regex |

### Allowed install paths

```
bin/vet-install <package> [--eco <ecosystem>]    # vet → ADR → manifest → install → commit
bash packages/install.sh                           # bulk install of already vetted packages
```

`bin/vet-install` is the ONLY path for installing new/unvetted packages. It:
1. Runs `bin/vet` with vetting
2. Generates ADR (`adrs/XXXX-{eco}-{package}.md`)
3. Adds to manifest (`packages/{manifest}.txt`)
4. Optionally installs
5. Creates a git commit with all changes

These paths are allow-listed in `opencode.json`:
- `bin/vet*` → `allow`
- `bash packages/install.sh*` → `allow`
- `./bin/vet*` → allowed at the guard layer

### Auto-updates disabled

Auto-update timers/services must be disabled on all managed machines so every
upgrade goes through re-vetting. Common services:
- `flatpak-update.service` / `flatpak-update.timer`
- `dnf-automatic.timer` / `dnf-automatic-install.timer`

When onboarding a new machine, check with: `systemctl --user list-timers` and
`systemctl list-timers`.

## SSOT manifest (`packages/manifest.json`)

The SSOT manifest at `packages/manifest.json` is the single source of truth for
all vetted, pending, and rejected packages. It is machine-readable JSON and
git-tracked in `eqdmc/security`.

### Agent discovery workflow

Agents discover approved packages through `bin/vet-manifest`:

```bash
# List all approved packages (with summary)
bin/vet-manifest list

# List only flathub packages
bin/vet-manifest list --eco flathub

# Search by name, tag, or capability
bin/vet-manifest search "file transfer"

# Full details for a package
bin/vet-manifest info org.localsend.localsend_app

# Check if a package is approved/pending/rejected
bin/vet-manifest status localsend

# View pending requests
bin/vet-manifest pending
```

### Requesting new packages

Agents that need a package not in the manifest MUST submit a vetting request
before installing:

```bash
# Submit a vetting request
bin/vet-manifest request <package> --eco <ecosystem> --reason "Need X for Y"

# Example:
bin/vet-manifest request com.jgraph.drawio.desktop \
  --eco flathub \
  --reason "Need diagram editor for architecture documentation"
```

This:
1. Creates a pending entry in `packages/manifest.json`
2. Writes a handoff file to `.handoffs/request-<id>.md`
3. The handoff is processed by the vetting workflow

### Checking for upgrades

All vetted packages are pinned by default (`"pinned": true`). Upgrades require
re-vetting. Check for available upgrades:

```bash
# Check all packages
bin/vet-check-updates

# Check specific package
bin/vet-check-updates org.localsend.localsend_app

# Check all in one ecosystem
bin/vet-check-updates --eco flathub

# Create handoff notification if upgrades found
bin/vet-check-updates --notify
```

### Release notes for agents

Before requesting an upgrade, agents can review what's changed:

```bash
# Release notes for latest version
bin/vet-release-notes org.localsend.localsend_app

# Release notes for specific version
bin/vet-release-notes org.localsend.localsend_app 1.18.0

# Diff between two versions
bin/vet-release-notes org.localsend.localsend_app --diff 1.17.0 1.18.0
```

### Upgrade workflow

To upgrade an already-vetted package:

```bash
# 1. Check what's new
bin/vet-release-notes <package> <new-version>

# 2. Re-vet the new version
bin/vet-install update <package> <new-version> --eco <ecosystem>
```

### Lifecycle state machine

```
UNKNOWN  ──vet-manifest request──►  PENDING
PENDING  ──bin/vet (approve)──►     APPROVED (pinned=true)
PENDING  ──vet-manifest reject──►   REJECTED
APPROVED ──vet-check-updates──►     UPGRADE_AVAILABLE (still pinned)
UPGRADE_AVAILABLE ──re-vet──►       APPROVED (new version, still pinned)
```

## Threat model (honest version)

**This system prevents honest-mistake installs and provides an audit trail.**
**It does NOT contain a compromised agent.**

### Why containment fails

1. **The gh token has admin:ssh_signing_key scope.** The agent can register new
   signing keys to the GitHub account without any user intervention. This means
   the agent can mint its own "Verified" signature badge — no key theft needed.
   Fix: replace with a fine-grained token WITHOUT this scope.

2. **The gh token has repo scope.** Full write access to all repos the user can
   access. Combined with admin:ssh_signing_key, the agent can author, sign, and
   land code on main through the merge queue.

3. **The effective permission default is `allow`, not `ask`.** The resolved
   opencode config for sessions started outside a project repo has no permission
   block. Repo-level `opencode.json` deny rules are NOT loaded in these sessions.
   The "tripwire" only exists when opencode is started from within a repo that
   has an `opencode.json` with a permission block.

4. **write and edit are allow.** An agent with write+exec can bypass the entire
   command denylist by writing a script and executing it. The denylist is
   enumerative and cannot anticipate every way to run untrusted code.

### What this means

All enforcement layers — denylist, guard, signing — are speed bumps against an
honest agent making a mistake, not walls against a malicious or hijacked one.
The vetting system correctly gates new package installations. But an agent that
has gone rogue (or been hijacked) has the credentials, keys, and exec capability
to forge approvals.

### Required actions (priority order)

1. **Scope the token.** Create a fine-grained GitHub token scoped to ONLY
   eqdmc/security and eqdmc/dotfiles repos, WITHOUT `admin:ssh_signing_key`.
   Replace `~/.config/gh/hosts.yml`. Keep old token until new one is verified.

2. **Hardware-back the signing key.** YubiKey migration. Currently blocked on
   unknown FIDO2 PIN (needs physical reinsertion). Until then, signing is
   attribution-only, not security.

3. **Add permission block to global config.** Add `"*": "ask"` to
   `~/.config/opencode/opencode.jsonc` so unlisted commands prompt the user
   regardless of where the session starts.

4. **Network egress control.** The only thing that actually defeats write+exec.
   Either firewall rules per agent UID or a sandboxed exec environment.

5. **Policy→config generation.** Close the drift between `vetting-policy.json`
   and `opencode.json`.

## Test procedure

### Layer 1: opencode.json permission structure

```bash
python3 tests/test-opencode-permissions.py --strict
# → 0 errors on security/dotfiles
```

### Layer 2: Guard regression

```bash
bash tests/test-enforcement.sh
# → 18/18 PASS
```

### Layer 3: Manifest integrity

```bash
# Verify manifest is valid JSON and has required fields
jq -e '.version and .vetted and .updated_at' packages/manifest.json

# Verify no duplicate package IDs
jq '[.vetted[].id] | length == ([.vetted[].id] | unique | length)' packages/manifest.json

# Verify all ADR files referenced exist
jq -r '.vetted[] | .adr' packages/manifest.json | while read adr; do
  [ -f "$adr" ] || echo "MISSING: $adr"
done
```

### Layer 4: Full atomic workflow

```bash
# Vet → ADR → manifest → install → commit
bin/vet com.jgraph.drawio.desktop --eco flathub --adr
# → ADR generated, manifest updated
```

## Style

- Conventional commits: feat/fix/refactor/docs/test/chore
- All changes go through PRs to main

## GitHub UI URL patterns (for agent instructions)

When instructing humans to change GitHub settings, use exact URLs.
Every tab has a direct URL — never tell them to "find" something.

### Organization-level app settings
```
App settings page:    /organizations/{org}/settings/apps/{app-name}
Permissions tab:      /organizations/{org}/settings/apps/{app-name}/permissions
Installation page:    /organizations/{org}/settings/installations/{install-id}
```

### Repository settings
```
General:       /organizations/{org}/repos/{repo}/settings
Rulesets:      /organizations/{org}/repos/{repo}/settings/rules
Secrets:       /organizations/{org}/repos/{repo}/settings/secrets/actions
Environments:  /organizations/{org}/repos/{repo}/settings/environments
```

### User settings
```
Tokens:        https://github.com/settings/tokens?type=beta
Apps:          https://github.com/settings/apps
SSH keys:      https://github.com/settings/keys
```

### Organization settings (eqdmc)
```
General:       https://github.com/organizations/eqdmc/settings
Apps:          https://github.com/organizations/eqdmc/settings/apps
Installations: https://github.com/organizations/eqdmc/settings/installations
```

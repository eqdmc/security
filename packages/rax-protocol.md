# rax protocol v0.2.1

Versioned specification for staging, approving, verifying, and auditing
Human-In-The-Loop (HITL) actions in AI-agent-assisted development.

## Version

**Current version: 0.2.1**

| Version | Date | Changes |
|---------|------|---------|
| 0.2.1 | 2026-06-30 | Task-type plugins, GitHub issue integration, auto-close |
| 2.0.0 | 2026-06-22 | Core HITL approval flow, risk scoring, audit log |
| 1.0.0 | 2026-06-15 | Initial rax release |

## Lifecycle

Every rax action follows this state machine:

```
             ┌──────────────────────────────────────┐
             │                                      │
             ▼                                      │
  STAGED ──► APPROVED ──► EXECUTING ──► VERIFIED ──┤
             │                          │           │
             │                          ├── FAILED ─┤
             │                          └── CLOSED ─┘
             │
             └──► REJECTED
```

- **STAGED**: Agent writes the action file. GitHub issue created (if not exists).
- **APPROVED**: Human runs `rax` and types `y`/`yes`.
- **EXECUTING**: rax runs the action script.
- **VERIFIED**: Verification command ran successfully. Issue auto-closed.
- **FAILED**: Action or verification failed. Issue updated with output.
- **CLOSED**: Terminal state. Issue closed. Audit log written.
- **REJECTED**: Human declined to run. Issue updated with "rejected."

## Action schema

Every rax action is a YAML document with this structure:

```yaml
rax-version: "0.2.1"          # protocol version (required, pinnable)
type: merge                    # task type (required)
action-id: "rax-2026-06-30-enforce-001"  # globally unique (required)
issue: 123                     # GitHub issue number (auto-created if absent)
created-by: "agent-build-7"    # agent session that staged this
created-at: "2026-06-30T09:00:00Z"  # ISO 8601
title: "Short human-readable title"  # becomes issue title
description: |                 # detailed description, becomes issue body
  Longer explanation of what this action does and why it needs HITL.
payload:                       # type-specific data (schema per type)
  repo: "eqdmc/security"
  pr: 45
verify:                        # how to confirm success
  command: "gh pr view 45 --json state,merged"
  expect:                      # optional: expected values after execution
    state: "MERGED"
    merged: true
rollback:                      # how to undo
  command: "gh pr revert 45"
labels:                        # GitHub issue labels (auto-added)
  - "agent-work"
  - "rax-merge"
```

### File format (backward-compatible)

rax also accepts shell scripts with headers (the v2.0 format). The shell script
format auto-promotes to YAML by parsing `# Purpose:` → `title`, `# Description:`
→ `description`, `# Verify:` → `verify.command`, `# Rollback:` → `rollback.command`,
`# Issue:` → `issue`, `# Action-ID:` → `action-id`, `# Repo:` → `payload.repo`.

## Task types

Each task type has a config file at `packages/rax-types/<type>.yaml` that defines:

| Field | Description |
|-------|-------------|
| `type` | Unique type name |
| `label` | GitHub issue label (auto-added) |
| `description` | Human-readable type description |
| `icon` | Emoji icon for display |
| `schema` | JSON Schema for the payload |
| `danger_patterns` | Additional regex patterns for risk scoring |
| `verify_default` | Default verify command (overridable per action) |
| `rollback_default` | Default rollback command (overridable per action) |
| `issue_template` | GitHub issue body template |
| `close_on_verify` | Whether to auto-close the issue on successful verify |
| `required_labels` | Labels to add to the issue |
| `auto_merge` | Whether this type can auto-merge PRs after HITL |

### Standard types

| Type | Label | Description |
|------|-------|-------------|
| `merge` | `rax-merge` | PR merge via merge queue |
| `vet` | `rax-vet` | Package vetting approval |
| `install` | `rax-install` | Package installation |
| `secrets` | `rax-secrets` | Secrets/token/credential management |
| `config` | `rax-config` | Config file changes (shell, editor, etc.) |
| `deploy` | `rax-deploy` | Deployment/release operations |
| `git-force-push` | `rax-git-force-push` | Destructive git operations |
| `cleanup` | `rax-cleanup` | Cleanup/delete operations |
| `test` | `rax-test` | Test-runner approval |
| `generic` | `rax-generic` | Other/unclassified |

## GitHub issue integration

Every rax action MUST be associated with a GitHub issue.

### Auto-create

If the staged action does not reference an existing issue (`# Issue:` header
or `issue` field), rax creates one automatically:

```
repo: eqdmc/security
title: "[rax] {title}"
labels: agent-work, rax-{type}
body: generated from action description
```

### Auto-close

When verification passes (exit 0 and all `expect` fields match), rax
auto-closes the issue with a comment:

```
rsax `{action-id}`: completed — {title}

Verification: PASS
Output: {output_tail}
```

### Auto-comment on failure

If verification fails, rax comments on the issue:

```
rsax `{action-id}`: verification FAILED — {title}

Exit: {exit_code}
Output: {output_tail}
```

## Audit trail

Every rax execution is logged to `$RAX_AUDIT_FILE` (JSONL, append-only):

```json
{"ts": 1750608000, "action_id": "rax-...", "type": "merge", "exit": 0,
 "verify_exit": 0, "issue": 123, "session_id": "...", "category": "merge"}
```

The audit log is the authoritative record of all HITL approvals. It feeds into
`rax-review` for monthly summaries and `rax-audit` for ad-hoc queries.

## Pinning

To pin a specific version of the rax protocol, set the `rax-version` field in
the action YAML. rax validates the action against the protocol version:

```
rax-version: "0.2.1"  # validated against packages/rax-protocol.md
```

Pinning is useful for CI/CD and multi-machine deployments where you want
consistent behavior across environments.

## Extending

To add a new task type:

1. Create `packages/rax-types/<type>.yaml` with the type config
2. Register any new danger patterns
3. The type is immediately available for use
4. Run `rax-deploy` to propagate to all machines

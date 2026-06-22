# rax environment variables

rax reads all configuration from environment variables. Every variable has a sensible default — zero configuration is needed for standalone use.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `RAX_PENDING_FILE` | `~/.rax/pending.sh` | Path to the staged action script |
| `RAX_STATE_DIR` | `~/.rax/state/` | Directory for result, log, and audit files |
| `RAX_RESULT_FILE` | `$RAX_STATE_DIR/last-result.json` | Structured JSON result for harness adapter |
| `RAX_AUDIT_FILE` | `$RAX_STATE_DIR/audit.jsonl` | Append-only JSONL audit log |
| `RAX_SESSION_ID` | `unknown` | Session correlation — set by the harness |
| `RAX_POLICY_FILE` | `~/.rax/policy.yml` | Danger patterns and thresholds (YAML) |

## Harness configuration

Each harness sets these variables at session start. The harness provides 3 values; rax does everything else.

### Claude Code

```bash
# In ~/.zshrc or session-start hook
export RAX_PENDING_FILE="$HOME/.claude/plans/pending-action.sh"
export RAX_STATE_DIR="$HOME/.claude/state"
export RAX_SESSION_ID="$CLAUDE_SESSION_ID"
```

### OpenCode

```bash
export RAX_PENDING_FILE="$HOME/.opencode/plans/pending-action.sh"
export RAX_STATE_DIR="$HOME/.opencode/state"
export RAX_SESSION_ID="$OPENCODE_SESSION_ID"
```

### Docker container

```yaml
# docker-compose.yml
services:
  agent:
    volumes:
      - ~/.rax:/rax
    environment:
      - RAX_PENDING_FILE=/rax/pending.sh
      - RAX_STATE_DIR=/rax/state
      - RAX_SESSION_ID=${SESSION_ID:-unknown}
```

Agent writes to `/rax/pending.sh` inside the container. Human runs `rax` on the host (reads `~/.rax/pending.sh` via the bind mount). Result lands in `~/.rax/state/last-result.json` — agent reads it on next turn.

### VPS / remote

Same as local, but the transport varies:
- **SSH**: `ssh vps 'rax'` — runs on the VPS directly
- **File sync**: rsync or mutagen mirrors `~/rax/` to local `~/.rax/` — run `rax` locally
- **Future**: `rax --remote` could poll a shared object store

## Result file format

`$RAX_RESULT_FILE` (JSON):

```json
{
  "ts": 1750608000,
  "action_id": "rsax-2026-06-22-merge-pr-248-0001",
  "exit": 0,
  "purpose": "Admin-merge PR #248",
  "danger_score": 40,
  "session_id": "BF3048F3-...",
  "verify_exit": 0,
  "output_tail": "..."
}
```

## Audit file format

`$RAX_AUDIT_FILE` (JSONL, append-only):

Same schema as result, minus `output_tail`. One entry per line. This is the authoritative record of all HITL approvals.

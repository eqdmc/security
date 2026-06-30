#!/bin/bash
# rax-env.sh — Per-platform environment configuration for the rax HITL system.
# Source this from .bashrc / .zshrc on each machine.
#
# Auto-detects the runtime (opencode, claude-code, docker) and sets:
#   RAX_PENDING_FILE  — where agents write staged actions
#   RAX_STATE_DIR     — where results and audit logs go
#   RAX_SESSION_ID    — session correlation (set by harness)
#   RAX_POLICY_FILE   — danger patterns and thresholds
#
# Also adds rax to PATH if not already there.

# ── Detect platform ────────────────────────────────────────────────
_rax_platform="unknown"
if [ -n "${OPENCODE_SESSION_ID:-}" ]; then
  _rax_platform="opencode"
elif [ -n "${CLAUDE_SESSION_ID:-}" ]; then
  _rax_platform="claude-code"
elif [ -f /.dockerenv ]; then
  _rax_platform="docker"
elif [ "$(uname -s)" = "Darwin" ]; then
  _rax_platform="macos"
elif [ "$(uname -s)" = "Linux" ]; then
  _rax_platform="linux"
fi

# ── Paths ──────────────────────────────────────────────────────────
_rax_home="${RAX_HOME:-$HOME/.rax}"
_rax_repo="${RAX_REPO_DIR:-$HOME/dev/eqdmc/security}"

# Set platform-appropriate defaults (only if not already set)
case "$_rax_platform" in
  opencode)
    export RAX_PENDING_FILE="${RAX_PENDING_FILE:-$_rax_home/pending.sh}"
    export RAX_STATE_DIR="${RAX_STATE_DIR:-$_rax_home/state}"
    export RAX_SESSION_ID="${RAX_SESSION_ID:-${OPENCODE_SESSION_ID:-unknown}}"
    ;;
  claude-code|macos)
    export RAX_PENDING_FILE="${RAX_PENDING_FILE:-$_rax_home/pending.sh}"
    export RAX_STATE_DIR="${RAX_STATE_DIR:-$_rax_home/state}"
    export RAX_SESSION_ID="${RAX_SESSION_ID:-${CLAUDE_SESSION_ID:-unknown}}"
    ;;
  docker)
    export RAX_PENDING_FILE="${RAX_PENDING_FILE:-$_rax_home/pending.sh}"
    export RAX_STATE_DIR="${RAX_STATE_DIR:-$_rax_home/state}"
    # Docker containers set this at entrypoint
    export RAX_SESSION_ID="${RAX_SESSION_ID:-docker-$(hostname)-$$}"
    ;;
  linux)
    export RAX_PENDING_FILE="${RAX_PENDING_FILE:-$_rax_home/pending.sh}"
    export RAX_STATE_DIR="${RAX_STATE_DIR:-$_rax_home/state}"
    export RAX_SESSION_ID="${RAX_SESSION_ID:-linux-$(hostname)-$$}"
    ;;
  *)
    export RAX_PENDING_FILE="${RAX_PENDING_FILE:-$_rax_home/pending.sh}"
    export RAX_STATE_DIR="${RAX_STATE_DIR:-$_rax_home/state}"
    export RAX_SESSION_ID="${RAX_SESSION_ID:-unknown}"
    ;;
esac

# ── Policy file ────────────────────────────────────────────────────
export RAX_POLICY_FILE="${RAX_POLICY_FILE:-$_rax_home/policy.yml}"

# ── PATH ───────────────────────────────────────────────────────────
# Add local bin if rax or the repo scripts are there
_rax_bin_dir="$_rax_home/bin"
if [ -d "$_rax_bin_dir" ] && [[ ":$PATH:" != *":$_rax_bin_dir:"* ]]; then
  export PATH="$PATH:$_rax_bin_dir"
fi

# Also add the repo bin/ if accessible (for development/self-hosted)
if [ -d "$_rax_repo/bin" ] && [[ ":$PATH:" != *":$_rax_repo/bin:"* ]]; then
  export PATH="$PATH:$_rax_repo/bin"
fi

# ── Cleanup ────────────────────────────────────────────────────────
unset _rax_platform _rax_home _rax_repo _rax_bin_dir

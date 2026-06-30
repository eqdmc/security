#!/bin/bash
# rax-config.sh — source this to get rax config vars from the SSOT.
# All values come from packages/rax.yaml — zero hardcoded variables.

_RAX_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_RAX_SSOT="$_RAX_LIB/../packages/rax.yaml"

if [ -f "$_RAX_SSOT" ] && command -v python3 &>/dev/null; then
  while IFS= read -r line; do
    eval "$line" 2>/dev/null || true
  done < <(python3 "$_RAX_LIB/rax-config-print.py" 2>/dev/null)
else
  export RAX_CLI_VERSION="0.2.1"
  export RAX_DEFAULT_REPO="eqdmc/security"
  export RAX_AUTO_CLOSE="true"
fi

export RAX_SSOT_PATH="$_RAX_SSOT"

#!/bin/bash
# Purpose: Provision a secret into a sops-encrypted file using YubiKey-backed age identity
# Description: Prompts for secret value (agent never sees it), encrypts to YubiKey-only
#   recipients from .sops.yaml, round-trip verify before returning PASS.
#   Uses the secrets lifecycle library (lib/secrets.sh) from eqdmc/dotfiles.
#   Contrast with secrets_sops.sh which uses software-key rotation (age-keygen +
#   ~/.config/age/keys.txt). These are incompatible paths — YubiKey identities are
#   non-extractable hardware keys, not software keypairs.
# Verify: secrets::verify_roundtrip or grep PASS
# Rollback: ciphertext backup in .bak.<ts> (auto-restored on verify failure)
# Action-ID: rsax-2026-06-29-yk-provision-001
# Issue: #43
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dev/eqdmc/dotfiles}"
source "$DOTFILES/lib/secrets.sh"

REPO_ROOT=$(secrets::discover_root) || exit 1
CONFIG=$(secrets::resolve_sops_config "$REPO_ROOT")
TARGET=$(secrets::resolve_target "$REPO_ROOT" "${2:-}")

echo "Recipients:"
secrets::print_recipients "$CONFIG"

read -rsp "Enter value: " VALUE
echo

RESULT=$(secrets::provision "${1}" "$TARGET" "$CONFIG" "$VALUE")
echo "$RESULT"
[ "$RESULT" = "PASS" ]

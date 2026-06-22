#!/bin/bash
# Purpose: Rotate age identity and re-encrypt secrets
# Description: Generate new age keypair, update .sops.yaml recipient, run sops updatekeys
# Verify: sops -d secrets/infra.enc.env | head -1
# Rollback: mv ~/.config/age/keys.txt.bak ~/.config/age/keys.txt
# Action-ID: rsax-2026-04-22-age-rotate-7a3b
# Issue: #512
set -euo pipefail

cp ~/.config/age/keys.txt ~/.config/age/keys.txt.bak
age-keygen -o ~/.config/age/keys.txt
sops updatekeys secrets/infra.enc.env

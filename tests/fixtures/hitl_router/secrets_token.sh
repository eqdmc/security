#!/bin/bash
# Purpose: Replace CLOUDFLARE_API_TOKEN in the sops-encrypted env with a fresh token
# Verify: sops -d secrets/infra.enc.env | grep CLOUDFLARE_API_TOKEN
# Rollback: sops -d secrets/infra.enc.env.bak > /tmp/restore && mv /tmp/restore secrets/infra.enc.env
# Action-ID: rsax-2026-04-15-cf-token-001
set -euo pipefail

read -sp "Cloudflare API token: " TOKEN
echo
sops set secrets/infra.enc.env '["CLOUDFLARE_API_TOKEN"]' "\"$TOKEN\""

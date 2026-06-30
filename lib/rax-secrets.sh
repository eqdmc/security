#!/usr/bin/env bash
# rax-secrets.sh — Reusable secret provisioning library for rax/secrets flow.
#
# Every secret in eqdmc goes through this flow:
#   1. Collect metadata (provider, type, purpose, permissions, usage)
#   2. Wrap in YAML + encrypt with sops/age (YubiKey-backed)
#   3. Store in eqdmc/eqdmc/secrets/
#   4. Update token manifest in eqdmc/security
#   5. Clean up plaintext
#   6. Verify decryption works
#
# Source this from rax actions or bin/rax-secrets
#
# Usage:
#   source lib/rax-secrets.sh
#   rax_secrets_provision "github-app" "merge-bot" \
#     --provider github \
#     --purpose "PR review and merge approval" \
#     --permissions "pull_requests:write,contents:write" \
#     --usage "gh-merge-bot-auth (CLI tool)"
#
# Secret types:
#   github-app   — GitHub App private key (.pem)
#   pat          — Personal access token (classic or fine-grained)
#   api-key      — Third-party API key (Anthropic, DeepSeek, etc.)
#   ssh-key      — SSH private key
#   generic      — Other secret types

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

RAX_SECRETS_DIR="${RAX_SECRETS_DIR:-$HOME/dev/eqdmc/eqdmc/secrets}"
RAX_TOKEN_MANIFEST="${RAX_TOKEN_MANIFEST:-$HOME/dev/eqdmc/security/packages/tokens/manifest.json}"
RAX_SECURITY_REPO="${RAX_SECURITY_REPO:-$HOME/dev/eqdmc/security}"

# ── Type configurations ──────────────────────────────────────────
# Each type defines: file extension, sops input format, metadata schema
declare -A SECRET_TYPE_CONFIG
SECRET_TYPE_CONFIG[github-app]="pem|yaml|GitHub App private key"
SECRET_TYPE_CONFIG[pat]="env|yaml|Personal access token"
SECRET_TYPE_CONFIG[api-key]="env|env|Third-party API key"
SECRET_TYPE_CONFIG[ssh-key]="pem|yaml|SSH private key"
SECRET_TYPE_CONFIG[generic]="env|yaml|Generic secret"

rax_secrets_provision() {
  local type="${1:-}"; local name="${2:-}"; shift 2 || true
  local provider="" purpose="" permissions="" usage="" source_file=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --provider) provider="$2"; shift 2 ;;
      --purpose) purpose="$2"; shift 2 ;;
      --permissions) permissions="$2"; shift 2 ;;
      --usage) usage="$2"; shift 2 ;;
      --source) source_file="$2"; shift 2 ;;
      *) echo "Unknown: $1"; return 1 ;;
    esac
  done

  [ -z "$type" ] && { echo "ERROR: type required (github-app|pat|api-key|ssh-key|generic)"; return 1; }
  [ -z "$name" ] && { echo "ERROR: name required"; return 1; }
  [ -z "$provider" ] && { echo "ERROR: --provider required"; return 1; }
  [ -z "$purpose" ] && { echo "ERROR: --purpose required"; return 1; }

  local config="${SECRET_TYPE_CONFIG[$type]:-generic|env|yaml|Generic}"
  local ext="${config%%|*}"
  local rest="${config#*|}"
  local input_fmt="${rest%%|*}"
  local desc="${rest#*|}"
  local output_file="${RAX_SECRETS_DIR}/${name}.enc.${ext}"
  local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  echo ""
  echo "  ── rax/secrets: ${type} → ${name} ──"
  echo "  Provider:   ${provider}"
  echo "  Purpose:    ${purpose}"
  echo "  Output:     ${output_file}"
  echo ""

  # Step 1: Check YubiKey
  info "[1/6] Checking YubiKey..."
  if ! ykman info >/dev/null 2>&1; then
    echo "    ❌ YubiKey not found — insert and re-run"
    return 1
  fi
  echo "    ✅ YubiKey detected"

  # Step 2: Prepare input
  echo "  [2/6] Preparing input..."
  local tmp_input="/tmp/rax-secret-${name}.${input_fmt}"
  if [ -n "$source_file" ] && [ -f "$source_file" ]; then
    # Encode binary files (pem) as base64 for YAML wrapper
    if [ "$input_fmt" = "yaml" ]; then
      local b64=$(base64 -w0 < "$source_file")
      cat > "$tmp_input" << YAML
${name}: ${b64}
metadata:
  type: ${type}
  provider: ${provider}
  created: ${timestamp}
  purpose: ${purpose}
  permissions: ${permissions:-}
  usage: ${usage:-}
YAML
    else
      # Plain env format for api-keys
      echo "${name}=$(cat "$source_file")" > "$tmp_input"
    fi
    echo "    ✅ Input prepared from ${source_file}"
  else
    # Prompt for value
    echo "    Enter secret value (hidden input):"
    read -rs secret_value
    echo ""
    if [ "$input_fmt" = "yaml" ]; then
      local b64=$(echo -n "$secret_value" | base64 -w0)
      cat > "$tmp_input" << YAML
${name}: ${b64}
metadata:
  type: ${type}
  provider: ${provider}
  created: ${timestamp}
  purpose: ${purpose}
  permissions: ${permissions:-}
  usage: ${usage:-}
YAML
    else
      echo "${name}=${secret_value}" > "$tmp_input"
    fi
    echo "    ✅ Input prepared from prompt"
    unset secret_value
  fi

  # Step 3: Encrypt with sops
  echo "  [3/6] Encrypting with sops/age..."
  mkdir -p "$RAX_SECRETS_DIR"
  sops --encrypt --input-type "$input_fmt" --output-type "$input_fmt" \
    "$tmp_input" > "$output_file" 2>&1
  chmod 600 "$output_file"
  rm -f "$tmp_input"
  echo "    ✅ Encrypted → ${output_file}"

  # Step 4: Verify decryption
  echo "  [4/6] Verifying decryption..."
  if sops --decrypt "$output_file" >/dev/null 2>&1; then
    echo "    ✅ Decryption verified"
  else
    echo "    ❌ Decryption failed"
    rm -f "$output_file"
    return 1
  fi

  # Step 5: Update token manifest
  echo "  [5/6] Updating token manifest..."
  if [ -f "$RAX_TOKEN_MANIFEST" ]; then
    local token_id="${provider}-${name}"
    python3 -c "
import json, sys
path = '$RAX_TOKEN_MANIFEST'
with open(path) as f:
    m = json.load(f)
# Add or update token entry
found = False
for t in m.get('tokens', []):
    if t.get('id') == '$token_id':
        t['status'] = 'active'
        t['title'] = '$purpose'
        t['updated_at'] = '$timestamp'
        found = True
        break
if not found:
    entry = {
        'id': '$token_id',
        'type': '$type',
        'category': '$provider',
        'title': '$purpose',
        'created_at': '$timestamp',
        'status': 'active',
        'storage': {'location': '$output_file', 'format': 'sops+age (YubiKey)', 'encrypted': True},
        'permissions': {'scope': '$permissions'},
        'usage': [{'function': '$usage', 'repo': '$provider'}],
        'notes': 'Provisioned via rax/secrets'
    }
    m.setdefault('tokens', []).append(entry)
m['updated_at'] = '$timestamp'
m['updated_by'] = 'rax-secrets'
with open(path, 'w') as f:
    json.dump(m, f, indent=2)
    f.write('\n')
print('    ✅ Token manifest updated')
" 2>&1 || echo "    ⚠️  Could not update token manifest"
  fi

  # Step 6: Clean up source file if provided
  echo "  [6/6] Cleaning up..."
  if [ -n "$source_file" ] && [ -f "$source_file" ]; then
    rm -f "$source_file"
    echo "    ✅ Source file removed: ${source_file}"
  fi

  echo ""
  echo "  ✅ rax/secrets: ${name} provisioned successfully"
  echo "     Encrypted at: ${output_file}"
  echo "     Token ID:     ${provider}-${name}"
  echo "     To decrypt:   sops --decrypt ${output_file}"
}

export -f rax_secrets_provision

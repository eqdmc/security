#!/bin/bash
# Purpose: Fix bash 3.2 compat bug in system-bootstrap-deactivate
# Verify: bash --version | head -1
# Rollback: git checkout -- bin/system-bootstrap-deactivate
# Action-ID: rsax-2026-06-22-compat-fix-001
set -euo pipefail

chmod +x bin/system-bootstrap-deactivate
sed -i '' 's/declare -A/declare/' bin/system-bootstrap-deactivate

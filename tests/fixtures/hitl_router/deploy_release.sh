#!/bin/bash
# Purpose: Create GitHub release v2.0.0 for eqdmc/security
# Verify: gh release view v2.0.0 --repo eqdmc/security --json tagName -q .tagName
# Rollback: gh release delete v2.0.0 --repo eqdmc/security --yes
# Action-ID: rsax-2026-06-22-release-sec-v2-001
set -euo pipefail

gh release create v2.0.0 --repo eqdmc/security --title "rax v2.0.0" --notes "Portable HITL approval tool"

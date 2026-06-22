#!/bin/bash
# Purpose: Clean up accidental repo-template clone from ~/dev/
# Verify: test ! -d ~/dev/repo-template
# Rollback: n/a
# Action-ID: rsax-2026-06-22-cleanup-001
set -euo pipefail

rm -rf ~/dev/repo-template

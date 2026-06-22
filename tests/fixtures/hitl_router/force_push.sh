#!/bin/bash
# Purpose: Force-push rebased feat/818-hitl-merge to update PR #847
# Description: Rebase dropped the already-merged base commit; 2 commits remain
# Verify: gh pr view 847 --json mergeable -q .mergeable | grep -q MERGEABLE
# Rollback: git push origin a03ebb4:feat/818-hitl-merge --force
# Action-ID: rsax-2026-06-22-fpush-847-0001
set -euo pipefail

git push --force-with-lease origin feat/818-hitl-merge

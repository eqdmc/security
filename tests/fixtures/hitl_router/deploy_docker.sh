#!/bin/bash
# Purpose: Push agent sandbox image to ghcr.io
# Verify: docker manifest inspect ghcr.io/eqdmc/agent-sandbox:latest
# Rollback: n/a (tag can be overwritten)
# Action-ID: rsax-2026-06-22-docker-push-001
set -euo pipefail

docker push ghcr.io/eqdmc/agent-sandbox:latest

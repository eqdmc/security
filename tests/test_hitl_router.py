"""Tests for lib/hitl_router.py — HITL flow classification."""

from pathlib import Path

import pytest

from lib.hitl_router import classify_action, _parse_action

FIXTURES = Path(__file__).parent / "fixtures" / "hitl_router"


class TestClassifyAction:
    def test_merge_gh_pr_merge(self):
        assert classify_action(FIXTURES / "merge_pr.sh") == "merge"

    def test_merge_header_only(self):
        assert classify_action(FIXTURES / "merge_header_only.sh") == "merge"

    def test_secrets_sops(self):
        assert classify_action(FIXTURES / "secrets_sops.sh") == "secrets"

    def test_secrets_token(self):
        assert classify_action(FIXTURES / "secrets_token.sh") == "secrets"

    def test_secrets_yubikey(self):
        """YubiKey-backed provision classifies as secrets (matches sops, secret, api_key patterns)."""
        assert classify_action(FIXTURES / "secrets_yubikey.sh") == "secrets"

    def test_deploy_release(self):
        assert classify_action(FIXTURES / "deploy_release.sh") == "deploy"

    def test_deploy_docker(self):
        assert classify_action(FIXTURES / "deploy_docker.sh") == "deploy"

    def test_raw_chmod(self):
        assert classify_action(FIXTURES / "raw_chmod.sh") == "rax"

    def test_raw_cleanup(self):
        assert classify_action(FIXTURES / "raw_cleanup.sh") == "rax"

    def test_force_push_is_raw(self):
        assert classify_action(FIXTURES / "force_push.sh") == "rax"

    def test_nonexistent_file(self, tmp_path):
        assert classify_action(tmp_path / "missing.sh") == "rax"

    def test_empty_script(self, tmp_path):
        f = tmp_path / "empty.sh"
        f.write_text("#!/bin/bash\nset -euo pipefail\n")
        assert classify_action(f) == "rax"

    def test_deploy_wrangler(self, tmp_path):
        f = tmp_path / "deploy.sh"
        f.write_text(
            "#!/bin/bash\n"
            "# Purpose: Deploy worker to production\n"
            "set -euo pipefail\n"
            "wrangler deploy --env production\n"
        )
        assert classify_action(f) == "deploy"

    def test_secrets_ssh(self, tmp_path):
        f = tmp_path / "ssh.sh"
        f.write_text(
            "#!/bin/bash\n"
            "# Purpose: Add deploy key\n"
            "set -euo pipefail\n"
            "cp id_ed25519 ~/.ssh/deploy_key\n"
        )
        assert classify_action(f) == "secrets"

    def test_priority_merge_over_secrets(self, tmp_path):
        """Merge patterns checked first — a merge that mentions tokens classifies as merge."""
        f = tmp_path / "mixed.sh"
        f.write_text(
            "#!/bin/bash\n"
            "# Purpose: Merge the token rotation PR\n"
            "set -euo pipefail\n"
            "gh pr merge 100 --squash\n"
        )
        assert classify_action(f) == "merge"


class TestParseAction:
    def test_splits_headers_and_body(self):
        headers, body = _parse_action(FIXTURES / "merge_pr.sh")
        assert "Purpose:" in headers
        assert "gh pr merge" in body
        assert "set -euo" not in headers
        assert "set -euo" not in body

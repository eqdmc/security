"""Tests for bin/rax repo-awareness — Repo/Workdir validation, permission checks."""

import json
import os
import stat
import subprocess
from pathlib import Path

import pytest

RAX = Path(__file__).parent.parent / "bin" / "rax"


def _make_action(tmp_path, headers="", body="echo ok"):
    """Write a staged action script and return its path."""
    action = tmp_path / "pending.sh"
    lines = ["#!/bin/bash"]
    lines.append("# Purpose: Test action")
    if headers:
        for h in headers.split("\n"):
            if h.strip():
                lines.append(h)
    lines.append("# Action-ID: rsax-test-0001")
    lines.append("set -euo pipefail")
    lines.append(body)
    action.write_text("\n".join(lines) + "\n")
    action.chmod(0o600)
    return action


def _run_rax(action_path, cwd=None, env_extra=None, input_text="n\n"):
    """Run rax with the given pending file, auto-declining the prompt."""
    env = os.environ.copy()
    env["RAX_PENDING_FILE"] = str(action_path)
    env["RAX_STATE_DIR"] = str(action_path.parent / "state")
    env["RAX_SESSION_ID"] = "test-session"
    env["RAX_POLICY_FILE"] = str(Path(__file__).parent.parent / "config" / "rsax-policy.yml")
    if env_extra:
        env.update(env_extra)
    result = subprocess.run(
        ["bash", str(RAX)],
        cwd=cwd or str(action_path.parent),
        env=env,
        input=input_text,
        capture_output=True,
        text=True,
        timeout=10,
    )
    return result


class TestRepoMismatch:
    """Repo header vs git remote validation."""

    def test_matching_repo_shows_checkmark(self, tmp_path):
        action = _make_action(tmp_path, headers="# Repo: eqdmc/security")
        repo_root = Path(__file__).parent.parent
        result = _run_rax(action, cwd=str(repo_root))
        assert "BLOCKED" not in result.stdout
        assert result.returncode != 1 or "Cancelled" in result.stdout

    def test_mismatched_repo_blocks(self, tmp_path):
        action = _make_action(tmp_path, headers="# Repo: eqdmc/totally-different-repo")
        repo_root = Path(__file__).parent.parent
        result = _run_rax(action, cwd=str(repo_root))
        assert "BLOCKED" in result.stdout
        assert "Repository mismatch" in result.stdout
        assert result.returncode == 1

    def test_no_repo_header_warns(self, tmp_path):
        action = _make_action(tmp_path)
        repo_root = Path(__file__).parent.parent
        result = _run_rax(action, cwd=str(repo_root))
        assert "No # Repo: or # Workdir: header" in result.stdout


class TestWorkdirValidation:
    """Workdir header validation and auto-cd."""

    def test_valid_workdir_accepted(self, tmp_path):
        action = _make_action(tmp_path, headers=f"# Workdir: {tmp_path}")
        result = _run_rax(action)
        assert "BLOCKED" not in result.stdout

    def test_nonexistent_workdir_blocks(self, tmp_path):
        action = _make_action(tmp_path, headers="# Workdir: /nonexistent/path/that/does/not/exist")
        result = _run_rax(action)
        assert "BLOCKED" in result.stdout
        assert "Workdir does not exist" in result.stdout
        assert result.returncode == 1

    def test_workdir_shown_in_context(self, tmp_path):
        action = _make_action(tmp_path, headers=f"# Workdir: {tmp_path}")
        result = _run_rax(action)
        assert "Workdir:" in result.stdout
        assert str(tmp_path) in result.stdout


class TestPermissionCheck:
    """Pending file permission validation."""

    def test_600_accepted_silently(self, tmp_path):
        action = _make_action(tmp_path)
        action.chmod(0o600)
        result = _run_rax(action)
        assert "expected 600" not in result.stdout

    def test_644_warns(self, tmp_path):
        action = _make_action(tmp_path)
        action.chmod(0o644)
        result = _run_rax(action)
        assert "644" in result.stdout

    def test_755_warns(self, tmp_path):
        action = _make_action(tmp_path)
        action.chmod(0o755)
        result = _run_rax(action)
        assert "755" in result.stdout


class TestBackwardCompat:
    """No headers = warning + proceed (don't block)."""

    def test_no_context_headers_still_runs(self, tmp_path):
        action = _make_action(tmp_path)
        result = _run_rax(action)
        assert "BLOCKED" not in result.stdout
        assert result.returncode != 1 or "Cancelled" in result.stdout

    def test_both_headers_no_warning(self, tmp_path):
        repo_root = Path(__file__).parent.parent
        action = _make_action(
            tmp_path,
            headers=f"# Repo: eqdmc/security\n# Workdir: {repo_root}",
        )
        result = _run_rax(action, cwd=str(repo_root))
        assert "No # Repo: or # Workdir: header" not in result.stdout


class TestAuditRepoField:
    """Audit entries include repo and workdir fields."""

    def test_audit_includes_repo(self, tmp_path):
        repo_root = Path(__file__).parent.parent
        action = _make_action(
            tmp_path,
            headers=f"# Repo: eqdmc/security\n# Workdir: {repo_root}",
            body="echo audit-test",
        )
        state_dir = tmp_path / "state"
        result = _run_rax(action, cwd=str(repo_root), input_text="y\n")
        result_file = state_dir / "last-result.json"
        if result_file.exists():
            data = json.loads(result_file.read_text())
            assert data.get("repo") == "eqdmc/security"
            assert data.get("workdir") == str(repo_root)

    def test_audit_includes_detected_repo_when_no_header(self, tmp_path):
        repo_root = Path(__file__).parent.parent
        action = _make_action(tmp_path, body="echo audit-test")
        state_dir = tmp_path / "state"
        result = _run_rax(action, cwd=str(repo_root), input_text="y\n")
        result_file = state_dir / "last-result.json"
        if result_file.exists():
            data = json.loads(result_file.read_text())
            assert data.get("repo") == "eqdmc/security"


class TestRepoUrlParsing:
    """Verify the sed-based URL parser handles different remote formats."""

    def _parse_repo(self, url):
        """Use the same sed command as rax to parse a remote URL."""
        result = subprocess.run(
            [
                "bash",
                "-c",
                f"echo '{url}' | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\\.git$##'",
            ],
            capture_output=True,
            text=True,
        )
        return result.stdout.strip()

    def test_ssh_url(self):
        assert self._parse_repo("git@github.com:eqdmc/security.git") == "eqdmc/security"

    def test_https_url_with_git(self):
        assert self._parse_repo("https://github.com/eqdmc/security.git") == "eqdmc/security"

    def test_https_url_without_git(self):
        assert self._parse_repo("https://github.com/eqdmc/security") == "eqdmc/security"

    def test_codeberg_ssh(self):
        assert self._parse_repo("git@codeberg.org:user/repo.git") == "user/repo"

    def test_nested_path(self):
        assert (
            self._parse_repo("https://gitlab.com/group/subgroup/repo.git") == "group/subgroup/repo"
        )

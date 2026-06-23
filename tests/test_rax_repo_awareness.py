"""Tests for bin/rax repo-awareness — Repo/Workdir validation, permission checks."""

import json
import os
import subprocess
from pathlib import Path

import pytest

RAX = Path(__file__).parent.parent / "bin" / "rax"
REPO_ROOT = Path(__file__).parent.parent


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
    state_dir = str(action_path.parent / "state")
    env = os.environ.copy()
    env["RAX_PENDING_FILE"] = str(action_path)
    env["RAX_STATE_DIR"] = state_dir
    env["RAX_RESULT_FILE"] = f"{state_dir}/last-result.json"
    env["RAX_AUDIT_FILE"] = f"{state_dir}/audit.jsonl"
    env["RAX_SESSION_ID"] = "test-session"
    env["RAX_POLICY_FILE"] = str(REPO_ROOT / "config" / "rsax-policy.yml")
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

    def test_matching_repo_not_blocked(self, tmp_path):
        action = _make_action(tmp_path, headers="# Repo: eqdmc/security")
        result = _run_rax(action, cwd=str(REPO_ROOT))
        assert "BLOCKED" not in result.stdout
        assert "eqdmc/security" in result.stdout

    def test_mismatched_repo_blocks(self, tmp_path):
        action = _make_action(tmp_path, headers="# Repo: eqdmc/totally-different-repo")
        result = _run_rax(action, cwd=str(REPO_ROOT))
        assert "BLOCKED" in result.stdout
        assert "Repository mismatch" in result.stdout
        assert result.returncode == 1

    def test_no_repo_header_warns(self, tmp_path):
        action = _make_action(tmp_path)
        result = _run_rax(action, cwd=str(REPO_ROOT))
        assert "No # Repo: or # Workdir: header" in result.stdout

    def test_repo_validated_from_invoker_cwd_not_workdir(self, tmp_path):
        """Critical: repo check must use invoker's cwd, not Workdir's git remote."""
        workdir = tmp_path / "workdir"
        workdir.mkdir()
        action = _make_action(
            tmp_path,
            headers=f"# Repo: eqdmc/security\n# Workdir: {workdir}",
        )
        result = _run_rax(action, cwd=str(REPO_ROOT))
        assert "BLOCKED" not in result.stdout


class TestWorkdirValidation:
    """Workdir header validation and auto-cd."""

    def test_valid_workdir_accepted(self, tmp_path):
        action = _make_action(tmp_path, headers=f"# Workdir: {tmp_path}")
        result = _run_rax(action)
        assert "BLOCKED" not in result.stdout
        assert str(tmp_path) in result.stdout

    def test_workdir_changes_execution_directory(self, tmp_path):
        """Verify cd actually happens — action body runs in Workdir, not cwd."""
        workdir = tmp_path / "target"
        workdir.mkdir()
        action = _make_action(tmp_path, headers=f"# Workdir: {workdir}", body="pwd")
        result = _run_rax(action, input_text="y\n")
        assert str(workdir) in result.stdout

    def test_nonexistent_workdir_blocks(self, tmp_path):
        action = _make_action(tmp_path, headers="# Workdir: /nonexistent/path/that/does/not/exist")
        result = _run_rax(action)
        assert "BLOCKED" in result.stdout
        assert "Workdir does not exist" in result.stdout
        assert result.returncode == 1

    def test_workdir_file_not_directory_blocks(self, tmp_path):
        """A Workdir pointing to a file (not a directory) must block."""
        some_file = tmp_path / "not-a-dir.txt"
        some_file.write_text("not a directory")
        action = _make_action(tmp_path, headers=f"# Workdir: {some_file}")
        result = _run_rax(action)
        assert "BLOCKED" in result.stdout
        assert result.returncode == 1

    def test_workdir_shown_in_context(self, tmp_path):
        action = _make_action(tmp_path, headers=f"# Workdir: {tmp_path}")
        result = _run_rax(action)
        assert "Workdir:" in result.stdout
        assert str(tmp_path) in result.stdout

    def test_workdir_symlink_resolved(self, tmp_path):
        """Symlinks should be resolved via realpath."""
        real_dir = tmp_path / "real"
        real_dir.mkdir()
        link = tmp_path / "link"
        link.symlink_to(real_dir)
        action = _make_action(tmp_path, headers=f"# Workdir: {link}", body="pwd")
        result = _run_rax(action, input_text="y\n")
        assert str(real_dir) in result.stdout


class TestPermissionCheck:
    """Pending file permission validation."""

    def test_600_accepted_silently(self, tmp_path):
        action = _make_action(tmp_path)
        action.chmod(0o600)
        result = _run_rax(action)
        assert "expected 600" not in result.stdout
        assert "Pending file permissions" not in result.stdout

    def test_700_accepted_silently(self, tmp_path):
        action = _make_action(tmp_path)
        action.chmod(0o700)
        result = _run_rax(action)
        assert "expected 600" not in result.stdout
        assert "Pending file permissions" not in result.stdout

    def test_644_warns_with_message(self, tmp_path):
        action = _make_action(tmp_path)
        action.chmod(0o644)
        result = _run_rax(action)
        assert "Pending file permissions" in result.stdout
        assert "644" in result.stdout

    def test_755_warns_with_message(self, tmp_path):
        action = _make_action(tmp_path)
        action.chmod(0o755)
        result = _run_rax(action)
        assert "Pending file permissions" in result.stdout
        assert "755" in result.stdout


class TestBackwardCompat:
    """No headers = warning + proceed (don't block)."""

    def test_no_context_headers_still_runs(self, tmp_path):
        action = _make_action(tmp_path)
        result = _run_rax(action)
        assert "BLOCKED" not in result.stdout
        assert "Execute?" in result.stdout or "Type 'yes'" in result.stdout

    def test_both_headers_no_warning(self, tmp_path):
        action = _make_action(
            tmp_path,
            headers=f"# Repo: eqdmc/security\n# Workdir: {REPO_ROOT}",
        )
        result = _run_rax(action, cwd=str(REPO_ROOT))
        assert "No # Repo: or # Workdir: header" not in result.stdout


class TestAuditRepoField:
    """Audit entries include repo and workdir fields."""

    def test_result_json_includes_repo_and_workdir(self, tmp_path):
        action = _make_action(
            tmp_path,
            headers=f"# Repo: eqdmc/security\n# Workdir: {REPO_ROOT}",
            body="echo audit-test",
        )
        state_dir = tmp_path / "state"
        result = _run_rax(action, cwd=str(REPO_ROOT), input_text="y\n")
        result_file = state_dir / "last-result.json"
        assert result_file.exists(), (
            f"Result file not written; rc={result.returncode}, stderr={result.stderr}"
        )
        data = json.loads(result_file.read_text())
        assert data["repo"] == "eqdmc/security"
        assert data["workdir"] == str(REPO_ROOT)

    def test_audit_jsonl_includes_repo(self, tmp_path):
        action = _make_action(
            tmp_path,
            headers=f"# Repo: eqdmc/security\n# Workdir: {REPO_ROOT}",
            body="echo audit-jsonl-test",
        )
        state_dir = tmp_path / "state"
        result = _run_rax(action, cwd=str(REPO_ROOT), input_text="y\n")
        audit_file = state_dir / "audit.jsonl"
        assert audit_file.exists(), (
            f"Audit file not written; rc={result.returncode}, stderr={result.stderr}"
        )
        lines = audit_file.read_text().strip().splitlines()
        assert len(lines) >= 1
        entry = json.loads(lines[-1])
        assert entry["repo"] == "eqdmc/security"

    def test_result_includes_detected_repo_when_no_header(self, tmp_path):
        action = _make_action(tmp_path, body="echo audit-test")
        state_dir = tmp_path / "state"
        result = _run_rax(action, cwd=str(REPO_ROOT), input_text="y\n")
        result_file = state_dir / "last-result.json"
        assert result_file.exists(), (
            f"Result file not written; rc={result.returncode}, stderr={result.stderr}"
        )
        data = json.loads(result_file.read_text())
        assert data["repo"] == "eqdmc/security"

    def test_result_includes_original_dir_as_workdir_fallback(self, tmp_path):
        action = _make_action(tmp_path, body="echo workdir-fallback")
        state_dir = tmp_path / "state"
        result = _run_rax(action, cwd=str(REPO_ROOT), input_text="y\n")
        result_file = state_dir / "last-result.json"
        assert result_file.exists(), (
            f"Result file not written; rc={result.returncode}, stderr={result.stderr}"
        )
        data = json.loads(result_file.read_text())
        assert data["workdir"] == str(REPO_ROOT)


class TestRepoUrlParsing:
    """Verify the sed-based URL parser handles different remote formats.

    Uses the SAME sed expression as bin/rax to avoid divergence.
    """

    @pytest.fixture(autouse=True)
    def _load_sed_expr(self):
        """Extract the sed expression from bin/rax so tests track the real code."""
        rax_text = RAX.read_text()
        for line in rax_text.splitlines():
            if "DETECTED_REPO=" in line and "sed -E" in line:
                start = line.index("'") + 1
                end = line.rindex("'")
                self._sed_expr = line[start:end]
                return
        pytest.fail("Could not find DETECTED_REPO sed expression in bin/rax")

    def _parse_repo(self, url):
        result = subprocess.run(
            ["bash", "-c", f"echo '{url}' | sed -E '{self._sed_expr}'"],
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

    def test_ssh_scheme_url(self):
        assert self._parse_repo("ssh://git@github.com/eqdmc/security.git") == "eqdmc/security"

    def test_https_with_credentials(self):
        assert (
            self._parse_repo("https://oauth2:token@github.com/eqdmc/security.git")
            == "eqdmc/security"
        )

    def test_codeberg_ssh(self):
        assert self._parse_repo("git@codeberg.org:user/repo.git") == "user/repo"

    def test_nested_path(self):
        assert (
            self._parse_repo("https://gitlab.com/group/subgroup/repo.git") == "group/subgroup/repo"
        )

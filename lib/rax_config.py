"""rax config loader — reads the SSOT packages/rax.yaml.

All rax tools import this instead of hardcoding versions, repos, or paths.
Changes to rax.yaml propagate to all tools automatically.
"""

import os
from pathlib import Path

REPO_DIR = Path(__file__).parent.parent
SSOT_PATH = REPO_DIR / "packages" / "rax.yaml"

_config = None


def load():
    global _config
    if _config is not None:
        return _config
    try:
        import yaml
        with open(SSOT_PATH) as f:
            _config = yaml.safe_load(f)
        return _config
    except ImportError:
        return _fallback()
    except FileNotFoundError:
        return _fallback()


def _fallback():
    global _config
    _config = {
        "protocol": {"version": "0.2.1"},
        "cli": {"version": "0.2.1", "repo": "eqdmc/security"},
        "review": {"version": "0.2.1"},
        "issue": {"default_repo": "eqdmc/security", "title_prefix": "[rax] ",
                  "auto_close_on_verify": True, "labels": ["agent-work"]},
        "paths": {"pending_file": os.path.expanduser("~/.rax/pending.sh"),
                  "state_dir": os.path.expanduser("~/.rax/state"),
                  "result_file": os.path.expanduser("~/.rax/state/last-result.json"),
                  "audit_file": os.path.expanduser("~/.rax/state/audit.jsonl")},
        "types": {},
    }
    return _config


def cli_version():
    return load()["cli"]["version"]


def protocol_version():
    return load()["protocol"]["version"]


def default_repo():
    return load()["issue"]["default_repo"]


def type_config(type_name):
    return load().get("types", {}).get(type_name, {})


def all_types():
    return load().get("types", {})


def policy_config():
    return load().get("policy", {})


def issue_config():
    return load()["issue"]

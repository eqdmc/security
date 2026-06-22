"""HITL flow router — classify staged actions by command patterns."""

import re
from pathlib import Path

__version__ = "1.0.0"

MERGE_PATTERNS = [
    re.compile(r"\bgh\s+pr\s+merge\b"),
    re.compile(r"\bgit\s+merge\b"),
    re.compile(r"\bgh\s+pr\s+review\s+--approve\b"),
]

SECRETS_PATTERNS = [
    re.compile(r"~/\.ssh/|~/.gnupg/|\$HOME/\.ssh/|\$HOME/\.gnupg/"),
    re.compile(r"\b(sops|age-keygen|age)\b"),
    re.compile(r"\bkeepassxc\b", re.IGNORECASE),
    re.compile(r"(api[_-]?key|api[_-]?token|credentials?|passphrase)", re.IGNORECASE),
]

DEPLOY_PATTERNS = [
    re.compile(r"\bgh\s+release\s+(create|edit|delete)\b"),
    re.compile(r"\bdocker\s+push\b"),
    re.compile(r"\bnpm\s+publish\b"),
    re.compile(r"\bwrangler\s+(deploy|publish)\b"),
    re.compile(r"\bterraform\s+apply\b"),
]

HEADER_MERGE = re.compile(r"#\s*Purpose:.*\bmerge\s+(PR|pull\s+request)\b", re.IGNORECASE)
HEADER_SECRETS = re.compile(
    r"\b(secret|credential|token|key|password|encrypt|decrypt)\b", re.IGNORECASE
)
HEADER_DEPLOY = re.compile(r"\b(deploy|release|publish|ship)\b", re.IGNORECASE)


def _parse_action(script_path: Path) -> tuple[str, str]:
    """Parse a staged action into (headers, body)."""
    text = script_path.read_text()
    header_lines = []
    body_lines = []
    in_body = False

    for line in text.splitlines():
        if in_body:
            body_lines.append(line)
        elif line.startswith("#"):
            header_lines.append(line)
        elif line.strip().startswith("set "):
            in_body = True
        else:
            in_body = True
            body_lines.append(line)

    return "\n".join(header_lines), "\n".join(body_lines)


def classify_action(script_path: Path) -> str:
    """Classify a staged action script into a HITL flow category.

    Returns one of: merge | secrets | deploy | rax
    """
    if not script_path.exists():
        return "rax"

    headers, body = _parse_action(script_path)
    full_text = headers + "\n" + body

    if _matches(MERGE_PATTERNS, body) or HEADER_MERGE.search(headers):
        return "merge"

    if _matches(SECRETS_PATTERNS, body) or HEADER_SECRETS.search(headers):
        return "secrets"

    if _matches(DEPLOY_PATTERNS, body) or HEADER_DEPLOY.search(headers):
        return "deploy"

    return "rax"


def _matches(patterns: list[re.Pattern], text: str) -> bool:
    return any(p.search(text) for p in patterns)

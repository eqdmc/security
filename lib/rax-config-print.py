#!/usr/bin/env python3
"""Print rax config vars for shell sourcing.
Called by rax-config.sh. Reads from packages/rax.yaml SSOT.
Outputs: export VAR=value lines for shell eval.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
try:
    from rax_config import load
    c = load()
    print(f'export RAX_PROTOCOL_VERSION={c["protocol"]["version"]}')
    print(f'export RAX_CLI_VERSION={c["cli"]["version"]}')
    print(f'export RAX_DEFAULT_REPO={c["issue"]["default_repo"]}')
    print(f'export RAX_AUTO_CLOSE={str(c["issue"]["auto_close_on_verify"]).lower()}')
    _fb = c.get("feedback", {})
    print(f'export RAX_FEEDBACK_METHOD={_fb.get("method", "yn-goal-text")}')
except Exception as e:
    print(f'export RAX_CLI_VERSION=0.2.1', file=sys.stderr)
    print(f'export RAX_DEFAULT_REPO=eqdmc/security')
    print(f'export RAX_AUTO_CLOSE=true')
    print(f'export RAX_FEEDBACK_METHOD=yn-goal-text')

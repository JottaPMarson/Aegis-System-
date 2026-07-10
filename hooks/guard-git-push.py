#!/usr/bin/env python3
"""
guard-git-push.py
PreToolUse hook — blocks 'git push --force' and 'git push -f'.

Behavior: block (ask) by default. User must add AEGIS_ALLOW=1 to proceed.
Logs every attempt to ~/.aegis/security-hook.log.

Test (run from repo root):
  echo '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}' \
    | python3 hooks/guard-git-push.py

  echo '{"tool_name":"Bash","tool_input":{"command":"git push -f"}}' \
    | python3 hooks/guard-git-push.py

  echo '{"tool_name":"Bash","tool_input":{"command":"AEGIS_ALLOW=1 git push --force origin main"}}' \
    | python3 hooks/guard-git-push.py ; echo "exit: $?"

  echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' \
    | python3 hooks/guard-git-push.py ; echo "exit: $?"
"""

import importlib.util
import os
import re
import sys

# Load shared utility (hyphen in filename — can't use normal import)
_spec = importlib.util.spec_from_file_location(
    "require_confirmation",
    os.path.join(os.path.dirname(os.path.abspath(__file__)), "require-confirmation.py"),
)
_rc = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_rc)

PATTERN_NAME = "git-force-push"
REASON = (
    "Force-pushing rewrites remote history and can permanently destroy commits "
    "for all collaborators on the remote branch."
)
ALTERNATIVE = (
    "`git push --force-with-lease` — safer: fails if the remote has commits "
    "you haven't fetched yet, preventing accidental overwrites."
)

# Matches: git push --force, git push -f, git push origin main --force, etc.
REGEXES = [
    r"\bgit\s+push\b.*\s(--force|-f)\b",
    r"\bgit\s+push\b.*(--force|-f)\s",
    r"\bgit\s+push\s+(--force|-f)\b",
]


def is_force_push(command: str) -> bool:
    return any(re.search(rx, command, re.IGNORECASE) for rx in REGEXES)


def main() -> None:
    payload = _rc.read_stdin_json()
    command = _rc.get_bash_command(payload)

    if not command:
        sys.exit(0)

    if _rc.is_overridden(command):
        _rc.log_attempt(command, PATTERN_NAME, allowed=True)
        sys.exit(0)

    if not is_force_push(command):
        sys.exit(0)

    _rc.log_attempt(command, PATTERN_NAME, allowed=False)
    print(_rc.block_response(command, PATTERN_NAME, REASON, ALTERNATIVE))
    sys.exit(1)


if __name__ == "__main__":
    main()

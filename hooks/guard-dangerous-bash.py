#!/usr/bin/env python3
"""
guard-dangerous-bash.py
PreToolUse hook — blocks rm -rf and git reset --hard.

Behavior: escalates to user confirmation dialog (permissionDecision: "ask").
Logs detection to ~/.aegis/security-hook.log.
Patterns are documented in rules/security/dangerous-patterns.md.

Test (run from repo root):
  echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf ./dist"}}' \
    | python3 hooks/guard-dangerous-bash.py

  echo '{"tool_name":"Bash","tool_input":{"command":"git reset --hard HEAD~3"}}' \
    | python3 hooks/guard-dangerous-bash.py

  echo '{"tool_name":"Bash","tool_input":{"command":"rm -f single-file.txt"}}' \
    | python3 hooks/guard-dangerous-bash.py ; echo "exit: $?"
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

# Each entry: name, regexes (list), reason, alternative
# Source of truth for descriptions: rules/security/dangerous-patterns.md
PATTERNS = [
    {
        "name": "rm-rf",
        "regexes": [
            r"\brm\s+-rf\b",
            r"\brm\s+-fr\b",
            r"\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)\b",
            r"\brm\s+(--recursive\s+--force|--force\s+--recursive)\b",
        ],
        "reason": (
            "Recursive force-delete permanently removes files and directories. "
            "There is no undo — data is gone."
        ),
        "alternative": (
            "Move to a temp directory first: `mv <path> /tmp/backup-$(date +%s)/` "
            "Verify the contents, then delete only what you need."
        ),
    },
    {
        "name": "git-reset-hard",
        "regexes": [
            r"\bgit\s+reset\s+--hard\b",
        ],
        "reason": (
            "Hard reset permanently discards all uncommitted changes and "
            "removes unstaged files from the working tree."
        ),
        "alternative": (
            "`git stash` to save changes first (recoverable), or "
            "`git reset --mixed` to unstage without losing work."
        ),
    },
]


def match_pattern(command: str) -> dict | None:
    """Return the first matching PATTERNS entry, or None if the command is safe."""
    for pattern in PATTERNS:
        if any(re.search(rx, command, re.IGNORECASE) for rx in pattern["regexes"]):
            return pattern
    return None


def main() -> None:
    payload = _rc.read_stdin_json()
    command = _rc.get_bash_command(payload)

    if not command:
        sys.exit(0)

    pattern = match_pattern(command)
    if pattern is None:
        sys.exit(0)

    _rc.log_attempt(command, pattern["name"], allowed=False)
    print(_rc.block_response(command, pattern["name"], pattern["reason"], pattern["alternative"]))
    sys.exit(0)


if __name__ == "__main__":
    main()

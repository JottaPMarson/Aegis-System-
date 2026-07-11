#!/usr/bin/env python3
"""
Shared utility for all aegis security hooks.

Provides: read_stdin_json, get_bash_command, log_attempt, block_response
Each guard imports this via importlib (filename has a hyphen, can't use normal import).
"""

import json
import datetime
from pathlib import Path
import sys


def read_stdin_json() -> dict:
    try:
        return json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return {}


def get_bash_command(payload: dict) -> str:
    if payload.get("tool_name") != "Bash":
        return ""
    return payload.get("tool_input", {}).get("command", "")


def log_attempt(command: str, pattern_name: str, allowed: bool) -> None:
    log_dir = Path.home() / ".aegis"
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / "security-hook.log"
    timestamp = datetime.datetime.now().isoformat()
    status = "ALLOWED" if allowed else "BLOCKED_PENDING_USER"
    entry = f"{timestamp} | {status} | pattern={pattern_name} | cmd={command[:300]}\n"
    try:
        with open(log_file, "a") as f:
            f.write(entry)
    except OSError:
        pass


def block_response(command: str, pattern: str, reason: str, alternative: str) -> str:
    """Return JSON for stdout — exit 0 + this JSON triggers a user confirmation dialog.

    permissionDecision: "ask" escalates to the user via Claude Code's permission UI.
    The tool call proceeds only if the user explicitly approves in the dialog.
    """
    message = (
        f"AEGIS SECURITY HOOK — {pattern}\n\n"
        f"Command:\n  {command.strip()}\n\n"
        f"Risk: {reason}\n\n"
        f"Safe alternative: {alternative}\n\n"
        f"Audit log: ~/.aegis/security-hook.log"
    )
    return json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": message,
        }
    })

#!/usr/bin/env python3
"""
Shared utility for all aegis security hooks.

Provides: read_stdin_json, get_bash_command, is_overridden, log_attempt, block_response
Each guard imports this via importlib (filename has a hyphen, can't use normal import).
"""

import json
import datetime
import sys
from pathlib import Path


def read_stdin_json() -> dict:
    try:
        return json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return {}


def get_bash_command(payload: dict) -> str:
    if payload.get("tool_name") != "Bash":
        return ""
    return payload.get("tool_input", {}).get("command", "")


def is_overridden(command: str) -> bool:
    """User explicitly added AEGIS_ALLOW=1 — let the command through."""
    return "AEGIS_ALLOW=1" in command


def log_attempt(command: str, pattern_name: str, allowed: bool) -> None:
    log_dir = Path.home() / ".aegis"
    log_dir.mkdir(exist_ok=True)
    log_file = log_dir / "security-hook.log"
    timestamp = datetime.datetime.now().isoformat()
    status = "ALLOWED" if allowed else "BLOCKED"
    entry = f"{timestamp} | {status} | pattern={pattern_name} | cmd={command[:300]}\n"
    try:
        with open(log_file, "a") as f:
            f.write(entry)
    except OSError:
        pass


def block_response(command: str, pattern: str, reason: str, alternative: str) -> str:
    """Return JSON string for stdout — tells Claude Code to block and show context."""
    message = (
        f"AEGIS SECURITY HOOK — BLOCKED: {pattern}\n\n"
        f"Command:\n  {command.strip()}\n\n"
        f"Risk: {reason}\n\n"
        f"Safe alternative: {alternative}\n\n"
        f"To proceed anyway: add AEGIS_ALLOW=1 before the command and confirm "
        f"explicitly that you understand the risk.\n\n"
        f"Audit log: ~/.aegis/security-hook.log"
    )
    return json.dumps({"decision": "block", "reason": message})

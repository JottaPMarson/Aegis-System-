#!/usr/bin/env python3
"""
guard-phase2.py
PreToolUse hook — Phase 2 dangerous pattern detection.

Covers (from rules/security/dangerous-patterns.md):
  - git-clean               : git clean -fd / -fdx / -fX
  - git-branch-delete-protected : git branch -D on production branches
  - terraform-destroy       : terraform destroy
  - kubectl-delete-namespace: kubectl delete namespace <name>
  - docker-system-prune     : docker system prune -a
  - drop-table              : DROP TABLE / DROP DATABASE / TRUNCATE (SQL)
  - chmod-777               : chmod -R 777 (recursive world-write)
  - secrets-in-commit       : git add .env / secret files / API key patterns in command

Behavior: block by default. Add AEGIS_ALLOW=1 to override.
Logs to ~/.aegis/security-hook.log.

Test (run from repo root):
  echo '{"tool_name":"Bash","tool_input":{"command":"git clean -fd"}}' \
    | python3 hooks/guard-phase2.py

  echo '{"tool_name":"Bash","tool_input":{"command":"terraform destroy"}}' \
    | python3 hooks/guard-phase2.py
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

# Branch patterns treated as production — mirrors rules/security/production-scope.md
_PRODUCTION_BRANCH_PATTERNS = [
    r"^main$",
    r"^master$",
    r"^production$",
    r"^prod$",
    r"^release/.+",
]

# Filenames and extensions that must not be committed
_SECRET_FILENAME_PATTERNS = [
    r"(?:^|\s)\.env(?:\.\w+)?(?:\s|$)",
    r"(?:^|\s)\S+\.pem(?:\s|$)",
    r"(?:^|\s)\S+\.key(?:\s|$)",
    r"(?:^|\s)id_rsa(?:\s|$)",
    r"(?:^|\s)id_dsa(?:\s|$)",
    r"(?:^|\s)id_ecdsa(?:\s|$)",
    r"(?:^|\s)id_ed25519(?:\s|$)",
    r"(?:^|\s)\S*credentials?\.json(?:\s|$)",
    r"(?:^|\s)\S*secrets?\.json(?:\s|$)",
    r"(?:^|\s)\S*service[_-]?account\.json(?:\s|$)",
]

# API key / secret literal patterns that might appear in command strings
_SECRET_VALUE_PATTERNS = [
    r"AKIA[0-9A-Z]{16}",                          # AWS access key
    r"(?:sk|rk)_(?:live|test)_[0-9a-zA-Z]{24,}",  # Stripe key
    r"AIza[0-9A-Za-z\-_]{35}",                    # Google API key
    r"ghp_[0-9a-zA-Z]{36}",                       # GitHub personal access token
    r"github_pat_[0-9a-zA-Z_]{82}",               # GitHub fine-grained token
    r"xoxb-[0-9]{11}-[0-9]{11}-[a-zA-Z0-9]{24}", # Slack bot token
    r"EAA[a-zA-Z0-9]{100,}",                      # Facebook/Meta token
    r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY",  # PEM private key header
]


def _is_production_branch(name: str) -> bool:
    if os.environ.get("AEGIS_ENV") == "production":
        return True
    return any(re.match(p, name.strip(), re.IGNORECASE) for p in _PRODUCTION_BRANCH_PATTERNS)


def _extract_branch_delete_target(command: str) -> str | None:
    """Return the branch name from 'git branch -D <name>', or None."""
    m = re.search(
        r"\bgit\s+branch\s+(?:--delete\s+--force|--force\s+--delete|-D)\s+(\S+)",
        command,
        re.IGNORECASE,
    )
    return m.group(1) if m else None


def _is_git_add_secrets(command: str) -> bool:
    """True if command is a git add that includes a secret-looking filename."""
    if not re.search(r"\bgit\s+add\b", command, re.IGNORECASE):
        return False
    return any(re.search(p, command, re.IGNORECASE) for p in _SECRET_FILENAME_PATTERNS)


def _has_secret_value(command: str) -> bool:
    """True if the command string contains what looks like a hardcoded credential."""
    return any(re.search(p, command) for p in _SECRET_VALUE_PATTERNS)


def match_pattern(command: str) -> dict | None:
    """Return the first matching pattern dict, or None if the command is safe."""

    # git clean with -f combined with -d (directories), -x (all untracked), or -X (ignored only)
    # Blocks: -fd, -fdx, -fX, -fXd, -f -d, -f -X, etc.
    _gc = re.search(r"\bgit\s+clean\b(.*)", command, re.IGNORECASE)
    _gc_flags = _gc.group(1) if _gc else ""
    _has_force = bool(re.search(r"(?:^|\s)-[a-zA-Z]*f[a-zA-Z]*|(?:^|\s)--force\b", _gc_flags))
    _has_dangerous = bool(re.search(r"(?:^|\s)-[a-zA-Z]*[dxX][a-zA-Z]*", _gc_flags))
    if _gc and _has_force and _has_dangerous:
        return {
            "name": "git-clean",
            "reason": (
                "git clean removes untracked files and directories permanently. "
                "Untracked files are NOT in git history — they are gone with no undo."
            ),
            "alternative": (
                "Review untracked files first with `git status` or `git clean -n` (dry run). "
                "Move important files to a backup before cleaning."
            ),
        }

    # git branch -D on a production branch
    branch_target = _extract_branch_delete_target(command)
    if branch_target is not None and _is_production_branch(branch_target):
        return {
            "name": "git-branch-delete-protected",
            "reason": (
                f"Force-deleting a production branch (`{branch_target}`) "
                "removes all commits reachable only from that branch. Recovery requires "
                "access to reflog or remote backup."
            ),
            "alternative": (
                "Verify the branch is fully merged before deleting: "
                "`git branch --merged main | grep <branch>`. "
                "Use `git branch -d` (lowercase) — it refuses to delete unmerged branches."
            ),
        }

    # terraform destroy
    if re.search(r"\bterraform\s+destroy\b", command, re.IGNORECASE):
        return {
            "name": "terraform-destroy",
            "reason": (
                "terraform destroy tears down ALL managed infrastructure in the current workspace. "
                "Resources may take minutes to hours to recreate and may incur data loss."
            ),
            "alternative": (
                "Target specific resources with `-target=<resource>` to avoid full teardown. "
                "Run `terraform plan -destroy` first to preview what will be removed."
            ),
        }

    # kubectl delete namespace
    if re.search(r"\bkubectl\s+delete\s+namespace\b", command, re.IGNORECASE):
        return {
            "name": "kubectl-delete-namespace",
            "reason": (
                "Deleting a Kubernetes namespace terminates ALL pods, services, deployments, "
                "and persistent volume claims inside it. Stateful data may be lost."
            ),
            "alternative": (
                "Delete individual resources before the namespace, or drain the namespace "
                "by scaling all deployments to 0 first. Backup PVCs if data matters."
            ),
        }

    # docker system prune -a
    if re.search(r"\bdocker\s+system\s+prune\b.*-a\b", command, re.IGNORECASE) or \
       re.search(r"\bdocker\s+system\s+prune\b.*--all\b", command, re.IGNORECASE):
        return {
            "name": "docker-system-prune",
            "reason": (
                "docker system prune -a removes ALL unused images, containers, networks, "
                "and build cache — including images for projects not currently running."
            ),
            "alternative": (
                "Prune only stopped containers: `docker container prune`. "
                "Remove only dangling (untagged) images: `docker image prune`. "
                "Avoid `-a` to keep images that aren't attached to running containers."
            ),
        }

    # DROP TABLE / DROP DATABASE / TRUNCATE (SQL)
    if re.search(
        r"\b(DROP\s+TABLE|DROP\s+DATABASE|DROP\s+SCHEMA|TRUNCATE(?:\s+TABLE)?)\b",
        command,
        re.IGNORECASE,
    ):
        return {
            "name": "drop-table",
            "reason": (
                "SQL DROP and TRUNCATE permanently destroy table data and/or schema. "
                "Outside a transaction, this cannot be rolled back."
            ),
            "alternative": (
                "Wrap in a transaction and verify row counts before committing. "
                "For TRUNCATE, prefer DELETE with a WHERE clause to target specific rows. "
                "For DROP, take a schema + data dump first."
            ),
        }

    # chmod -R 777 (recursive world-writeable)
    if re.search(r"\bchmod\b.*-[a-zA-Z]*R[a-zA-Z]*\s+(?:0?777|a\+rwx|ugo\+rwx)\b", command) or \
       re.search(r"\bchmod\b.*(?:0?777|a\+rwx|ugo\+rwx)\s+.*-[a-zA-Z]*R[a-zA-Z]*\b", command):
        return {
            "name": "chmod-777",
            "reason": (
                "chmod -R 777 grants world read+write+execute permission to every file "
                "in the tree. Any user on the system (including web servers, cron jobs, "
                "and attackers with any foothold) can read, modify, or execute those files."
            ),
            "alternative": (
                "Use the minimum necessary permissions: "
                "`755` for directories, `644` for files, `600` for secrets. "
                "Fix ownership issues with `chown` rather than opening all permissions."
            ),
        }

    # secrets in git add (filename patterns)
    if _is_git_add_secrets(command):
        return {
            "name": "secrets-in-commit",
            "reason": (
                "You are staging a file that typically contains secrets or credentials. "
                "Once committed and pushed, secrets in git history are compromised — "
                "even if the file is deleted in a later commit."
            ),
            "alternative": (
                "Add the file to `.gitignore` immediately. "
                "Use environment variables or a secrets manager (AWS Secrets Manager, "
                "HashiCorp Vault, GitHub Secrets) instead of committing credentials. "
                "If the secret was already pushed: rotate it immediately, then purge history."
            ),
        }

    # hardcoded secret values in command string
    if _has_secret_value(command):
        return {
            "name": "secrets-in-command",
            "reason": (
                "The command appears to contain a hardcoded credential or API key. "
                "Shell history and Claude Code's logs may persist this value in plain text."
            ),
            "alternative": (
                "Store the secret in an environment variable and reference it as `$VAR_NAME`. "
                "Use a secrets manager for long-lived credentials. "
                "Rotate the exposed key immediately if it was already used."
            ),
        }

    return None


def main() -> None:
    payload = _rc.read_stdin_json()
    command = _rc.get_bash_command(payload)

    if not command:
        sys.exit(0)

    if _rc.is_overridden(command):
        _rc.log_attempt(command, "override", allowed=True)
        sys.exit(0)

    pattern = match_pattern(command)
    if pattern is None:
        sys.exit(0)

    _rc.log_attempt(command, pattern["name"], allowed=False)
    print(_rc.block_response(command, pattern["name"], pattern["reason"], pattern["alternative"]))
    sys.exit(1)


if __name__ == "__main__":
    main()

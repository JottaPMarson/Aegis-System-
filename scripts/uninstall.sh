#!/usr/bin/env bash
# uninstall.sh — Aegis plugin uninstaller
#
# Usage:
#   bash scripts/uninstall.sh            # reverses user-level install
#   bash scripts/uninstall.sh --project  # reverses project-level install
#
# Does NOT touch external MCPs (Serena, Lumen, Graphify, drawio-mcp-server).
# Asks before removing ~/.aegis/repo (may contain local customizations).

set -euo pipefail

AEGIS_DIR="${HOME}/.aegis"
AEGIS_REPO="${AEGIS_DIR}/repo"
CLAUDE_DIR="${HOME}/.claude"
RULES_GLOBAL="${CLAUDE_DIR}/rules/aegis"
SETTINGS_GLOBAL="${CLAUDE_DIR}/settings.json"

# Color output
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

ok()   { printf "%b[OK]%b   %s\n" "${GREEN}" "${NC}" "$*"; }
warn() { printf "%b[WARN]%b %s\n" "${YELLOW}" "${NC}" "$*"; }
fail() { printf "%b[FAIL]%b %s\n" "${RED}" "${NC}" "$*" >&2; exit 1; }
step() { printf "\n%b── %s%b\n" "${BOLD}" "$*" "${NC}"; }

# ── Parse flags ──────────────────────────────────────────────────────────────
PROJECT_MODE=false
for arg in "$@"; do
  case "$arg" in --project) PROJECT_MODE=true ;; esac
done

if $PROJECT_MODE; then
  RULES_TARGET=".claude/rules/aegis"
  SETTINGS_TARGET=".claude/settings.json"
  printf "\n%bAegis uninstaller%b — project mode\n" "${BOLD}" "${NC}"
else
  RULES_TARGET="${RULES_GLOBAL}"
  SETTINGS_TARGET="${SETTINGS_GLOBAL}"
  printf "\n%bAegis uninstaller%b — user mode\n" "${BOLD}" "${NC}"
fi

# ── Step 1: Uninstall plugin ─────────────────────────────────────────────────
step "Step 1/4 — Unregister plugin"

if command -v claude >/dev/null 2>&1; then
  if claude plugin list 2>/dev/null | grep -qi "aegis"; then
    if claude plugin uninstall aegis 2>/dev/null; then
      ok "Plugin unregistered"
    else
      warn "claude plugin uninstall failed — remove manually or check Claude Code docs."
    fi
  else
    warn "aegis plugin not registered — skipping"
  fi
else
  warn "claude CLI not found — plugin unregistration skipped."
  warn "To uninstall manually: claude plugin uninstall aegis"
fi

# ── Step 2: Remove rules ─────────────────────────────────────────────────────
step "Step 2/4 — Remove rules (${RULES_TARGET})"

if [ -d "${RULES_TARGET}" ]; then
  rm -rf "${RULES_TARGET}"
  ok "Removed ${RULES_TARGET}"
else
  warn "Rules directory not found at ${RULES_TARGET} — skipping"
fi

# ── Step 3: Remove Aegis hooks from settings.json ───────────────────────────
step "Step 3/4 — Remove Aegis hooks from ${SETTINGS_TARGET}"

if [ -f "${SETTINGS_TARGET}" ]; then
  python3 - "${SETTINGS_TARGET}" "${AEGIS_REPO}" <<'PYEOF'
import json, sys, pathlib

settings_path = sys.argv[1]
repo_path     = sys.argv[2]

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    print("Settings file missing or invalid — skipping hook removal.")
    sys.exit(0)

removed = 0
hooks = settings.get("hooks", {})

for event_type in list(hooks.keys()):
    cleaned_entries = []
    for entry in hooks[event_type]:
        # Remove hooks that reference the Aegis repo path
        remaining = [
            h for h in entry.get("hooks", [])
            if repo_path not in h.get("command", "")
        ]
        removed += len(entry.get("hooks", [])) - len(remaining)
        if remaining:
            cleaned_entry = dict(entry)
            cleaned_entry["hooks"] = remaining
            cleaned_entries.append(cleaned_entry)
    if cleaned_entries:
        hooks[event_type] = cleaned_entries
    else:
        del hooks[event_type]

if not hooks:
    del settings["hooks"]

pathlib.Path(settings_path).write_text(json.dumps(settings, indent=2) + "\n")
print(f"Removed {removed} Aegis hook(s).")
PYEOF
  ok "Hooks removed from ${SETTINGS_TARGET}"
else
  warn "Settings file not found — skipping hook removal"
fi

# ── Step 4: Optionally remove local repo ────────────────────────────────────
step "Step 4/4 — Local repo (${AEGIS_REPO})"

if [ -d "${AEGIS_REPO}" ]; then
  printf "  Remove %s? This deletes any local customizations. [y/N] " "${AEGIS_REPO}"
  read -r CONFIRM
  case "${CONFIRM}" in
    [yY]|[yY][eE][sS])
      rm -rf "${AEGIS_REPO}"
      # Remove ~/.aegis dir if empty
      rmdir "${AEGIS_DIR}" 2>/dev/null || true
      ok "Removed ${AEGIS_REPO}"
      ;;
    *)
      ok "Kept ${AEGIS_REPO} (skipped)"
      ;;
  esac
else
  warn "Repo directory not found at ${AEGIS_REPO} — skipping"
fi

printf "\n%bUninstall complete.%b External MCPs (Serena, Lumen, Graphify, drawio) were not modified.\n\n" \
  "${GREEN}" "${NC}"

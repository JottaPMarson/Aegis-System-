#!/usr/bin/env bash
# doctor.sh — Aegis health check
# Can be run at any time: bash scripts/doctor.sh [--project]
# Reports the status of plugin, rules, hooks, and recommended MCPs.

set -euo pipefail

AEGIS_REPO="${HOME}/.aegis/repo"
CLAUDE_DIR="${HOME}/.claude"
RULES_GLOBAL="${CLAUDE_DIR}/rules/aegis"
SETTINGS_GLOBAL="${CLAUDE_DIR}/settings.json"

# Color output (disabled when not a TTY)
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

ok()   { printf "  %b✓%b  %s\n" "${GREEN}" "${NC}" "$*"; }
warn() { printf "  %b!%b  %s\n" "${YELLOW}" "${NC}" "$*"; }
fail() { printf "  %b✗%b  %s\n" "${RED}" "${NC}" "$*"; }
head() { printf "\n%b%s%b\n" "${BOLD}" "$*" "${NC}"; }

# Parse flags
PROJECT_MODE=false
for arg in "$@"; do
  case "$arg" in --project) PROJECT_MODE=true ;; esac
done

if $PROJECT_MODE; then
  RULES_TARGET=".claude/rules/aegis"
  SETTINGS_TARGET=".claude/settings.json"
else
  RULES_TARGET="${RULES_GLOBAL}"
  SETTINGS_TARGET="${SETTINGS_GLOBAL}"
fi

ISSUES=0
issue() { fail "$*"; ISSUES=$((ISSUES + 1)); }

printf "\n%b Aegis Doctor%b\n" "${BOLD}" "${NC}"
printf " Checking your Aegis installation...\n"

# ── 1. Claude CLI ────────────────────────────────────────────────────────────
head "1. Claude CLI"
if command -v claude >/dev/null 2>&1; then
  CLAUDE_VERSION="$(claude --version 2>/dev/null | head -1 || echo 'version unknown')"
  ok "claude CLI found: ${CLAUDE_VERSION}"
else
  issue "claude CLI not found — install Claude Code to use Aegis"
fi

# ── 2. Plugin registration ───────────────────────────────────────────────────
head "2. Plugin"
if command -v claude >/dev/null 2>&1; then
  if claude plugin list 2>/dev/null | grep -qi "aegis"; then
    ok "aegis plugin is registered"
  else
    issue "aegis plugin not registered — run: cd ${AEGIS_REPO} && claude plugin install ."
  fi
else
  warn "Skipping plugin check (claude CLI not available)"
fi

# ── 3. Rules ────────────────────────────────────────────────────────────────
head "3. Rules (${RULES_TARGET})"
if [ -d "${RULES_TARGET}" ]; then
  RULE_COUNT=$(find "${RULES_TARGET}" -name "*.md" | wc -l | tr -d ' ')
  ok "Rules directory exists — ${RULE_COUNT} .md files found"

  # Spot-check critical rule files
  for f in common/stack-detection.md security/owasp-top10-2025.md; do
    if [ -f "${RULES_TARGET}/${f}" ]; then
      ok "  rules/${f}"
    else
      issue "  Missing: ${RULES_TARGET}/${f}"
    fi
  done
else
  issue "Rules directory not found at ${RULES_TARGET}"
  warn "  Run: scripts/install.sh$(${PROJECT_MODE} && echo ' --project' || echo '')"
fi

# ── 4. Hooks ────────────────────────────────────────────────────────────────
head "4. Hooks (${SETTINGS_TARGET})"
if [ -f "${SETTINGS_TARGET}" ]; then
  if python3 - "${SETTINGS_TARGET}" "${AEGIS_REPO}" <<'PYEOF' 2>/dev/null; then
import json, sys

settings_path = sys.argv[1]
repo_path     = sys.argv[2]

try:
    with open(settings_path) as f:
        settings = json.load(f)
except Exception:
    print("INVALID_JSON")
    sys.exit(1)

hooks = settings.get("hooks", {})
pre = hooks.get("PreToolUse", [])
aegis_hooks = [
    h["command"]
    for entry in pre
    for h in entry.get("hooks", [])
    if repo_path in h.get("command", "")
]

if aegis_hooks:
    for cmd in aegis_hooks:
        print(f"FOUND:{cmd}")
else:
    print("NOT_FOUND")
PYEOF
    HOOK_OUTPUT=$(python3 - "${SETTINGS_TARGET}" "${AEGIS_REPO}" 2>/dev/null || echo "ERROR")
    if echo "${HOOK_OUTPUT}" | grep -q "^FOUND:"; then
      HOOK_COUNT=$(echo "${HOOK_OUTPUT}" | grep -c "^FOUND:")
      ok "${HOOK_COUNT} Aegis hook(s) registered in ${SETTINGS_TARGET}"
    else
      issue "Aegis hooks not found in ${SETTINGS_TARGET}"
      warn "  Run: scripts/install.sh$(${PROJECT_MODE} && echo ' --project' || echo '')"
    fi
  else
    issue "Could not parse ${SETTINGS_TARGET} — may be invalid JSON"
  fi
else
  issue "Settings file not found: ${SETTINGS_TARGET}"
fi

# ── 5. Recommended MCPs ──────────────────────────────────────────────────────
head "5. Recommended MCPs"
if command -v claude >/dev/null 2>&1; then
  MCP_LIST="$(claude mcp list 2>/dev/null || echo '')"

  for mcp in serena lumen graphify drawio; do
    if echo "${MCP_LIST}" | grep -qi "${mcp}"; then
      ok "${mcp}"
    else
      warn "${mcp} — not configured (see SETUP.md for installation)"
    fi
  done
else
  warn "Skipping MCP check (claude CLI not available)"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
printf "\n"
if [ "${ISSUES}" -eq 0 ]; then
  printf "%b All checks passed.%b Aegis is ready.\n\n" "${GREEN}" "${NC}"
else
  printf "%b %d issue(s) found.%b See above for remediation steps.\n\n" \
    "${RED}" "${ISSUES}" "${NC}"
  exit 1
fi

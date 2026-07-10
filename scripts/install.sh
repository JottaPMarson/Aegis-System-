#!/usr/bin/env bash
# install.sh — Aegis plugin installer
#
# Usage:
#   bash scripts/install.sh            # user-level (all projects)
#   bash scripts/install.sh --project  # project-level (current directory only)
#
# Idempotent: safe to run again — updates the repo and re-copies rules without duplicating hooks.

set -euo pipefail

REPO_URL="https://github.com/JottaPMarson/Aegis-System-.git"
AEGIS_DIR="${HOME}/.aegis"
AEGIS_REPO="${AEGIS_DIR}/repo"
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
  printf "\n%bAegis installer%b — project mode (current directory: %s)\n" \
    "${BOLD}" "${NC}" "$(pwd)"
else
  RULES_TARGET="${RULES_GLOBAL}"
  SETTINGS_TARGET="${SETTINGS_GLOBAL}"
  printf "\n%bAegis installer%b — user mode (all projects)\n" "${BOLD}" "${NC}"
fi

# ── Prerequisites ────────────────────────────────────────────────────────────
step "Checking prerequisites"

command -v git    >/dev/null 2>&1 || fail "git is required. Install git and retry."
command -v python3 >/dev/null 2>&1 || fail "python3 is required. Install Python 3 and retry."
ok "git: $(git --version)"
ok "python3: $(python3 --version)"

CLAUDE_BIN=""
if command -v claude >/dev/null 2>&1; then
  CLAUDE_BIN="claude"
  ok "claude CLI: $(claude --version 2>/dev/null | head -1 || echo 'version unknown')"
else
  warn "claude CLI not found — plugin step will print a manual command instead."
fi

# ── Step 1: Clone / update repo ──────────────────────────────────────────────
step "Step 1/5 — Clone/update repo → ${AEGIS_REPO}"

mkdir -p "${AEGIS_DIR}"

if [ -d "${AEGIS_REPO}/.git" ]; then
  printf "  Repo exists, pulling latest...\n"
  if git -C "${AEGIS_REPO}" pull --ff-only; then
    ok "Repo updated"
  else
    warn "git pull failed (local changes?). Using existing repo as-is."
  fi
else
  git clone "${REPO_URL}" "${AEGIS_REPO}"
  ok "Repo cloned to ${AEGIS_REPO}"
fi

# ── Step 2: Install plugin ───────────────────────────────────────────────────
step "Step 2/5 — Register plugin with Claude Code"

if [ -n "${CLAUDE_BIN}" ]; then
  if (cd "${AEGIS_REPO}" && claude plugin install . 2>/dev/null); then
    ok "Plugin installed via 'claude plugin install .'"
  else
    warn "Plugin registration failed or the feature is not yet available in this Claude Code version."
    warn "To install manually, run:"
    warn "  cd ${AEGIS_REPO} && claude plugin install ."
  fi
else
  warn "Claude CLI not available. Install the plugin manually:"
  warn "  cd ${AEGIS_REPO} && claude plugin install ."
fi

# ── Step 3: Copy rules ───────────────────────────────────────────────────────
step "Step 3/5 — Copy rules → ${RULES_TARGET}"

mkdir -p "${RULES_TARGET}"
# Use -r and overwrite so re-runs are idempotent
cp -r "${AEGIS_REPO}/rules/." "${RULES_TARGET}/"
RULE_COUNT=$(find "${RULES_TARGET}" -name "*.md" | wc -l | tr -d ' ')
ok "Rules copied (${RULE_COUNT} .md files) → ${RULES_TARGET}"

# ── Step 4: Merge hooks ──────────────────────────────────────────────────────
step "Step 4/5 — Merge hooks → ${SETTINGS_TARGET}"

mkdir -p "$(dirname "${SETTINGS_TARGET}")"

python3 - "${SETTINGS_TARGET}" "${AEGIS_REPO}/hooks/hooks.json" "${AEGIS_REPO}" <<'PYEOF'
import json, sys, pathlib

settings_path = sys.argv[1]
hooks_path    = sys.argv[2]
repo_path     = sys.argv[3]

# Read current settings (create empty if missing or invalid)
try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

# Read Aegis hooks, resolving ${CLAUDE_PLUGIN_ROOT} to the actual repo path
with open(hooks_path) as f:
    raw = f.read().replace("${CLAUDE_PLUGIN_ROOT}", repo_path)
aegis_hooks = json.loads(raw)

if "hooks" not in settings:
    settings["hooks"] = {}

merged = 0
skipped = 0
for event_type, hook_entries in aegis_hooks.items():
    if event_type not in settings["hooks"]:
        settings["hooks"][event_type] = []

    for entry in hook_entries:
        matcher = entry.get("matcher")
        for hook in entry.get("hooks", []):
            cmd = hook.get("command", "")
            # Skip if already registered (idempotency)
            already = any(
                h.get("command") == cmd
                for existing_entry in settings["hooks"][event_type]
                if existing_entry.get("matcher") == matcher
                for h in existing_entry.get("hooks", [])
            )
            if already:
                skipped += 1
                continue
            # Find or create the matching matcher block
            target = next(
                (e for e in settings["hooks"][event_type]
                 if e.get("matcher") == matcher), None
            )
            if target is None:
                target = {"matcher": matcher, "hooks": []}
                settings["hooks"][event_type].append(target)
            target["hooks"].append(hook)
            merged += 1

# Write back with trailing newline
out = pathlib.Path(settings_path)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(settings, indent=2) + "\n")
print(f"Hooks: {merged} merged, {skipped} already present.")
PYEOF

ok "Hooks merged into ${SETTINGS_TARGET}"

# ── Step 5: Health check ─────────────────────────────────────────────────────
step "Step 5/5 — Running health check"

DOCTOR="${AEGIS_REPO}/scripts/doctor.sh"
if [ -f "${DOCTOR}" ]; then
  bash "${DOCTOR}" $(${PROJECT_MODE} && echo "--project" || true)
else
  warn "doctor.sh not found at ${DOCTOR} — skipping health check."
fi

printf "\n%bInstallation complete.%b\n" "${GREEN}" "${NC}"
printf "To verify at any time: bash %s/scripts/doctor.sh\n\n" "${AEGIS_REPO}"

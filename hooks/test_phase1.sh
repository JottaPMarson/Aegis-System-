#!/usr/bin/env bash
# Test all Phase 1 hooks without running Claude Code.
# Run from repo root: bash hooks/test_phase1.sh
# Each test prints PASS or FAIL with the scenario name.

set -euo pipefail

PASS=0
FAIL=0

run_hook() {
  local hook="$1"
  local payload="$2"
  echo "$payload" | python3 "hooks/$hook"
  return $?
}

assert_blocked() {
  local label="$1"
  local hook="$2"
  local payload="$3"
  output=$(echo "$payload" | python3 "hooks/$hook" 2>/dev/null || true)
  exit_code=$(echo "$payload" | python3 "hooks/$hook" > /dev/null 2>&1; echo $?) || true
  exit_code=$(echo "$payload" | python3 "hooks/$hook" 2>/dev/null; echo $?)
  # Re-run to capture exit code cleanly
  set +e
  echo "$payload" | python3 "hooks/$hook" > /dev/null 2>&1
  local code=$?
  set -e
  if [ "$code" -ne 0 ]; then
    echo "PASS: $label (exit $code — blocked)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (expected block, got exit 0)"
    FAIL=$((FAIL + 1))
  fi
}

assert_allowed() {
  local label="$1"
  local hook="$2"
  local payload="$3"
  set +e
  echo "$payload" | python3 "hooks/$hook" > /dev/null 2>&1
  local code=$?
  set -e
  if [ "$code" -eq 0 ]; then
    echo "PASS: $label (exit 0 — allowed)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (expected allow/exit 0, got exit $code)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Fase 1 Hook Tests ==="
echo ""

# ── guard-git-push.py ────────────────────────────────────────────────────────

echo "-- guard-git-push.py --"

assert_blocked "git push --force origin main" "guard-git-push.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git push --force origin main"}}'

assert_blocked "git push -f" "guard-git-push.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git push -f"}}'

assert_blocked "git push origin main --force" "guard-git-push.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git push origin main --force"}}'

assert_allowed "git push origin main (normal push)" "guard-git-push.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}'

assert_allowed "git push --force with AEGIS_ALLOW=1" "guard-git-push.py" \
  '{"tool_name":"Bash","tool_input":{"command":"AEGIS_ALLOW=1 git push --force origin main"}}'

assert_allowed "non-Bash tool ignored" "guard-git-push.py" \
  '{"tool_name":"Write","tool_input":{"command":"git push --force"}}'

echo ""

# ── guard-dangerous-bash.py ──────────────────────────────────────────────────

echo "-- guard-dangerous-bash.py --"

assert_blocked "rm -rf ./dist" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"rm -rf ./dist"}}'

assert_blocked "rm -fr /tmp/old" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"rm -fr /tmp/old"}}'

assert_blocked "git reset --hard HEAD~3" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git reset --hard HEAD~3"}}'

assert_blocked "git reset --hard (no target)" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git reset --hard"}}'

assert_allowed "rm -f single-file.txt" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"rm -f single-file.txt"}}'

assert_allowed "rm -rf with AEGIS_ALLOW=1" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"AEGIS_ALLOW=1 rm -rf ./dist"}}'

assert_allowed "git reset --mixed" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git reset --mixed HEAD~1"}}'

assert_allowed "git reset --soft" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git reset --soft HEAD~1"}}'

assert_allowed "non-Bash tool ignored" "guard-dangerous-bash.py" \
  '{"tool_name":"Write","tool_input":{"command":"rm -rf /"}}'

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

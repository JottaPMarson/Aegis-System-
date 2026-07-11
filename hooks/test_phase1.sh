#!/usr/bin/env bash
# Test all Phase 1 hooks without running Claude Code.
# Run from repo root: bash hooks/test_phase1.sh
#
# Detection logic: hooks now exit 0 in all cases.
# A dangerous command produces JSON with "permissionDecision" on stdout.
# A safe command produces no output (or no "permissionDecision" in output).

set -euo pipefail

PASS=0
FAIL=0

assert_blocked() {
  local label="$1"
  local hook="$2"
  local payload="$3"
  local output
  output=$(echo "$payload" | python3 "hooks/$hook" 2>/dev/null)
  if echo "$output" | grep -q '"permissionDecision"'; then
    echo "PASS: $label (ask decision returned)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (expected permissionDecision in output, got: $output)"
    FAIL=$((FAIL + 1))
  fi
}

assert_allowed() {
  local label="$1"
  local hook="$2"
  local payload="$3"
  local output exit_code
  exit_code=0
  output=$(echo "$payload" | python3 "hooks/$hook" 2>/dev/null) || exit_code=$?
  if [ "$exit_code" -eq 0 ] && ! echo "$output" | grep -q '"permissionDecision"'; then
    echo "PASS: $label (allowed — no permission decision)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label (expected no permissionDecision; exit=$exit_code output=$output)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Phase 1 Hook Tests ==="
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

assert_allowed "git reset --mixed" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git reset --mixed HEAD~1"}}'

assert_allowed "git reset --soft" "guard-dangerous-bash.py" \
  '{"tool_name":"Bash","tool_input":{"command":"git reset --soft HEAD~1"}}'

assert_allowed "non-Bash tool ignored" "guard-dangerous-bash.py" \
  '{"tool_name":"Write","tool_input":{"command":"rm -rf /"}}'

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

#!/usr/bin/env bash
# Test all Phase 2 hooks without running Claude Code.
# Run from repo root: bash hooks/test_phase2.sh
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

echo "=== Phase 2 Hook Tests ==="
echo ""

HOOK="guard-phase2.py"

# ── git clean ────────────────────────────────────────────────────────────────
echo "-- git-clean --"

assert_blocked "git clean -fd" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git clean -fd"}}'

assert_blocked "git clean -fdx" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git clean -fdx"}}'

assert_blocked "git clean -fX" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git clean -fX"}}'

assert_blocked "git clean -f -d" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git clean -f -d"}}'

assert_allowed "git clean -n (dry run)" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git clean -n"}}'

echo ""

# ── git branch -D protected ──────────────────────────────────────────────────
echo "-- git-branch-delete-protected --"

assert_blocked "git branch -D main" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git branch -D main"}}'

assert_blocked "git branch -D master" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git branch -D master"}}'

assert_blocked "git branch -D production" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git branch -D production"}}'

assert_blocked "git branch -D release/1.2.0" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git branch -D release/1.2.0"}}'

assert_allowed "git branch -D feat/my-feature" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git branch -D feat/my-feature"}}'

echo ""

# ── terraform destroy ────────────────────────────────────────────────────────
echo "-- terraform-destroy --"

assert_blocked "terraform destroy" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"terraform destroy"}}'

assert_blocked "terraform destroy -auto-approve" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"terraform destroy -auto-approve"}}'

assert_allowed "terraform plan" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"terraform plan"}}'

assert_allowed "terraform apply" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"terraform apply"}}'

echo ""

# ── kubectl delete namespace ─────────────────────────────────────────────────
echo "-- kubectl-delete-namespace --"

assert_blocked "kubectl delete namespace staging" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"kubectl delete namespace staging"}}'

assert_blocked "kubectl delete namespace prod --force" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"kubectl delete namespace prod --force"}}'

assert_allowed "kubectl delete pod my-pod" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"kubectl delete pod my-pod"}}'

assert_allowed "kubectl get namespace" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"kubectl get namespace"}}'

echo ""

# ── docker system prune -a ───────────────────────────────────────────────────
echo "-- docker-system-prune --"

assert_blocked "docker system prune -a" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"docker system prune -a"}}'

assert_blocked "docker system prune --all" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"docker system prune --all"}}'

assert_allowed "docker system prune (no -a)" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"docker system prune"}}'

assert_allowed "docker image prune" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"docker image prune"}}'

echo ""

# ── SQL DROP / TRUNCATE ──────────────────────────────────────────────────────
echo "-- drop-table --"

assert_blocked "DROP TABLE users" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP TABLE users\""}}'

assert_blocked "DROP DATABASE myapp" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP DATABASE myapp\""}}'

assert_blocked "TRUNCATE orders" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"psql -c \"TRUNCATE orders\""}}'

assert_blocked "TRUNCATE TABLE sessions" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"mysql -e \"TRUNCATE TABLE sessions\""}}'

assert_allowed "SELECT * FROM users" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"psql -c \"SELECT * FROM users\""}}'

echo ""

# ── chmod -R 777 ─────────────────────────────────────────────────────────────
echo "-- chmod-777 --"

assert_blocked "chmod -R 777 /var/www" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"chmod -R 777 /var/www"}}'

assert_blocked "chmod -R 0777 ." "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"chmod -R 0777 ."}}'

assert_allowed "chmod 755 script.sh" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"chmod 755 script.sh"}}'

assert_allowed "chmod -R 644 /var/www" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"chmod -R 644 /var/www"}}'

echo ""

# ── secrets in git add ───────────────────────────────────────────────────────
echo "-- secrets-in-commit --"

assert_blocked "git add .env" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git add .env"}}'

assert_blocked "git add .env.local" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git add .env.local"}}'

assert_blocked "git add id_rsa" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git add id_rsa"}}'

assert_blocked "git add server.key" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git add server.key"}}'

assert_blocked "git add cert.pem" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git add cert.pem"}}'

assert_allowed "git add src/config.py" "$HOOK" \
  '{"tool_name":"Bash","tool_input":{"command":"git add src/config.py"}}'

assert_allowed "non-Bash tool ignored" "$HOOK" \
  '{"tool_name":"Write","tool_input":{"command":"git clean -fd"}}'

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

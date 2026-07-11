---
name: debugging
description: Use when a test fails or unexpected behavior is reported: reproduce, localize via codebase navigation, form one hypothesis, verify, fix minimally, confirm no regressions.
---

# Skill: Debugging

Use when a test fails, a production error is reported, or behavior doesn't match the spec.

## Process

1. **Reproduce** — confirm the failure is reproducible before investigating. If not reproducible, ask for more context.
2. **Localize** — use the codebase navigation skill (Graphify → Lumen → Serena → Read) to find the relevant code. Do not grep blindly.
3. **Hypothesize** — form one hypothesis at a time. State it explicitly: "I think X is causing Y because Z."
4. **Verify** — check the hypothesis against the code or test output. Do not fix before verifying.
5. **Fix** — minimal change that addresses the root cause. Do not fix symptoms.
6. **Confirm** — run the failing test again. It must pass. Then run the full test suite — no regressions allowed.

## What not to do

- Do not add debug logging and forget to remove it.
- Do not fix the test to make it pass — fix the code the test is testing.
- Do not mark a bug fixed until the test passes in CI, not just locally.

## Dispatch to specialists

- Bug is in infrastructure: dispatch to `infra-engineer`.
- Bug is in a database query or schema: dispatch to `database-engineer`.
- Bug reveals a security issue: dispatch to `security-reviewer` before fixing.
- Otherwise: dispatch to the language agent for the stack in scope.

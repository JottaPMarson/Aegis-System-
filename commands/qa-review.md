---
description: Generate a test plan or validate test coverage for a scope. Usage — /aegis:qa-review <path or feature spec>
allowed-tools: Task, Read, Bash, Glob
---

Dispatch the **QA Engineer** specialist (`agents/qa-engineer.md`) for:

> $ARGUMENTS

## Instructions

1. Determine the mode from `$ARGUMENTS`:
   - **Generate test plan**: `$ARGUMENTS` describes a feature or spec (no implementation yet) → QA writes a test plan.
   - **Validate coverage**: `$ARGUMENTS` is a path to existing code → QA checks existing tests and reports gaps.
   - If unclear, ask the user: "Should I generate a test plan for a new feature, or validate coverage on existing code?"

2. Provide the QA Engineer with:
   - The feature spec or file path from `$ARGUMENTS`.
   - The project's test command (check `package.json`, `pyproject.toml`, `Makefile`, etc. via `Read`).
   - Any existing test files in the relevant path (run `Glob` for `*.test.*`, `*_test.*`, `spec/**`).

3. For **test plan mode**: QA returns a bullet list of scenarios (happy path, edge cases, failure modes, security inputs). Present the plan to the user for confirmation before any test code is written.

4. For **coverage validation mode**: QA reads existing tests, runs the test suite via `Bash`, and returns:
   - Pass/fail per test.
   - Gaps (scenarios from the spec not covered by existing tests).
   - Coverage delta if measurable.

5. Apply two-stage review on return:
   - **Stage 1 — Compliance**: does the plan cover the full scope? Are edge cases present?
   - **Stage 2 — Quality**: are test names descriptive? Does the plan avoid testing implementation details?

6. Present the plan or results to the user.

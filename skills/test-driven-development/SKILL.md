---
name: test-driven-development
description: Apply TDD as the default working mode: qa-engineer writes tests before implementation, chunks are marked complete only when all tests pass.
---

# Skill: Test-Driven Development

Apply TDD as the default working mode for all implementation tasks.

## The rule

Tests are defined in the Spec step — before implementation. No chunk is marked complete with failing tests in scope.

## Orchestrator responsibilities

1. In the Spec step: dispatch `qa-engineer` to write a test plan.
2. In the Plan step: include a "QA — write tests" chunk BEFORE the "implementation" chunk for each deliverable.
3. After implementation: dispatch `qa-engineer` to run tests and report results.
4. Mark the implementation chunk complete only when `qa-engineer` reports all tests passing.

## What counts as a test

- Unit tests for pure logic.
- Integration tests for I/O (database, external APIs, file system) — prefer real dependencies over mocks. Mocked I/O tests have passed when real ones failed; this has caused production incidents.
- Smoke tests for CLI or script outputs.
- Security property tests when `security-reviewer` flags a specific risk (SQL injection, XSS, etc.).

## What does NOT count

- Manual testing without a reproducible script.
- "I ran it and it seemed to work."
- Type checking (catches types, not behavior).
- Linting (catches style, not correctness).

## When to skip

Trivial tasks only: single-line typo fixes, comment updates, documentation edits. If in doubt, write the test.

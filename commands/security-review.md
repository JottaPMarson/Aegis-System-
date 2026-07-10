---
description: Run an OWASP Top 10:2025 security review on a scope (path, PR diff, or feature). Usage — /aegis:security-review <path or scope>
allowed-tools: Task, Read, Bash, Glob
---

Dispatch the **Security Reviewer** specialist (`agents/security-reviewer.md`) to review:

> $ARGUMENTS

## Instructions

1. If `$ARGUMENTS` is empty, determine the scope automatically:
   - Run `git diff --name-only HEAD~1` to identify files changed in the last commit.
   - If the repo is clean, ask the user: "What scope should be reviewed? (path, PR number, or feature description)"
2. Gather context before dispatching:
   - List the files in scope with `Glob` or `git diff`.
   - Note any auth, data persistence, or external API files in the list — flag them explicitly to the Reviewer.
3. Dispatch to `security-reviewer` with:
   - The list of files in scope.
   - The feature being reviewed (from `$ARGUMENTS` or inferred).
   - Path to `rules/security/owasp-top10-2025.md` as the review checklist.
4. Apply two-stage review on return:
   - **Stage 1 — Compliance**: all 10 OWASP categories addressed? Overall risk rating present?
   - **Stage 2 — Quality**: are findings actionable? Severity accurate?
5. Present findings to the user:
   - Per-category results (findings or "No findings").
   - Overall risk rating.
   - If Critical or High findings: pause and present them before proceeding. Do not continue with other work until the user decides.

Do not fix code from this command. Return findings to the orchestrator for dispatch to the language or infra agent.

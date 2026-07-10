---
description: Full pre-deploy checklist — infra, security, QA, and database (if migrations pending). Usage — /aegis:deploy-check [branch or scope]
allowed-tools: Task, Read, Bash, Glob
---

Run the **pre-deploy checklist** for:

> $ARGUMENTS

This command coordinates four specialists in sequence. Do not skip a step. If any step returns Critical or High findings, pause and present them to the user before continuing.

## Step 1 — Scope and context

1. Determine the deployment scope:
   - If `$ARGUMENTS` is a branch: `git diff main...$ARGUMENTS --name-only` to get changed files.
   - If `$ARGUMENTS` is empty: `git diff --name-only HEAD~1` (last commit) or ask for scope.
2. Categorize files by type:
   - **App code**: `.ts`, `.js`, `.py`, `.cs`, `.go`, `.php`, `.kt`, `.swift`, `.java`, `.rb`, `.rs`, `.dart`, `.cpp`
   - **Infra files**: `Dockerfile*`, `*.tf`, `k8s/**`, `.github/workflows/**`, `docker-compose*`
   - **DB files**: `migrations/**`, `db/migrate/**`, `prisma/migrations/**`, `flyway/**`, `alembic/versions/**`

## Step 2 — Security review

Dispatch `security-reviewer` on the **app code** files.

- Rules: `rules/security/owasp-top10-2025.md`
- **If Critical or High findings**: present to user immediately. Do not proceed to Step 3 until the user explicitly confirms to continue.

## Step 3 — Infra review (if infra files present)

Dispatch `infra-engineer` on the **infra files**.

- **If Critical findings**: present to user and pause.

## Step 4 — Database review (if DB files present)

Dispatch `database-engineer` on the **DB files** with the relevant rules file.

- Confirm no destructive migration runs without a backup/rollback plan.
- **If migration has irreversible changes** (DROP, TRUNCATE, column removal): flag explicitly to the user.

## Step 5 — QA status

Run the test suite via `Bash`:
- Check `package.json`, `pyproject.toml`, `Makefile`, or the project's CI config for the test command.
- Report: all tests passing? Any skipped? Coverage delta?
- **If tests are failing**: do not proceed. Report to user.

## Step 6 — Go / No-go summary

Present a consolidated report to the user:

```
## Deploy Check — [scope]

### Security
[Critical/High/Medium/Low/No findings]

### Infrastructure
[Findings or N/A]

### Database
[Migration summary, reversibility, or N/A]

### Tests
[Pass/Fail — X tests, Y skipped]

### Verdict
[ ] GO — all checks passed
[ ] NO-GO — [list blocking issues]
```

Do not push or deploy from this command. The verdict is a recommendation for the user to act on.

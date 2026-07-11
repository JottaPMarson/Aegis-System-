---
name: git-workflow
description: Apply these commit and branch rules to all git operations, including how to handle dangerous-operation intercepts from the Aegis security hooks.
---

# Skill: Git Workflow

Apply these rules to all git operations.

## Commit discipline

- One logical change per commit. If you can't describe it in one sentence, split it.
- Message format: `<type>: <summary>` — types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
- Summary: imperative mood, present tense ("add login endpoint", not "added" or "adds").
- No WIP commits on shared branches.

## Branch discipline

- Feature work: branch off the project's default branch. Name: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`.
- Never commit directly to `main`/`master`/`production` except trivial repo-setup chores.

## Dangerous operations (security hook intercepts these)

The aegis hooks intercept the following and open a **user confirmation dialog**:
- `git push --force` / `git push -f` → prefer `--force-with-lease` (fails if remote has commits you haven't fetched).
- `git reset --hard` → prefer `git stash` (recoverable) or `git reset --mixed` (unstages without losing work).

When the dialog appears, only the human user can approve or deny — the agent cannot self-approve.

## Before push checklist

1. All tests pass locally.
2. No debug code or leftover console.log / print statements.
3. No secrets or credentials in any committed file.
4. Commit messages are clean.

## Push to remote

Never push without a passing test suite. If CI is configured, confirm CI passes before merging to the default branch.

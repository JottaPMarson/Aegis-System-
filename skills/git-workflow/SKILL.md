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

The aegis hooks block the following — do not bypass without explicit user confirmation:
- `git push --force` / `git push -f` → prefer `--force-with-lease` (fails if remote has commits you haven't fetched).
- `git reset --hard` → prefer `git stash` (recoverable) or `git reset --mixed` (unstages without losing work).

To proceed after a block: add `AEGIS_ALLOW=1` before the command only after confirming the risk with the user.

## Before push checklist

1. All tests pass locally.
2. No debug code or leftover console.log / print statements.
3. No secrets or credentials in any committed file.
4. Commit messages are clean.

## Push to remote

Never push without a passing test suite. If CI is configured, confirm CI passes before merging to the default branch.

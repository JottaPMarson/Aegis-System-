# Contributing

## Adding a new language agent

1. Create `agents/lang-<x>.md` — copy the front-matter pattern from an existing language agent (e.g., `agents/lang-go.md`). Include: `description`, `tools`, marker file, framework detection, navigation order, and output contract.
2. Create `rules/<x>/base.md` with language conventions (naming, package management, async, error handling, testing, linting).
3. Create `rules/<x>/frameworks/` with a `.gitkeep` for now. Add `rules/<x>/frameworks/<framework>.md` when a specific framework is confirmed.
4. Add a row to `rules/common/stack-detection.md` (marker file → agent name).

No other files need to change.

## Adding a new framework to an existing language

Create `rules/<lang>/frameworks/<framework>.md`. The language agent reads it automatically when it detects the relevant dependency (e.g., `react` in `package.json`). No changes to the agent file.

## Adding a new database technology

Create `rules/database/<tech>.md` (e.g., `rules/database/mongodb.md`). The `database-engineer` agent reads this file when the technology is in scope. No changes to the agent file.

## Adding a new security hook pattern

Edit `rules/security/dangerous-patterns.md` (source of truth for pattern descriptions). Update the matching hook script (`hooks/guard-dangerous-bash.py` or `hooks/guard-git-push.py`) with the new regex pattern. Run `hooks/test_phase1.sh` to verify.

## Adding a new slash command

1. Create `commands/<name>.md` following the front-matter pattern of existing commands:

```markdown
---
description: One-line description shown in the command palette
allowed-tools: Task, Read, Bash, Glob
---

Command body. Use $ARGUMENTS for text typed after the command.
```

2. The command is immediately available as `/aegis:<name>` after `claude plugin install .`.
3. Update `README.md` command table and `CHANGELOG.md`.

## Commit discipline

Format: `<type>: <summary>` — types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.

One logical change per commit. Do not bundle Phase N and Phase N+1 work in the same commit.

## Scope discipline

One logical change per PR. Do not bundle unrelated fixes or features. Each change ends with a commit, push, and passing CI.

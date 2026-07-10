# Skill: Subagent Delegation

Use to decide which specialist agent to dispatch for a given task chunk.

## Decision table

| Task type | Specialist |
|---|---|
| Architecture, trade-offs, ADRs, system design | `agents/architect.md` |
| Security review, OWASP Top 10:2025, threat model | `agents/security-reviewer.md` |
| Test strategy, test plan, coverage | `agents/qa-engineer.md` |
| Code quality, readability, complexity | `agents/code-reviewer.md` |
| Infra: Docker, k8s, Terraform, AWS, CI/CD | `agents/infra-engineer.md` |
| DB schema, migrations, queries, cache strategy | `agents/database-engineer.md` |
| README, CHANGELOG, ADRs, API docs | `agents/docs-writer.md` |
| Implementation (language-specific) | `agents/lang-*.md` — see stack detection below |

## Stack detection (before every implementation dispatch)

Run `Glob` on the marker files listed in `rules/common/stack-detection.md` at the project root (or relevant subdirectory for monorepos). Match the marker to the agent in the table there.

- Multiple markers found (monorepo): dispatch to multiple language agents, one per subdirectory scope.
- No marker found: execute implementation directly as orchestrator. Log the gap — a new `agents/lang-<x>.md` + `rules/<x>/` is needed.

## Dispatch content (via Task tool)

Include in every dispatch:
1. **Goal**: the chunk's deliverable.
2. **Context**: spec summary, relevant file paths, constraints.
3. **Rules**: path to the specialist's rules file(s).
4. **Output contract**: what the specialist must return (defined in the agent's own `.md`).

## Parallel dispatch rules

- `qa-engineer` (test writing) and `architect` (design review) can run in parallel — no shared write scope.
- `infra-engineer` always runs in parallel with the language agent — they own different file scopes.
- All others run sequentially when touching the same files.

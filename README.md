# Aegis

**Adaptive Engineering & Governance Intelligence System** — a Claude Code plugin with a specialized team of sub-agents, security hooks, skills, and slash commands.

## What it is

Aegis replaces the generic sub-agent approach with a curated team of specialists that the orchestrator (`CLAUDE.md`) plans, delegates to, and reviews. Every implementation task goes through Brainstorm → Spec → Plan → Execute with TDD enforced from the Spec step.

---

## Agents

### Core specialists

| Agent | Dispatched when |
|---|---|
| `architect` | System design decisions, ADRs, blast-radius analysis, C4 diagrams |
| `security-reviewer` | OWASP Top 10:2025 review, CVE checks, hook audit |
| `qa-engineer` | Test plan (before implementation) and coverage validation (after) |
| `code-reviewer` | Quality gate: readability, duplication, complexity, rules adherence |
| `infra-engineer` | Docker, k8s, Terraform, AWS — runs in parallel with language agent |
| `database-engineer` | Schema, migrations, indexing, cache strategy |
| `docs-writer` | README, CHANGELOG, CONTRIBUTING, ADRs — last chunk of every feature |

### Language engineers (auto-detected by marker file)

| Agent | Marker file | Covers |
|---|---|---|
| `lang-js-ts` | `package.json` | JavaScript, TypeScript, React, Angular, NestJS, Node, etc. |
| `lang-python` | `requirements.txt` / `pyproject.toml` / `Pipfile` / `manage.py` | Django, FastAPI, Flask, general Python |
| `lang-csharp` | `*.csproj` / `*.sln` | ASP.NET Core, EF Core, general .NET |
| `lang-php` | `composer.json` | Laravel, Symfony, general PHP |
| `lang-go` | `go.mod` | Gin, Echo, Fiber, general Go |
| `lang-kotlin` | `build.gradle.kts` / `*.kt` majority | Android, Ktor, Kotlin Multiplatform |
| `lang-swift` | `Package.swift` / `*.xcodeproj` | SwiftUI, UIKit |
| `lang-dart` | `pubspec.yaml` | Flutter, general Dart |
| `lang-java` | `pom.xml` / `build.gradle` (Java) | Spring Boot, general JVM Java |
| `lang-ruby` | `Gemfile` | Rails, general Ruby |
| `lang-cpp` | `CMakeLists.txt` / `*.vcxproj` / `Makefile`+`.cpp` | General C++, CMake |
| `lang-rust` | `Cargo.toml` | axum, actix-web, general Rust |

---

## Slash commands

Invoke from Claude Code chat with `/aegis:<command> [scope]`. All commands accept an optional scope argument (file path, directory, PR description, branch name, or feature spec).

| Command | What it does |
|---|---|
| `/aegis:architect` | Dispatch the Architect for design decisions + ADR |
| `/aegis:diagram` | Generate/update a `.drawio` diagram (C4, sequence, infra) |
| `/aegis:security-review` | OWASP Top 10:2025 review on a scope |
| `/aegis:qa-review` | Generate a test plan or validate coverage for a scope |
| `/aegis:db-review` | Review schema, migration, indexes, or cache strategy |
| `/aegis:infra-review` | Review Dockerfile, k8s manifest, Terraform, or CI pipeline |
| `/aegis:code-review` | Quality review outside the automatic pipeline |
| `/aegis:deploy-check` | Full pre-deploy checklist: security + infra + QA + DB |

---

## Security hooks

Three `PreToolUse` hooks intercept dangerous commands before they run and require explicit opt-in (`AEGIS_ALLOW=1`):

| Pattern intercepted | Alternative suggested |
|---|---|
| `git push --force` / `git push -f` | `git push --force-with-lease` |
| `git reset --hard` | `git stash` or `git reset --mixed` |
| `rm -rf` / `rm -fr` | Move to `/tmp/` first, verify, then delete |

All attempts are logged to `~/.aegis/security-hook.log`.

---

## Skills

The orchestrator follows these skills (in `skills/`):

| Skill | Purpose |
|---|---|
| `brainstorming` | Explore problem space before committing to a solution |
| `writing-plans` | Break work into independently testable chunks |
| `executing-plans` | Dispatch, two-stage review, track progress |
| `test-driven-development` | Tests defined in Spec step, before implementation |
| `subagent-delegation` | Decision table: which agent for which task |
| `codebase-navigation` | Graphify → Lumen → Serena → Read (mandatory order) |
| `debugging` | Reproduce → Localize → Hypothesize → Verify → Fix |
| `git-workflow` | Commit discipline, branch rules, dangerous-op policy |
| `requesting-code-review` | When and how to dispatch `code-reviewer` |

---

## Recommended MCPs

| MCP | Navigation order | Used by |
|---|---|---|
| Graphify | 1st — structure/impact questions | architect, security-reviewer, database-engineer |
| Lumen | 2nd — location by meaning | all language agents, qa-engineer, code-reviewer |
| Serena | 3rd — precise symbol read/edit | all language agents, code-reviewer, database-engineer |
| drawio-mcp-server | — diagrams only | architect |

See `mcp-config/recommended-mcp.json` and `SETUP.md` for installation instructions.

---

## Status

`v0.1.0` — first release. All 7 phases complete.

| Phase | Description |
|---|---|
| 0 | Skeleton: .claude-plugin/plugin.json, CLAUDE.md, rules, skills |
| 1 | Security hooks: force-push, reset --hard, rm -rf |
| 2 | Core sub-agents: architect, security, QA, code-reviewer, infra, DB, docs |
| 3 | 12 language agents + base rules |
| 4 | MCP config, OWASP rules, database rules |
| 5 | 8 slash commands |
| 6 | Install/uninstall scripts (bash + PowerShell) |
| 7 | Docs finalization + v0.1.0 release |

See [docs/architecture/AEGIS-ARCHITECTURE.md](docs/architecture/AEGIS-ARCHITECTURE.md) for design decisions.

---

## Installation

```bash
# Linux / macOS — user level (all projects):
bash scripts/install.sh

# Project level (current directory only):
bash scripts/install.sh --project

# Windows (PowerShell):
.\scripts\install.ps1

# Verify:
bash scripts/doctor.sh
```

For MCP setup (Serena, Lumen, Graphify, drawio-mcp-server), see [SETUP.md](SETUP.md).

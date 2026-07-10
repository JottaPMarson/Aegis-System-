# Changelog

All notable changes to Aegis are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added

- `LICENSE` — PolyForm NonCommercial License 1.0.0: free for personal, research, education, and non-profit use; commercial use prohibited
- Branch protection on `main`: PR review required, linear history, no force pushes, no deletions, conversation resolution required, signed commits required

### Fixed

- `scripts/doctor.sh` — section 4 (hooks) always reported "not found" due to a double `python3` heredoc call: the heredoc was consumed by the `if` condition, leaving the second call without a script; restructured to a single call with captured output
- `docs/architecture/AEGIS-ARCHITECTURE.md §8.1` — hook decision value corrected from `ask` to `block` (with JSON stdout); clarified `AEGIS_ALLOW=1` override mechanism
- `docs/architecture/AEGIS-ARCHITECTURE.md §8.3` — replaced stale `.sh` filenames with the actual `.py` guard scripts; noted Phase 2 patterns as planned-but-not-implemented
- `docs/architecture/AEGIS-ARCHITECTURE.md §8.4` — clarified that `dangerous-patterns.md` is human reference only, not parsed at runtime by hook scripts

### Added

- `rules/cpp/frameworks/`, `rules/go/frameworks/`, `rules/rust/frameworks/` — placeholder dirs now consistent with all other language rules directories

### Removed

- `commands/.gitkeep`, `scripts/.gitkeep` — obsolete placeholder files removed now that both directories contain real files

---

## [0.1.0] — 2026-07-10

### Added

**Phase 7 — Docs finalization + v0.1.0 release**
- `README.md` — finalized: version badge updated to `v0.1.0`, all 7 phases marked complete, agent/command/skill/MCP tables
- `SETUP.md` — stale Phase 6 reference replaced with working `bash scripts/doctor.sh` code block in verify section
- `CHANGELOG.md` — `[Unreleased]` promoted to `[0.1.0] — 2026-07-10`; diff links added at bottom
- Git tag `v0.1.0` — initial release of the full Aegis Claude Code plugin

**Phase 6 — Installation scripts**
- `scripts/install.sh` — bash installer for Linux/macOS: clones/updates `~/.aegis/repo`, installs plugin, copies rules, merges hooks into settings.json; supports `--project` flag for per-project installs; fully idempotent (re-runs update, never duplicate)
- `scripts/uninstall.sh` — bash uninstaller: reverses install (plugin → rules → hooks → optional repo removal); asks before deleting `~/.aegis/repo`; does not touch external MCPs
- `scripts/doctor.sh` — standalone health check: verifies Claude CLI, plugin registration, rules directory, hooks in settings.json, and which of the 4 recommended MCPs are configured; exits non-zero if any check fails
- `scripts/install.ps1` — PowerShell equivalent of install.sh for Windows
- `scripts/uninstall.ps1` — PowerShell equivalent of uninstall.sh for Windows
- Hook merge uses Python inline script to resolve `${CLAUDE_PLUGIN_ROOT}` → actual repo path and merge without clobbering existing hooks from other plugins

**Phase 5 — Slash commands (8 commands)**
- `commands/architect.md` — `/aegis:architect`: dispatch Architect for design + ADR; two-stage review; presents blast radius and open questions
- `commands/diagram.md` — `/aegis:diagram`: dispatch Architect for drawio-mcp diagram generation; fallback to Mermaid/ASCII if MCP not installed
- `commands/security-review.md` — `/aegis:security-review`: OWASP Top 10:2025 review on a scope; auto-detects changed files if no scope given; pauses on Critical/High findings
- `commands/qa-review.md` — `/aegis:qa-review`: two modes — generate test plan (pre-impl) or validate coverage (post-impl); presents plan for user confirmation before writing tests
- `commands/db-review.md` — `/aegis:db-review`: schema/migration/index/cache review; auto-detects pending migration files; triggers infra hand-off flag when provisioning is involved
- `commands/infra-review.md` — `/aegis:infra-review`: Dockerfile/k8s/Terraform/CI review; triggers security hand-off on IAM/secrets; scoped to infra files only
- `commands/code-review.md` — `/aegis:code-review`: quality review outside automatic pipeline; auto-detects language and loads correct rules file; returns verdict (Approved / Needs changes)
- `commands/deploy-check.md` — `/aegis:deploy-check`: full 6-step pre-deploy checklist coordinating security-reviewer, infra-engineer, database-engineer, and QA test run; produces Go/No-go summary

**Phase 4 — MCP Integrations**
- `rules/security/owasp-top10-2025.md` — full OWASP Top 10:2025 reference with per-category checklists (A01–A10); used by `security-reviewer` agent
- `rules/database/postgresql.md` — schema design, indexing, migrations, and query rules for PostgreSQL
- `rules/database/dynamodb.md` — single-table design, key/index strategy, access pattern rules for DynamoDB
- `rules/database/redis-cache.md` — cache strategy, TTL, invalidation, stampede prevention, and security rules for Redis
- `rules/infra/` — placeholder directory for infrastructure conventions (to be populated in Phase 5+)
- `mcp-config/recommended-mcp.json` — updated with `install_hint`, `navigation_order`, and `known_limitation` for Graphify
- `SETUP.md` — expanded with exact `claude mcp add` commands, verification steps, and MCP navigation order table

**Phase 3 — Language sub-agents (12 agents + 12 base rules)**
- `agents/lang-js-ts.md` — JS and TypeScript engineer (same agent, framework detection via package.json signals)
- `agents/lang-python.md` — Python engineer (Django/FastAPI/Flask detection)
- `agents/lang-csharp.md` — C#/.NET engineer (ASP.NET Core detection)
- `agents/lang-php.md` — PHP engineer (Laravel/Symfony detection)
- `agents/lang-go.md` — Go engineer (Gin/Echo/Fiber detection)
- `agents/lang-kotlin.md` — Kotlin engineer (Android/Ktor/KMP detection)
- `agents/lang-swift.md` — Swift engineer (SwiftUI/UIKit detection)
- `agents/lang-dart.md` — Dart/Flutter engineer
- `agents/lang-java.md` — Java engineer (Spring Boot detection)
- `agents/lang-ruby.md` — Ruby engineer (Rails detection)
- `agents/lang-cpp.md` — C++ engineer (CMake/vcpkg toolchain)
- `agents/lang-rust.md` — Rust engineer (Cargo workspace support)
- `rules/js-ts/base.md` — JS/TS conventions (ES modules, async/await, TypeScript strict mode, testing)
- `rules/python/base.md` — Python conventions (type hints, ruff, pytest, asyncio)
- `rules/csharp/base.md` — C# conventions (nullable, async, DI, records, xUnit)
- `rules/php/base.md` — PHP conventions (strict_types, PSR-12, PHPStan, PHPUnit)
- `rules/go/base.md` — Go conventions (error handling, concurrency, gofmt, golangci-lint)
- `rules/kotlin/base.md` — Kotlin conventions (null safety, coroutines, sealed classes, Kotest)
- `rules/swift/base.md` — Swift conventions (optionals, async/await, actors, XCTest)
- `rules/dart/base.md` — Dart conventions (null safety, records, dart analyze, flutter test)
- `rules/java/base.md` — Java conventions (modern Java 17/21 features, Optional, Stream, JUnit 5)
- `rules/ruby/base.md` — Ruby conventions (RuboCop, idioms, RSpec)
- `rules/cpp/base.md` — C++ conventions (RAII, smart pointers, modern C++20, Google Test)
- `rules/rust/base.md` — Rust conventions (ownership, Result/?, clippy, cargo audit)
- Framework placeholder directories for all language rules (`.gitkeep`) — populated when frameworks are confirmed

**Phase 2 — Core sub-agents**
- `agents/architect.md` — system design, ADRs, C4 diagrams, blast-radius analysis via Graphify
- `agents/security-reviewer.md` — OWASP Top 10:2025 reviews, CVE checks, hook audit
- `agents/qa-engineer.md` — TDD: test plan before implementation, test run after
- `agents/code-reviewer.md` — cross-stack quality gate (readability, duplication, complexity, rules adherence)
- `agents/infra-engineer.md` — Docker, k8s, Terraform, AWS; runs in parallel with language agent
- `agents/database-engineer.md` — schema, migrations, indexing, cache strategy
- `agents/docs-writer.md` — README, CHANGELOG, CONTRIBUTING, ADRs; last chunk of every feature

**Phase 1 — Security hooks**
- `hooks/guard-git-push.py` — intercepts `git push --force` / `git push -f`; blocks, shows reason + safe alternative, logs to `~/.aegis/security-hook.log`
- `hooks/guard-dangerous-bash.py` — intercepts `rm -rf` and `git reset --hard`; same block/log/alternative pattern
- `hooks/require-confirmation.py` — shared utility: JSON stdin parsing, AEGIS_ALLOW=1 override, log writing, block response formatting
- `hooks/hooks.json` — registers both guards as `PreToolUse` matchers on `Bash`
- `rules/security/dangerous-patterns.md` — source of truth for pattern descriptions
- `rules/security/production-scope.md` — branch patterns considered production (`main`, `master`, `production`, `prod`, `release/*`); supports `AEGIS_ENV=production` override

**Phase 0 — Repository skeleton**
- `.claude-plugin/plugin.json` — plugin metadata (`name: aegis`, `version: 0.1.0`)
- `CLAUDE.md` — orchestrator: Brainstorm → Spec → Plan → Execute methodology, TDD, git discipline, delegation rules, two-stage review, skills reference
- `rules/common/stack-detection.md` — marker file → language agent mapping table (source of truth for auto-detection)
- `mcp-config/recommended-mcp.json` — MCP registry (Serena, Lumen, Graphify, drawio-mcp-server)
- `skills/` — 9 skill files for the orchestrator: brainstorming, writing-plans, executing-plans, TDD, subagent-delegation, codebase-navigation, debugging, git-workflow, requesting-code-review
- `docs/architecture/AEGIS-ARCHITECTURE.md` — full architecture reference document
- `README.md`, `SETUP.md`, `CHANGELOG.md`, `CONTRIBUTING.md` — project root documentation

---

[0.1.0]: https://github.com/JottaPMarson/Aegis-System-/releases/tag/v0.1.0

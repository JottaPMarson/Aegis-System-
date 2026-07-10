# Changelog

All notable changes to Aegis are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added

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
- `plugin.json` — plugin metadata (`name: aegis`, `version: 0.1.0`)
- `CLAUDE.md` — orchestrator: Brainstorm → Spec → Plan → Execute methodology, TDD, git discipline, delegation rules, two-stage review, skills reference
- `rules/common/stack-detection.md` — marker file → language agent mapping table (source of truth for auto-detection)
- `mcp-config/recommended-mcp.json` — MCP registry (Serena, Lumen, Graphify, drawio-mcp-server)
- `skills/` — 9 skill files for the orchestrator: brainstorming, writing-plans, executing-plans, TDD, subagent-delegation, codebase-navigation, debugging, git-workflow, requesting-code-review
- `docs/architecture/AEGIS-ARCHITECTURE.md` — full architecture reference document
- `README.md`, `SETUP.md`, `CHANGELOG.md`, `CONTRIBUTING.md` — project root documentation

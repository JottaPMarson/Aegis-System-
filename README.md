# Aegis

**Adaptive Engineering & Governance Intelligence System** — a Claude Code plugin with a specialized team of sub-agents, security hooks, and skills.

## What it is

A Claude Code plugin that replaces the generic sub-agent approach with a curated team of specialists:

- **12 language engineers** (JS/TS, Python, C#, C++, PHP, Go, Kotlin, Swift, Java, Rust, Ruby, Dart)
- **6 core specialists**: Architect, Security (OWASP Top 10:2025), QA, Code Reviewer, Infra/DevOps, Database/Cache
- **Security hooks** that intercept dangerous commands (`git push --force`, `rm -rf`, `git reset --hard`, etc.) and require explicit user confirmation before running
- **8 slash commands**: `/aegis:architect`, `/aegis:security-review`, `/aegis:qa-review`, `/aegis:db-review`, `/aegis:infra-review`, `/aegis:code-review`, `/aegis:deploy-check`, `/aegis:diagram`

## Status

`0.1.0-dev` — under active development. See [docs/architecture/AEGIS-ARCHITECTURE.md](docs/architecture/AEGIS-ARCHITECTURE.md) for design decisions.

## Installation

```bash
# Coming in Phase 6 — scripts/install.sh
```

See [SETUP.md](SETUP.md) for manual installation steps.

## Architecture

See [docs/architecture/AEGIS-ARCHITECTURE.md](docs/architecture/AEGIS-ARCHITECTURE.md).

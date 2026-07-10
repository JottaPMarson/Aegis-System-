# Contributing

## Adding a new language agent

1. Create `agents/lang-<x>.md` — copy the front-matter pattern from an existing language agent.
2. Create `rules/<x>/base.md` with language conventions.
3. Create `rules/<x>/frameworks/` when specific frameworks are confirmed (one file per framework).
4. Add a row to `rules/common/stack-detection.md` (marker file → agent name).

That's it. No other files need to change.

## Adding a new framework to an existing language

Create `rules/<lang>/frameworks/<framework>.md`. The language agent reads it automatically when it detects the relevant dependency.

## Adding a new security hook pattern

Edit `rules/security/dangerous-patterns.md` (source of truth). The hook scripts read from there — no code changes needed.

## Adding a new slash command

Create `commands/<name>.md` following the front-matter pattern of existing commands.

## Phases

Development follows the roadmap in [docs/architecture/AEGIS-ARCHITECTURE.md](docs/architecture/AEGIS-ARCHITECTURE.md) §12. Do not add code for a later phase until the current phase is tested and complete.

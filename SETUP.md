# Setup

## Automated (Linux / macOS)

```bash
# User-level install (works across all your projects):
bash scripts/install.sh

# Project-level install (rules/hooks scoped to the current directory):
bash scripts/install.sh --project

# Verify at any time:
bash scripts/doctor.sh

# Uninstall:
bash scripts/uninstall.sh
```

## Automated (Windows — PowerShell)

```powershell
# User-level:
.\scripts\install.ps1

# Project-level:
.\scripts\install.ps1 -Project

# Uninstall:
.\scripts\uninstall.ps1
```

### What the installer does (in order)

1. Clones or updates `~/.aegis/repo` from GitHub (idempotent — re-running pulls latest).
2. Registers the plugin: `claude plugin install .` (prints a manual command if the CLI is unavailable).
3. Copies `rules/` to `~/.claude/rules/aegis/` (or `.claude/rules/aegis/` with `--project`).
4. Merges Aegis hooks into `~/.claude/settings.json` without clobbering your existing hooks.
5. Runs `scripts/doctor.sh` to confirm everything is in place.

---

## Manual setup (if the automated scripts are unavailable)

---

### 1. Install the plugin

From the Aegis repo root:

```bash
claude plugin install .
```

### 2. Install recommended MCPs

Aegis works best with four MCPs. Two you may already have; two are optional but unlock the full navigation order (Graphify → Lumen → Serena → Read).

#### Serena (code read/edit by symbol via LSP)

```bash
claude mcp add serena -- uvx --from serena serena-language-server --context-window-tokens 40000
```

Verify: `claude mcp list` should show `serena` as active.

#### Lumen (semantic search by meaning)

```bash
claude mcp add lumen -- npx @ory/lumen-mcp
```

After installing, index your project:

```bash
# Inside your project directory:
npx @ory/lumen index
```

Verify: run `/lumen:doctor` inside Claude Code to confirm the index is active.

#### Graphify (code structure graph — first stop for impact questions)

See [https://github.com/Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) for installation steps.

Graphify installs its own `PreToolUse` hook that automatically redirects `Read`/`Glob` calls to the graph when it is running.

**Known limitation**: Graphify caches `graph.json` at startup. Use `--watch` mode or configure a `post-commit` hook to keep the graph current. Validate graph freshness before trusting structural answers.

#### drawio-mcp-server (diagram generation — used by architect agent)

See [https://www.drawio.com/docs/manual/generate/drawio-mcp-server/](https://www.drawio.com/docs/manual/generate/drawio-mcp-server/) for installation steps.

---

### 3. Verify

Check which MCPs are active:

```bash
claude mcp list
```

A full health check script (`scripts/doctor.sh`) will be available in Phase 6.

---

## MCP navigation order (for reference)

The `skills/codebase-navigation/SKILL.md` formalizes this, but here is the summary:

| Order | MCP | Use for |
|---|---|---|
| 1 | Graphify | Structure/impact questions ("what calls this", "what breaks if I change X") |
| 2 | Lumen | Location by meaning ("where is the code that does X") |
| 3 | Serena | Precise symbol read/edit once you know where to look |
| 4 | Read (raw) | Last resort — file outside indexed scope, or path already confirmed |

---

## Adding a framework

When a new framework is added to a project, create the corresponding rules file:

```
rules/<language>/frameworks/<framework>.md
```

No other files need to change. The language agent will detect the framework and load the rules file automatically.

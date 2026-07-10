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

### 2. Install recommended tools

Aegis works best with four tools. Install each independently — they have separate lifecycles.

#### Serena (code read/edit by symbol via LSP)

**Prerequisite:** [`uv`](https://docs.astral.sh/uv/getting-started/installation/) must be installed first.

```bash
# 1. Install Serena
uv tool install -p 3.13 serena-agent

# 2. Register with Claude Code (automatic setup)
serena setup claude-code
```

If you prefer to register manually:

```bash
claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
```

> **Note:** Do not install Serena via a Claude Code plugin marketplace — those entries are outdated. Use the commands above.

Verify: `claude mcp list` should show `serena` as active.

#### Lumen (semantic search by meaning)

Lumen is a **Claude Code plugin** (not a standalone MCP). It requires [Ollama](https://ollama.com) running locally with an embedding model.

```bash
# 1. Install Ollama and pull the embedding model
ollama pull ordis/jina-embeddings-v2-base-code
```

Then inside a Claude Code session, run these slash commands:

```
/plugin marketplace add ory/claude-plugins
/plugin install lumen@ory
```

Lumen indexes your project automatically on the first session start — no manual index step needed. To force a re-index: `/lumen:reindex`.

Verify: run `/lumen:doctor` inside Claude Code to confirm the index is active.

#### Graphify (code structure graph — first stop for impact questions)

**Prerequisite:** Python 3.10 or later.

```bash
pip install graphifyy && graphify install
```

To analyze a project, run `/graphify .` inside Claude Code. Graphify does **not** install any automatic hook — it is invoked manually via the slash command.

To keep the graph current after commits:

```bash
graphify hook install   # installs a git post-commit hook
# or use watch mode:
graphify ./raw --watch
```

**Known limitation**: Graphify caches `graph.json` at startup. Use `--watch` or the post-commit hook to keep the graph current. Validate graph freshness before trusting structural answers.

#### drawio (diagram generation — used by architect agent)

drawio is also a **Claude Code plugin**. Inside a Claude Code session:

```
/plugin marketplace add jgraph/drawio-mcp
/plugin install drawio@drawio
```

---

### 3. Verify

Check MCP servers (Serena appears here):

```bash
claude mcp list
```

Check installed plugins (Lumen and drawio appear here):

```bash
claude plugin list
```

Run the full Aegis health check at any time:

```bash
bash scripts/doctor.sh
```

---

## MCP navigation order (for reference)

The `skills/codebase-navigation/SKILL.md` formalizes this, but here is the summary:

| Order | MCP | Use for |
|---|---|---|
| 1 | Graphify | Structure/impact questions ("what calls this", "what breaks if I change X") — invoke via `/graphify .` |
| 2 | Lumen | Location by meaning ("where is the code that does X") — `mcp__lumen__semantic_search` |
| 3 | Serena | Precise symbol read/edit once you know where to look |
| 4 | Read (raw) | Last resort — file outside indexed scope, or path already confirmed |

---

## Adding a framework

When a new framework is added to a project, create the corresponding rules file:

```
rules/<language>/frameworks/<framework>.md
```

No other files need to change. The language agent will detect the framework and load the rules file automatically.

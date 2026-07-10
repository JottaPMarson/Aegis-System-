# Setup

## Automated (Phase 6 — not yet available)

```bash
./scripts/install.sh
```

Until `scripts/install.sh` is implemented (Phase 6), follow the manual steps below.

---

## Manual setup

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

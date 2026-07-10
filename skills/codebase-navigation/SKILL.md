# Skill: Codebase Navigation

Use for all code discovery tasks. Follow the order below — do not jump straight to `Read` or `Grep`.

## Order of tools (mandatory)

### 1. Graphify — structural and relational questions

Use first when asking: "what calls this function", "what breaks if I change X", "how does A connect to B", "what are the dependencies of this module".

Tools: `graph_search`, `graph_impact`, `graph_path`, `graph_explain`, `graph_hotspots`.

Graphify is invoked manually via `/graphify .` inside Claude Code — it does not install any automatic hook. Run it before starting structural analysis, then query the graph with `graph_search`, `graph_impact`, `graph_path`, `graph_explain`.

**If Graphify is not available**: skip to step 2 and note the gap.

**Known limitation**: Graphify caches `graph.json` at startup. After significant code changes, verify the graph is current. Use `--watch` mode or the project's post-commit hook if configured. Do not trust structural answers from a stale graph — this is flagged as a validation item for Phase 4.

### 2. Lumen — semantic location

Use when asking: "where is the code that does X", "find the payment processing logic", "where do we validate email addresses".

Tool: `mcp__lumen__semantic_search` — call this BEFORE `Grep`/`Bash find`/`Read` for any location-by-meaning question.

Lumen finds by meaning, not by keyword. It does NOT enforce itself via a hook; the discipline lives in this skill.

**If Lumen is unavailable or returns no results**: fall back to step 3.

### 3. Serena — precise symbol-level reading and editing

Use once you know exactly which file and symbol to look at.

Tools: `find_symbol`, `find_declaration`, `find_implementations`, `find_referencing_symbols`, `replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`.

Serena uses the live language server (LSP) — it reads the actual source, not an index snapshot. This is the correct tool for editing. Neither Graphify nor Lumen replace this step: the graph is a structural map, the Lumen chunks are candidate excerpts — neither is a safe edit surface.

### 4. Read (raw) — last resort only

Use only when:
- The file is outside the indexed scope (generated code, vendored files, config files without LSP support).
- The graph or embeddings are stale or unavailable.
- The exact file path was already confirmed in the same session by a prior tool call.

## Rule for all agents

No agent uses `Read` or `Bash` to answer a structural or discovery question without first checking Graphify (step 1) or Lumen (step 2) — unless the file path was provided explicitly in the same task dispatch.

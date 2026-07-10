# Setup

## Automated (Phase 6+)

```bash
./scripts/install.sh
```

## Manual

### 1. Install the plugin

```bash
# From the aegis repo root:
claude plugin install .
```

### 2. Install recommended MCPs

```bash
# Serena (already installed if you have it)
claude mcp add serena -- <your serena command>

# Lumen (already installed if you have it)
claude mcp add lumen -- <your lumen command>

# Graphify (to install)
claude mcp add graphify -- <graphify command>

# drawio-mcp-server (to install)
claude mcp add drawio -- <drawio command>
```

See `mcp-config/recommended-mcp.json` for each MCP's purpose and which agents use it.

### 3. Verify

```bash
# Coming in Phase 6:
./scripts/doctor.sh
```

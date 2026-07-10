---
description: Generate or update a .drawio diagram via the Architect agent and drawio-mcp-server. Usage — /aegis:diagram <what to diagram>
allowed-tools: Task, Read, Glob
---

Dispatch the **Architect** specialist (`agents/architect.md`) to generate or update a diagram for:

> $ARGUMENTS

## Instructions

1. If `$ARGUMENTS` is empty, ask the user: "What should be diagrammed? (Examples: C4 context, sequence flow for auth, infrastructure layout)"
2. Determine the diagram type from the scope:
   - System overview → C4 Context diagram
   - Component breakdown → C4 Container or Component diagram
   - Request flow → Sequence diagram
   - Deployment → Infrastructure diagram
3. Provide the Architect with:
   - The diagram type and scope above.
   - Relevant file paths (read existing architecture files in `docs/architecture/` first).
4. The Architect will use drawio-mcp-server to produce or update the `.drawio` file in `docs/architecture/`.
5. After the Architect returns, confirm:
   - The diagram file path exists.
   - The diagram accurately reflects the described scope.
6. Present the diagram path to the user.

If drawio-mcp-server is not installed, instruct the Architect to produce a textual diagram (Mermaid or ASCII) as a fallback and note that drawio-mcp-server installation is required for `.drawio` output (see `SETUP.md`).

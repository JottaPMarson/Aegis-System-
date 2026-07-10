---
description: Dispatch the Architect agent for system design decisions, trade-offs, ADRs, and blast-radius analysis. Usage — /aegis:architect <question or scope>
allowed-tools: Task, Read, Bash, Glob
---

Dispatch the **Architect** specialist (`agents/architect.md`) for the following design question or scope:

> $ARGUMENTS

## Instructions

1. If `$ARGUMENTS` is empty, ask the user: "What design decision or architectural question should the Architect investigate?"
2. Provide the Architect with:
   - The question or scope above.
   - Relevant file paths if detectable (run `Glob` on the affected area first).
   - Any constraints or decisions already made in this session.
3. The Architect must use Graphify first (impact/blast radius), then Lumen, then Read — as specified in `agents/architect.md`.
4. After the Architect returns, apply the two-stage review:
   - **Stage 1 — Compliance**: did the Architect answer the specific question? Produce an ADR?
   - **Stage 2 — Quality**: is the reasoning sound? Are there gaps or unresolved trade-offs?
5. Present findings to the user: decision summary, ADR path, blast radius, and open questions.

Do not implement any code from this command. If the decision requires implementation, present it to the user first.

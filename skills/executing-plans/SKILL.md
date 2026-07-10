# Skill: Executing Plans

Use once a plan is confirmed. Dispatch each chunk to the right specialist and review results before proceeding.

## Dispatch protocol

1. Read the current chunk from the plan.
2. Identify the specialist from the chunk's "Specialist:" field.
3. Dispatch via `Task` with: the chunk's deliverable as the goal; all relevant context (spec, file paths, constraints); the rules file path for the specialist's domain.
4. Wait for the specialist to return before proceeding.

## Two-stage review (mandatory for every chunk)

**Stage 1 — Compliance**: Does the output match the chunk's deliverable? Is it complete?
- If no: return to the specialist with specific, actionable feedback. Do not proceed to Stage 2.

**Stage 2 — Quality**: Is it correct? Are there issues to flag?
- Minor issues (< 5 lines, purely mechanical): fix yourself and note it.
- Non-trivial issues: return to the specialist with specific feedback.

Only after both stages pass: mark the chunk complete and move to the next.

## Progress tracking

After each chunk is marked complete, update the plan status. If a chunk reveals new work (scope expansion), add a new chunk to the plan and note the expansion — do not silently absorb extra scope.

## Stopping conditions

- A test chunk fails: do not proceed to the next implementation chunk. Fix the failure first.
- Security review returns Critical or High findings: pause the plan. Present findings to the user before continuing.
- The user revises the spec mid-execution: update the plan, confirm the update with the user, then continue.

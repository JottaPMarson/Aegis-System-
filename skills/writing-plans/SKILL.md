# Skill: Writing Plans

Use after brainstorming is complete and the approach is confirmed. Write a plan before any implementation begins.

## When to use

Any non-trivial task (more than a single-file edit or a clearly reversible fix).

## Structure of a good plan

A plan is a numbered list of **chunks**. Each chunk must be:
- **Small enough to complete and test in one dispatch** — if it would take more than one specialist invocation to verify, split it.
- **Independently testable** — tests for the chunk are defined in the chunk itself, not deferred to "test everything at the end".
- **Scoped to one specialist** — if a chunk needs two specialists, it is two chunks.

## Plan format

```
## Plan: <task name>

### Chunk 1 — <name>
Specialist: <agent name>
Deliverable: <what comes back from the specialist>
Tests: <what QA verifies before this chunk is marked done>

### Chunk 2 — <name>
...
```

## Sequencing rules

- QA writes tests BEFORE the implementation chunk they cover.
- Security review comes AFTER implementation, BEFORE merge.
- Code review comes AFTER implementation, BEFORE security review on significant changes.
- Docs update is the last chunk of any user-facing feature.

## Waiting for confirmation

Present the plan to the user and wait for explicit confirmation before dispatching any chunk.

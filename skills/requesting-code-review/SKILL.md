# Skill: Requesting Code Review

Use to dispatch `code-reviewer` at the right moment and with the right context.

## When to dispatch

- After every non-trivial implementation chunk, before marking it complete.
- Before any PR that touches shared/public APIs, auth flows, or data persistence.
- After `security-reviewer` returns "no findings" — still do a quality pass.

## What to include in the dispatch

1. **Scope**: exact file paths or diff range under review.
2. **Spec summary**: what the code is supposed to do.
3. **Rules file**: `rules/<stack>/base.md` for the language in scope. Include framework rules if applicable.
4. **Context**: any constraints or decisions that are intentional, so the reviewer does not flag them.

## After "Needs changes"

Return the findings to the language agent with **specific, actionable** instructions. Do not forward the review verbatim — distill it into concrete changes. After the fix, request another review of the changed sections only.

## After "Approved"

Mark the chunk complete and proceed. If it is the last chunk before merge, proceed to security review.

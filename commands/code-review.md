---
description: Quality review outside the automatic pipeline — readability, duplication, complexity, rules adherence. Usage — /aegis:code-review <path or diff>
allowed-tools: Task, Read, Bash, Glob
---

Dispatch the **Code Reviewer** specialist (`agents/code-reviewer.md`) to review:

> $ARGUMENTS

## Instructions

1. If `$ARGUMENTS` is empty, determine the scope from git:
   - Run `git diff --name-only HEAD~1` to get recently changed files.
   - If the working tree is clean and no recent commit exists, ask: "What scope should be reviewed? (file path, directory, or paste code)"

2. Detect the language in scope (from file extensions) and find the matching rules file:
   - `.ts`/`.js` → `rules/js-ts/base.md`
   - `.py` → `rules/python/base.md`
   - `.cs` → `rules/csharp/base.md`
   - `.php` → `rules/php/base.md`
   - `.go` → `rules/go/base.md`
   - `.kt` → `rules/kotlin/base.md`
   - `.swift` → `rules/swift/base.md`
   - `.dart` → `rules/dart/base.md`
   - `.java` → `rules/java/base.md`
   - `.rb` → `rules/ruby/base.md`
   - `.cpp`/`.hpp` → `rules/cpp/base.md`
   - `.rs` → `rules/rust/base.md`

3. Dispatch to `code-reviewer` with:
   - The file(s) in scope.
   - The spec or PR description if available (`$ARGUMENTS` or git commit message).
   - The rules file path for the language in scope.

4. Apply two-stage review on return:
   - **Stage 1 — Compliance**: does the code match the spec? Is it complete for its scope?
   - **Stage 2 — Quality**: are the findings accurate? Is the verdict appropriate?

5. Present findings to the user:
   - Compliance check result.
   - Quality findings (file:line, dimension, suggested fix).
   - Verdict: Approved / Approved with minor notes / Needs changes.
   - If "Needs changes": present specific, actionable instructions for the developer.

This is a quality review only. For security findings use `/aegis:security-review`. For test coverage use `/aegis:qa-review`.

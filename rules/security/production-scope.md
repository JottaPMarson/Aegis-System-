# Production Scope — Branch Patterns

This file defines which branches are considered "production" by the aegis security hooks.
Edit this file to match your project's branching conventions. Do not hardcode branch names in hook scripts.

## Default patterns (regex, case-insensitive)

```
^main$
^master$
^production$
^prod$
^release/.+
```

## Environment variable override

If `AEGIS_ENV=production` is set in the current shell, the hooks treat the current context as
production regardless of branch name. Useful for CI/CD pipelines and deploy scripts.

## How hooks use this file

Security hooks load these patterns at runtime (no restart needed) and apply stricter blocking
rules when the current branch matches any pattern here — or when `AEGIS_ENV=production` is set.

## Adding patterns for your project

Add one regex per line inside the code block above. Examples:
- `^hotfix/.+` — hotfix branches that deploy directly
- `^staging$` — staging treated as production-level protection
- `^v[0-9]+\.[0-9]+` — version branches

## Patterns NOT to add here

Feature branches, personal branches, `dev`, `develop`, `test-*` — these are intentionally
outside production scope. Dangerous commands on these branches still trigger the ask flow,
but with a more permissive tone in the message.

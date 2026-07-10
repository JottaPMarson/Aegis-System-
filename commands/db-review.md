---
description: Review schema design, a migration file, index strategy, or cache approach. Usage — /aegis:db-review <path or scope>
allowed-tools: Task, Read, Bash, Glob
---

Dispatch the **Database Engineer** specialist (`agents/database-engineer.md`) to review:

> $ARGUMENTS

## Instructions

1. If `$ARGUMENTS` is empty, scan for pending migrations:
   - Check common migration paths: `migrations/`, `db/migrate/`, `prisma/migrations/`, `flyway/`, `alembic/versions/`.
   - If pending migrations are found, use them as the review scope.
   - Otherwise ask the user: "What should be reviewed? (migration file, schema file, query, or cache strategy)"

2. Determine the technology in scope and provide the relevant rules file to the Database Engineer:
   - PostgreSQL → `rules/database/postgresql.md`
   - DynamoDB → `rules/database/dynamodb.md`
   - Redis cache → `rules/database/redis-cache.md`
   - Other: note that the rules file does not exist yet (gap) and proceed with best practices.

3. Dispatch to `database-engineer` with:
   - The file(s) in scope.
   - The technology and rules file path.
   - Any related ORM/query code found via `Glob`.

4. Apply two-stage review on return:
   - **Stage 1 — Compliance**: schema, indexes, cache strategy, and migration addressed?
   - **Stage 2 — Quality**: are index choices justified? Is the migration reversible risk addressed? Is the cache strategy justified (not added by default)?

5. Present findings to the user:
   - Schema/index plan.
   - Migration summary.
   - Cache strategy (or "no cache needed" with reasoning).
   - N+1 findings if the Database Engineer flagged any.
   - Infra hand-off flag: if provisioning is involved, dispatch `/aegis:infra-review` on the affected resources.

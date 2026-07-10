# PostgreSQL Rules

## Schema design

- Name tables in `snake_case`, plural (`users`, `order_items`). Primary key: `id` (UUID or bigserial — choose consistently across the schema).
- Never store multiple values in a single column (no comma-separated IDs). Use a junction table.
- Add `created_at TIMESTAMPTZ DEFAULT now()` and `updated_at TIMESTAMPTZ` to every entity table.
- Use `NOT NULL` by default. Add `NULL` only when absence is genuinely meaningful in the domain.
- Prefer `TIMESTAMPTZ` over `TIMESTAMP` — always store timezone-aware datetimes.

## Indexes

- Every foreign key column gets an index (`CREATE INDEX ON order_items(order_id)`).
- Partial indexes for common filtered queries: `CREATE INDEX ON users(email) WHERE deleted_at IS NULL`.
- `EXPLAIN ANALYZE` before and after adding an index in production — verify it is used.
- Avoid over-indexing: each index slows down writes. Validate usage with `pg_stat_user_indexes`.

## Queries

- Parameterized queries always — never string interpolation into SQL.
- Avoid `SELECT *` in application code — select only columns the code actually uses.
- Use CTEs (`WITH`) for readability in complex queries; PostgreSQL 12+ inlines them by default (`MATERIALIZED` to force materialization).
- `RETURNING` clause to avoid a second round-trip after `INSERT`/`UPDATE`.

## Migrations

- One migration = one logical change. Never modify a migration that has already been applied in any environment.
- Forward-only migrations (no `down` in production). Rollback by writing a new migration.
- Column removal: deprecate first (stop writing/reading), confirm no rows use the old column, then drop in a separate migration.
- Add columns as nullable first when backfilling is needed, then apply `NOT NULL` constraint after the backfill.

## Performance patterns

- Connection pooling (`pgBouncer` or application-level pool). Never open a connection per request in production.
- `VACUUM ANALYZE` runs automatically (autovacuum) — do not disable it. Monitor bloat with `pgstattuple`.
- `pg_stat_statements` enabled for query performance tracking.
- Avoid transactions that hold locks while waiting for user input.

## Security

- Application connects with a role that has minimal privileges (no superuser, no DDL in production).
- `pg_hba.conf` restricts connections to the application subnet only.
- Passwords not stored as plain text — use `pgcrypto` or handle hashing in the application.

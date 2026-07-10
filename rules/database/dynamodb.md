# DynamoDB Rules

## Design approach — access patterns first

DynamoDB is a key-value and document store. Unlike relational databases, you design the table for the access patterns — not for normalization. Define every access pattern before writing a single `CreateTable` call.

## Table structure

- Single-table design is the default for most applications: one table, multiple entity types, discriminated by the key structure.
- `PK` (partition key) and `SK` (sort key) as generic attribute names, with entity-type prefixes: `PK = USER#<userId>`, `SK = PROFILE#<userId>`.
- Add a `type` attribute on every item for debugging and filtering without key knowledge.
- Avoid multi-table design unless entity types have radically different access patterns and scale requirements.

## Keys and indexes

- Choose partition keys with high cardinality and even distribution. Avoid hot partitions (a single PK receiving a disproportionate share of traffic).
- GSI (Global Secondary Index): one per additional access pattern that requires a different partition key. Maximum 20 per table.
- LSI (Local Secondary Index): only when you need range queries on a different sort key for the same partition key. Must be defined at table creation — cannot be added later.
- Sparse indexes: only items with a particular attribute appear in the index — use for efficient filtered queries.

## Item size and modeling

- Maximum item size: 400 KB. Split large items into related items sharing a prefix.
- Store only what you query. Avoid duplicating data you will never filter or sort on in DynamoDB — use S3 for large blobs.
- Use `TTL` attribute for automatic expiration of transient data (sessions, tokens, cache entries).

## Capacity and billing

- On-demand billing for unpredictable workloads; provisioned for predictable, high-volume, cost-sensitive workloads.
- Monitor `ConsumedCapacityUnits` and `ThrottledRequests` — throttling means you are reading or writing faster than provisioned capacity.
- Avoid full table scans (`Scan`) in production code — they consume capacity proportional to the table size.

## Transactions and consistency

- `TransactWriteItems` for multi-item, multi-table atomic writes (max 100 items per transaction).
- `Strong consistency` (`ConsistentRead: true`) only when you cannot tolerate stale reads — it costs 2× read capacity.
- Eventual consistency is the default and acceptable for most read paths.

## Migrations

- DynamoDB is schemaless — "migrations" are access pattern evolutions. Document every access pattern change.
- Adding a new GSI: test on a copy of the table first (backfill is automatic but eventually consistent).
- Renaming an attribute: add the new attribute, backfill, stop writing the old one, confirm reads are migrated, then remove.

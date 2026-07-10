# Redis — Cache Strategy Rules

## Cache vs. source of truth

Redis is a cache layer — not the source of truth. Data in Redis can be evicted, lost on restart (without persistence configured), or stale. Never use Redis as the only storage for data that cannot be reconstructed from the primary store.

## When to cache — justify every entry

Do not cache by default. Add a cache entry only when:
1. The query is expensive (> 50ms P95) and the result is read far more often than it changes.
2. Rate limiting or token bucket behavior is needed.
3. Session data that needs fast access across services.
4. Computed aggregates that are expensive to recompute on every request.

If in doubt, profile first. Premature caching adds complexity without measurable benefit.

## Key design

- Hierarchical, colon-separated keys: `<service>:<entity>:<id>` → `user-service:user:123`.
- Include version prefix when the cached data format changes: `v2:user:123`.
- Keep keys short — each key is stored in memory. Long keys waste RAM across millions of entries.

## TTL (Time-to-Live)

- Every cache entry must have a TTL — no indefinitely cached data.
- TTL should reflect the acceptable staleness window for the use case, not an arbitrary large number.
- Use jitter (±10–20% of TTL) to prevent cache stampede when many keys expire simultaneously.

## Cache invalidation strategies

- **Cache-aside (lazy loading)**: application reads from cache; on miss, reads from DB, writes to cache. Simple, but reads may be stale until TTL expires.
- **Write-through**: write to DB and cache simultaneously. More consistent, but every write pays the cache update cost.
- **Write-behind (write-back)**: write to cache first, DB asynchronously. High performance, but risk of data loss on cache failure. Use only when loss is acceptable.
- **Event-driven invalidation**: invalidate or update the cache key when an event signals data has changed (message queue or DB trigger). Most consistent, highest complexity.

Choose the simplest strategy that meets the consistency requirement.

## Cache stampede prevention

When a hot key expires, many concurrent requests will miss and hit the DB simultaneously:
- Use `SET NX` (set if not exists) with a short lock TTL to let only one request rebuild the cache.
- Or use probabilistic early expiration: recompute the cache before it actually expires.

## Memory and eviction

- Set `maxmemory` and an appropriate `maxmemory-policy`. For a pure cache: `allkeys-lru` or `allkeys-lfu`.
- Monitor `used_memory` and `evicted_keys`. Sustained eviction means the cache is undersized or key design needs review.
- Do not store large blobs (> 1 MB per key) — they fragment memory and slow serialization.

## Security

- Redis should not be publicly accessible. Bind to localhost or the internal network only.
- Enable `requirepass` or ACLs (Redis 6+) — never run Redis without authentication in any environment.
- Use TLS for connections between the application and Redis in production.

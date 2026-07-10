# Kotlin Base Rules

## Language features — use them

Kotlin's standard library eliminates most Java boilerplate. Use idiomatic Kotlin instead of translating Java patterns:
- Null safety: `?.`, `?:`, `!!` (only when provably non-null), `let`, `run`, `also`, `apply`.
- Data classes over POJOs.
- Sealed classes/interfaces for exhaustive when expressions.
- Extension functions to add behavior without inheritance.

## Null safety

- Never use `!!` without a comment explaining why the value is guaranteed non-null.
- Prefer early return over deeply nested null checks: `val x = value ?: return`.
- Use `lateinit var` only for dependency-injected properties initialized before first use (and only for non-nullable types that truly can't be initialized in the constructor).

## Coroutines

- `suspend` functions over callbacks or `CompletableFuture`.
- Launch coroutines in a structured scope (`viewModelScope`, `lifecycleScope`, a custom `CoroutineScope`). Never `GlobalScope` in production code.
- Use `Dispatchers.IO` for blocking I/O; `Dispatchers.Default` for CPU-bound work; `Dispatchers.Main` for UI updates.
- `withContext` to switch dispatchers — do not launch a new coroutine just to change context.

## Functions and classes

- Prefer top-level functions over utility classes with only static methods.
- Use `object` declarations for true singletons.
- `companion object` only for factory methods and constants; prefer top-level functions for utility logic.
- Avoid deep inheritance hierarchies — prefer composition and interfaces.

## Naming (Kotlin conventions)

- `camelCase` for functions, properties, local variables.
- `PascalCase` for classes, interfaces, objects, enums.
- `SCREAMING_SNAKE_CASE` for compile-time constants (`const val`).

## Collections

- Immutable collections (`listOf`, `mapOf`, `setOf`) by default. Use mutable variants (`mutableListOf`, etc.) only when mutation is genuinely needed.
- Use `Sequence` for lazy evaluation on large or chained collection operations.

## Testing

- JVM/Server: Kotest (descriptive test DSL) or JUnit 5 with kotlin-test assertions.
- Android: JUnit 4 with Robolectric for unit tests; Espresso for UI tests; Hilt testing support for DI.
- Run tests with `./gradlew test` (JVM) or `./gradlew testDebugUnitTest` (Android).

## Adding a framework/platform

When a platform is detected, read `rules/kotlin/frameworks/<platform>.md` if it exists.

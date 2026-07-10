# C# Base Rules

## Language version and nullable

- Use the latest C# version the `<TargetFramework>` supports. Enable nullable reference types: `<Nullable>enable</Nullable>` in the `.csproj`.
- Annotate all parameters and return types for nullability. Never suppress nullable warnings with `!` without a comment explaining why.

## Naming conventions (Microsoft standard)

- `PascalCase`: classes, interfaces, methods, properties, public fields.
- `camelCase`: local variables, method parameters.
- `_camelCase`: private instance fields.
- Interfaces always start with `I` (`IRepository`, `IUserService`).

## Async

- Suffix async methods with `Async` (`GetUserAsync`, `SaveAsync`).
- Prefer `Task`/`Task<T>` over `ValueTask<T>` unless profiling shows allocation pressure.
- Always `await` — never `.Result` or `.Wait()` on a `Task` in async code (deadlock risk).
- Pass `CancellationToken` through the entire async call chain; never ignore it.

## Dependency injection

- Register services in the DI container (built-in `Microsoft.Extensions.DI` or configured container).
- Constructor injection only — property injection is harder to reason about.
- Prefer interfaces over concrete types in constructors (testability and substitutability).

## LINQ and collections

- Use LINQ for query expressions, not for side effects.
- Avoid `ToList()` unless you need a snapshot — prefer `IEnumerable<T>` to defer execution.
- `IReadOnlyList<T>` / `IReadOnlyDictionary<K,V>` for return types — communicate immutability.

## Error handling

- Use exceptions for exceptional conditions, not flow control.
- Prefer typed exceptions over catching `Exception` broadly. Include inner exceptions when re-throwing.
- Use `using` statements (or `await using`) for `IDisposable`/`IAsyncDisposable`.

## Records and immutability

- Prefer `record` types for data carriers (DTOs, value objects). Use `init`-only properties.
- Avoid mutable state in domain models — return new instances instead of mutating.

## Testing

- xUnit for unit and integration tests. Prefer `[Fact]` for simple tests and `[Theory]` + `[InlineData]` for parameterized cases.
- Use `Moq` or `NSubstitute` for mocking interfaces — not for mocking concrete types.
- Run `dotnet format --verify-no-changes` in CI to enforce style.

## Adding a framework

When a framework is detected, read `rules/csharp/frameworks/<framework>.md`. Create that file when a new framework is added.

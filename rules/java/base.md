# Java Base Rules

## Java version

- Target Java 17 LTS minimum. Java 21 LTS (virtual threads, pattern matching) is preferred for new projects.
- Use `--enable-preview` only if the project explicitly does so — it means you're on cutting-edge features that may change.

## Naming (Oracle conventions)

- `PascalCase`: classes, interfaces, enums, annotations, records.
- `camelCase`: methods, variables, parameters.
- `SCREAMING_SNAKE_CASE`: constants (`static final`).
- Package names: all lowercase, reverse domain notation (`com.company.project.module`).

## Modern Java — use it

Java 17+ features that reduce boilerplate:
- Records for immutable data carriers: `record User(String name, String email) {}`.
- Sealed classes for restricted hierarchies.
- `var` for local type inference where the type is obvious from the right-hand side.
- Text blocks for multi-line strings.
- Pattern matching for `instanceof` checks.
- Switch expressions (not statements) with arrow syntax.

## Optionals

- `Optional<T>` for return types that may be absent — never return `null` from a public method that could legitimately have no result.
- Do not use `Optional` as a parameter type or field type — it is a return-value container only.
- Chain `.map()` / `.flatMap()` / `.orElseThrow()` instead of `isPresent()` + `get()`.

## Collections

- `List.of()`, `Set.of()`, `Map.of()` for immutable collections.
- `Stream` API for transformations — avoid imperative loops for collection processing.
- Never return mutable `ArrayList` from a public method when the caller should not modify it — return `List.copyOf()` or `Collections.unmodifiableList()`.

## Concurrency

- Prefer `java.util.concurrent` abstractions over `synchronized`. Use `ExecutorService`, `CompletableFuture`, or (Java 21+) virtual threads.
- Java 21+: `Thread.ofVirtual().start(task)` for I/O-bound concurrency.

## Error handling

- Checked exceptions for recoverable failures that callers must handle. Unchecked (`RuntimeException`) for programming errors and non-recoverable states.
- Never catch `Exception` or `Throwable` broadly without logging and re-throwing.
- Use `try-with-resources` for all `AutoCloseable` resources.

## Testing

- JUnit 5 with AssertJ. `@ExtendWith(MockitoExtension.class)` for unit tests with mocks.
- Spring Boot: prefer `@WebMvcTest` / `@DataJpaTest` slice tests over full `@SpringBootTest` context for speed.
- Run: `mvn test` (Maven) or `./gradlew test` (Gradle).

## Adding a framework

When a framework is detected, read `rules/java/frameworks/<framework>.md` if it exists.

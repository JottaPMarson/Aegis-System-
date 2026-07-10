# Swift Base Rules

## Language version

- Swift 5.9+ unless project specifies otherwise. Macros are available from 5.9; structured concurrency from 5.5.
- Strict concurrency checking (`-strict-concurrency=complete`) as a goal — enable it in new code and resolve violations before enabling project-wide.

## Naming (Swift API Design Guidelines)

- `camelCase` for everything except types and protocols, which use `PascalCase`.
- Names should read as prose at the call site: `list.insert(element, at: index)`, not `list.insertElement(element, atIndex: index)`.
- Avoid abbreviations except for very common ones (`URL`, `ID`, `HTTP`).
- Boolean properties and functions use `is`, `has`, `can`, `should` prefixes.

## Optionals

- Unwrap safely with `if let`, `guard let`, or `??`. Force-unwrap (`!`) only when the value is guaranteed (e.g., outlets after `viewDidLoad`, or documented API contracts) — add a comment.
- Avoid optional chaining chains longer than two levels — introduce an intermediate `guard let`.

## Value types

- Prefer `struct` over `class` for data models. Use `class` when identity matters (reference semantics) or when interoperating with Obj-C APIs.
- Enums with associated values for sum types — do not use `Optional` as a workaround for a missing type.

## Concurrency (async/await)

- `async`/`await` over completion handlers for new code.
- Mark types as `Sendable` (or `@unchecked Sendable` with a comment) when crossing actor boundaries.
- Use `actor` for shared mutable state — do not use locks or semaphores in new Swift code.
- `@MainActor` for any type or function that must run on the main thread (UI updates).

## Error handling

- Throwing functions over returning `Optional` when failure has a meaningful cause.
- Define typed enums conforming to `Error` for domain errors.
- Use `defer` for cleanup that must happen regardless of success or failure.

## Testing

- XCTest: `XCTestCase` subclasses with `test` prefix methods.
- Async tests: `func testSomething() async throws`.
- Swift Package Manager projects: `swift test`. Xcode projects: `xcodebuild test -scheme <scheme>`.

## Adding a framework

When a UI framework is detected, read `rules/swift/frameworks/<framework>.md` if it exists.

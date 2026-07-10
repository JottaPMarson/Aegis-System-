# Dart Base Rules

## Language version and null safety

- Dart 3.0+ (null safety is mandatory). Dart 3.0 also introduces records, patterns, and sealed classes — use them where they simplify code.
- Set the minimum SDK constraint in `pubspec.yaml`: `sdk: ">=3.0.0 <4.0.0"` (adjust upper bound as needed).

## Naming (Dart style guide)

- `UpperCamelCase`: classes, enums, typedefs, type parameters.
- `lowerCamelCase`: variables, parameters, named parameters, functions, methods.
- `lowercase_with_underscores`: libraries, packages, directories, source files.
- `SCREAMING_SNAKE_CASE`: constants only if the project already uses this convention.

## Null safety

- Non-nullable by default. Use `?` only when a value is genuinely optional.
- Avoid `!` (null-assertion operator) except when you have proof the value is non-null — add a comment.
- Use `late` for non-nullable fields initialized after construction; avoid it for fields initialized lazily without guaranteed access ordering.

## Functions and classes

- Prefer immutable data: `final` for fields and local variables that don't change.
- Named constructors for multiple construction patterns (`User.fromJson`, `User.empty`).
- Extension methods to add functionality without subclassing.
- Avoid deep inheritance — prefer mixins for shared behavior.

## Async

- `async`/`await` with `Future<T>`. Use `Stream<T>` for sequences of async events.
- Never `then()` chains when `await` is available.
- Cancel subscriptions and close StreamControllers in `dispose()` (Flutter) or on cleanup.

## Collections

- Use collection literals (`[]`, `{}`, `<Type>[]`) with type inference.
- Spread operator (`...`) and collection-if/for for building collections declaratively.
- `const` collections where values are compile-time constants.

## Error handling

- Typed exceptions extending `Exception` or `Error` for domain failures.
- `try`/`catch`/`finally` — do not swallow exceptions without logging.

## Testing

- `package:test` for pure Dart; `flutter_test` for Flutter widgets.
- `dart test` for pure packages; `flutter test` for Flutter projects.
- `dart analyze` must report zero issues; `dart format --set-exit-if-changed .` must pass.

## Adding a framework

When Flutter is detected, read `rules/dart/frameworks/flutter.md` if it exists.

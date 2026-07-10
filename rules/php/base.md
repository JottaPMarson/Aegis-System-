# PHP Base Rules

## PHP version

- Target PHP 8.1+ unless the project specifies otherwise. Enums, fibers, `never` return type, and intersection types are available from 8.1.
- Use strict types: `declare(strict_types=1);` at the top of every file.

## Naming (PSR-1 / PSR-12)

- `PascalCase`: classes, interfaces, traits, enums.
- `camelCase`: methods, non-constant properties.
- `snake_case`: local variables, function parameters.
- `SCREAMING_SNAKE_CASE`: class constants.
- One class per file. File name matches class name exactly.

## Autoloading and namespaces

- PSR-4 autoloading via Composer. Namespace mirrors the directory path relative to `src/`.
- Never use `require`/`include` manually for project classes — trust Composer's autoloader.

## Types and nullability

- Declare parameter types, return types, and property types. No untyped function signatures.
- Use union types (`string|int`) and nullable types (`?string`) instead of mixed when possible.
- Avoid `mixed` unless genuinely necessary — it defeats static analysis.

## Error handling

- Throw typed exceptions extending `\RuntimeException` (for recoverable errors) or `\LogicException` (for programming errors).
- Never return `false`/`null` to signal failure from a function that returns a meaningful type — throw.
- Use `finally` for cleanup (closing resources) regardless of whether an exception occurred.

## Arrays and collections

- Type-annotate arrays in docblocks: `/** @param array<int, User> $users */`.
- For structured data, prefer typed DTO classes or enums over associative arrays.

## Code style

- PSR-12 formatting. Use `PHP CS Fixer` with PSR-12 ruleset.
- Run `phpstan analyse --level=8` (or max). Fix all issues before committing.

## Testing

- PHPUnit. Test classes in `tests/` mirroring `src/` structure.
- No database mocks in integration tests — use an in-memory SQLite or a test container.

## Adding a framework

When a framework is detected, read `rules/php/frameworks/<framework>.md`. Create that file when a new framework is added.

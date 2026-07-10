# Python Base Rules

## Python version and typing

- Target Python 3.10+ unless the project specifies otherwise. Use `match`/`case`, `X | Y` union syntax, and `TypeAlias` freely on 3.10+.
- Add type hints to all public functions and methods. Use `from __future__ import annotations` for forward references.
- Enable strict mode in `mypy` or `pyright`. Fix type errors; do not add `# type: ignore` without a comment explaining why.

## Package management

- Use the tool already in the project (`pip`+`requirements.txt`, `poetry`/`pyproject.toml`, or `pipenv`). Do not switch.
- Pin versions in production requirements. Use version ranges (`>=`, `~=`) in library `pyproject.toml` dependencies.

## Code style

- Follow PEP 8. Use `ruff format` (or `black`) for formatting — do not apply manual formatting that a tool would revert.
- Maximum line length: 88 characters (Black default). Never exceed 120.
- `ruff check` for linting. Treat all `E` and `F` codes as errors.

## Naming

- `snake_case` for variables, functions, modules. `PascalCase` for classes. `SCREAMING_SNAKE_CASE` for module-level constants.
- Prefix private members with a single underscore (`_internal`). Double underscore only for name mangling (rare).

## Functions and classes

- Functions do one thing. If you can't name it without "and", split it.
- Prefer dataclasses or Pydantic models over plain dicts for structured data — dicts are hard to refactor and type-check.
- Use `@property` sparingly — if it does real work, make it a method so callers know to expect side effects or latency.

## Error handling

- Raise specific exceptions, not bare `Exception`. Create custom exception classes for domain errors.
- Never `except Exception: pass`. Either handle, re-raise, or log and re-raise.
- Use context managers (`with`) for resource management — files, DB connections, locks.

## Async (when used)

- `asyncio` with `async`/`await`. Do not mix sync and async in the same call stack without explicit bridging (`asyncio.run`, `run_in_executor`).
- Avoid blocking I/O in async functions — use async-aware libraries (`httpx`, `asyncpg`, `aiofiles`).

## Testing

- `pytest`. Use `pytest-asyncio` for async tests. Keep test fixtures in `conftest.py`.
- No `unittest.TestCase` in new code — use plain functions with `pytest`.
- Integration tests that need a database: use a real test database (containerized), not mocks.

## Adding a framework

When a framework is detected, read `rules/python/frameworks/<framework>.md`. Create that file when a new framework is added to the project.

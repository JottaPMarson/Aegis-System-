# C++ Base Rules

## Standard

- C++17 minimum. C++20 (concepts, ranges, coroutines, `std::format`) is preferred for new projects.
- Check `CMAKE_CXX_STANDARD` in `CMakeLists.txt` or compiler flags — never assume the standard.

## RAII — always

- Resources (memory, file handles, sockets, locks) are managed by destructors, not by manual `delete`/`free`/`close`.
- `std::unique_ptr<T>` for exclusive ownership; `std::shared_ptr<T>` only when shared ownership is genuinely required.
- Never raw `new`/`delete` in application code. Use `std::make_unique`/`std::make_shared`.
- `std::lock_guard` / `std::unique_lock` for mutexes — never unlock manually.

## Naming (Google C++ Style as baseline — adjust to project's existing convention)

- `PascalCase`: classes, structs, type aliases, concepts.
- `snake_case`: functions, methods, local variables.
- `kCamelCase` or `SCREAMING_SNAKE_CASE`: constants (match existing style in the project).
- Trailing `_` for private member variables: `name_`, `count_`.

## Memory and safety

- Avoid raw pointers for ownership. Raw pointers are acceptable for non-owning references when lifetime is clear and documented.
- `std::span<T>` (C++20) over raw pointer + size pairs.
- No `reinterpret_cast` without a comment explaining the invariant being relied on.
- Use `[[nodiscard]]` on functions whose return values must not be ignored.

## Error handling

- Use exceptions for errors that callers cannot reasonably anticipate or handle locally (constructor failures, I/O errors).
- Return `std::expected<T, E>` (C++23) or `std::optional<T>` for functions that can fail without throwing.
- Never throw from destructors.

## Modern C++ idioms

- Range-based `for` loops over index-based loops.
- Structured bindings: `auto [key, value] = pair;`.
- `if`/`switch` with initializer: `if (auto it = map.find(key); it != map.end())`.
- Lambda captures: capture by value `[=]` only what you need; prefer explicit captures.
- `constexpr` for compile-time constants and functions.

## Build and tooling

- CMake as the build system. Define targets with `add_library`/`add_executable`; link with `target_link_libraries`.
- Enable warnings as errors: `-Wall -Wextra -Wpedantic -Werror` (GCC/Clang) or `/W4 /WX` (MSVC).
- `clang-format` for formatting (`.clang-format` file at project root).
- `clang-tidy` or `cppcheck` for static analysis.

## Testing

- Google Test or Catch2. Tests in a `tests/` subdirectory, registered in `CMakeLists.txt` with `enable_testing()` and `add_test()`.
- Run: `ctest --test-dir build/ --output-on-failure`.

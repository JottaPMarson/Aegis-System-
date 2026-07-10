# Rust Base Rules

## Edition and toolchain

- Use the `edition` from `Cargo.toml` (2021 is current baseline). Check `rust-toolchain.toml` for a pinned version.
- Stable Rust only unless the project explicitly uses nightly features — if so, document why.

## Ownership and borrowing — respect the model

- Immutable references (`&T`) by default. Mutable references (`&mut T`) only when mutation is needed.
- Minimize the lifetime of borrows — keep them short so the borrow checker is happy and the code is easier to reason about.
- `clone()` is not a solution to a borrow error — understand the ownership issue first.
- `Arc<T>` for shared ownership across threads; `Rc<T>` for single-threaded shared ownership. Prefer `Arc<Mutex<T>>` pattern for shared mutable state — but design to minimize it.

## Error handling

- `Result<T, E>` for recoverable errors. Use `?` to propagate — never `.unwrap()` or `.expect()` in library code.
- `.unwrap()` is acceptable in tests, examples, and one-time scripts. In application code, replace with `?` or `.expect("clear message explaining the invariant")`.
- Custom error types: implement `std::error::Error`. Use `thiserror` crate for deriving; `anyhow` for application-level error aggregation.

## Naming (Rust conventions)

- `snake_case`: functions, methods, modules, variables, crate names.
- `PascalCase`: types, traits, enums, variants.
- `SCREAMING_SNAKE_CASE`: constants and statics.
- Boolean methods: `is_`, `has_`, `can_` prefix.

## Traits and generics

- Prefer trait bounds (`fn foo<T: Display>(x: T)`) for flexibility; use `impl Trait` in function signatures for simpler cases.
- `dyn Trait` (dynamic dispatch) only when runtime polymorphism is required — it carries a vtable cost.
- Derive standard traits automatically: `#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]` — only what is actually needed.

## Iterators

- Prefer iterator chains (`map`, `filter`, `fold`, `collect`) over explicit loops. They compose well and are zero-cost abstractions.
- Use `into_iter()` to consume, `iter()` for borrowed iteration, `iter_mut()` for mutable borrowed iteration.

## Unsafe

- `unsafe` blocks must have a comment explaining the invariant that makes the unsafe operation sound.
- Minimize the scope of `unsafe` — isolate it in a well-documented wrapper.
- Code review of any `unsafe` block is mandatory before merging.

## Async (when used)

- `async`/`await` with `tokio` (most common runtime). Do not block the async executor — use `tokio::task::spawn_blocking` for blocking I/O.
- `Send + Sync` bounds on futures when crossing thread boundaries.

## Tooling

- `cargo fmt` — always before committing.
- `cargo clippy -- -D warnings` — fix all Clippy lints.
- `cargo test` — all tests must pass.
- `cargo audit` — scan for known vulnerabilities in dependencies (run before release).

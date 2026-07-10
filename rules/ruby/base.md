# Ruby Base Rules

## Ruby version

- Use the version specified in `.ruby-version`, `Gemfile ruby` directive, or `.tool-versions`.
- Ruby 3.1+ is recommended — Ractors, pattern matching, and `endless method` definitions are stable.

## Style (RuboCop + Ruby Style Guide)

- Run `bundle exec rubocop` with the project's `.rubocop.yml`. Never commit with `rubocop` errors.
- Default offense level: treat `C` (convention) violations as failures in CI.
- Line length: 120 characters maximum.

## Naming

- `snake_case`: methods, variables, files, directories.
- `PascalCase`: classes, modules.
- `SCREAMING_SNAKE_CASE`: constants.
- Methods that return boolean end with `?` (`valid?`, `empty?`).
- Methods with side effects that change state end with `!` (`save!`, `update!`).

## Ruby idioms

- Implicit return (last expression) — only use `return` for early exit.
- Prefer `||=` for memoization (but be careful with falsy values — use `defined?` pattern instead when `false`/`nil` are valid values).
- Symbols over strings for hash keys.
- `Struct` or `Data` (Ruby 3.2+) for simple value objects over plain `Hash`.
- `Enumerable` methods (`map`, `select`, `reduce`, `flat_map`) over imperative loops.

## Blocks and procs

- Use `do..end` for multi-line blocks; `{..}` for single-line blocks.
- Prefer `yield` over storing a proc when a block is expected once.

## Error handling

- Rescue specific exception classes — never `rescue StandardError` or bare `rescue` without cause.
- Use `ensure` for cleanup (always runs regardless of exception).
- Custom exception classes inherit from `StandardError`, not `RuntimeError`.

## Testing

- RSpec: `describe` / `context` / `it` blocks. Behavior-driven language: `it "returns X when Y"`.
- Use `let` and `let!` for setup; avoid `before(:each)` for data that can be lazy.
- Integration/system specs: Capybara for browser-level tests.
- Rails: run `bin/rails test` (minitest) or `bundle exec rspec` (RSpec), depending on what the project uses.

## Adding a framework

When a framework is detected, read `rules/ruby/frameworks/<framework>.md` if it exists.

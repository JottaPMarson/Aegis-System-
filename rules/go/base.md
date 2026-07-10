# Go Base Rules

## Idioms first

Go has strong community conventions enforced by tooling. Follow them — do not bring patterns from other languages.

## Formatting and linting

- `gofmt` / `goimports` on every file before committing. CI must fail on unformatted code.
- Run `go vet ./...` — treat all findings as errors.
- Use `golangci-lint` with at minimum: `errcheck`, `govet`, `staticcheck`, `gosimple`, `unused`.

## Error handling

- Errors are values — handle them explicitly. Never discard an error with `_` unless you have a documented reason.
- Wrap errors with context: `fmt.Errorf("loading config: %w", err)`. Use `errors.Is` / `errors.As` to inspect wrapped errors.
- Do not use `panic` for expected failures. `panic` is for programming errors (invariant violations), not runtime conditions.

## Naming

- Short, descriptive names in small scopes. Long, descriptive names for exported identifiers.
- Exported identifiers have doc comments (`// FunctionName does X.`).
- Avoid stuttering: `http.Server`, not `http.HTTPServer`.
- Interfaces: name with `-er` suffix for single-method interfaces (`Reader`, `Closer`, `Stringer`).

## Concurrency

- Prefer channels for coordination; mutexes for shared state. Do not mix without clear reason.
- Every goroutine needs a defined lifecycle — know who creates it, who waits for it, and how it stops.
- Use `context.Context` as the first parameter of any function that can be cancelled or timed out. Never store contexts in structs.

## Packages

- Small, focused packages. Avoid `utils`, `helpers`, `common` — they become dumping grounds.
- Unexported identifiers are the default — export only what needs to be exported.
- Circular imports are a compile error — they reveal a design problem, not a tooling limitation.

## Testing

- `go test ./...` with `-race` flag in CI.
- Table-driven tests for functions with many input variants.
- Use `testify/assert` and `testify/require` if already in `go.mod`; otherwise use the standard `testing` package.
- Integration tests that hit real services: use build tags (`//go:build integration`) to exclude from unit test runs.

## Adding a framework

When a web framework is detected, read `rules/go/frameworks/<framework>.md` if it exists. Create that file when a new framework is confirmed in the project.

# JS/TS Base Rules

JavaScript and TypeScript share these rules. TypeScript-specific additions are marked **[TS]**.

## Package management

- Use the package manager already in the project (`npm`, `yarn`, or `pnpm` — check for lockfile). Never switch managers mid-project.
- Do not add a dependency for something the standard library or existing deps already solve.

## Module system

- Prefer ES modules (`import`/`export`) over CommonJS (`require`/`module.exports`). If the project uses CJS, stay consistent.
- Named exports over default exports — easier to refactor and grep.

## Async

- `async`/`await` over raw promises. No `.then().catch()` chains unless returning a promise from a non-async function.
- Never `await` inside a loop without a good reason — use `Promise.all()` for parallel work.
- Always handle rejections: `await` in a `try/catch` or attach `.catch()` to fire-and-forget calls.

## TypeScript [TS]

- Enable `strict: true` in `tsconfig.json`. Never disable it to silence a type error — fix the type.
- Prefer `interface` for object shapes that describe a contract, `type` for unions, intersections, and mapped types.
- Avoid `any`. Use `unknown` when the type is genuinely unknown and narrow it before use.
- Use non-null assertion (`!`) only when you have proof the value is defined (add a comment explaining why).

## Functions and variables

- `const` by default; `let` when mutation is needed; never `var`.
- Arrow functions for callbacks and short expressions; named function declarations for top-level functions (easier to trace in stack traces).
- Destructure parameters when a function takes more than two arguments: `function fn({ a, b, c }: Options)`.

## Error handling

- Throw `Error` objects, not strings.
- In Express/NestJS-style middleware, always forward errors to the next error handler — do not swallow them.
- Do not return `null`/`undefined` from a function that can legitimately fail — throw or return a `Result` type.

## Code structure

- One class or one major export per file.
- Avoid files longer than ~300 lines — split by responsibility.
- No barrel re-exports (`index.ts` that re-exports everything) unless the project already uses them.

## Testing (reference framework in rules/js-ts/frameworks/ for project-specific config)

- Test files co-located with the source or in a mirrored `__tests__/` directory.
- Use `describe` / `it` blocks. Name the test after the behavior: `it("should reject when token is expired")`.
- Mock only external I/O (HTTP calls, DB calls). Do not mock your own modules.

## Linting and formatting

- ESLint for lint; Prettier or Biome for format. Do not mix formatters.
- Run `--fix` before committing — do not leave auto-fixable issues in PRs.

## Adding a framework

When a framework is detected, read `rules/js-ts/frameworks/<framework>.md` for additional conventions. Create that file when a new framework is added to the project.

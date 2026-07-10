# Stack Detection — Marker File → Language Agent

The orchestrator reads these marker files (via `Glob`) to determine which language agent to dispatch for implementation tasks. Run the detection before every implementation delegation, at the project root or relevant monorepo subdirectory.

| Marker file | Agent |
|---|---|
| `package.json` (with or without `tsconfig.json`) | `lang-js-ts` |
| `requirements.txt` / `pyproject.toml` / `Pipfile` / `manage.py` | `lang-python` |
| `*.csproj` / `*.sln` | `lang-csharp` |
| `CMakeLists.txt` / `*.vcxproj` / `Makefile` (with `.cpp`/`.hpp` sources) | `lang-cpp` |
| `composer.json` | `lang-php` |
| `go.mod` | `lang-go` |
| `build.gradle.kts` / `build.gradle` (Kotlin plugin) / predominant `*.kt` files | `lang-kotlin` |
| `Package.swift` / `*.xcodeproj` / `*.xcworkspace` | `lang-swift` |
| `pom.xml` / `build.gradle` (Java, no Kotlin plugin) | `lang-java` |
| `Cargo.toml` | `lang-rust` |
| `Gemfile` | `lang-ruby` |
| `pubspec.yaml` | `lang-dart` |
| `Dockerfile` / `docker-compose.yml` / `*.tf` / `k8s/*.yaml` | `infra-engineer` (runs in parallel with language agent — does not replace it) |

## Monorepos

Check each subdirectory independently. Example: `apps/mobile/pubspec.yaml` → `lang-dart`, `apps/api/go.mod` → `lang-go` — both specialists are called for the same feature, each handling their scope.

## No Marker Found

Execute the implementation directly as orchestrator. Log the gap: add a note that a new `agents/lang-<x>.md` + `rules/<x>/` is needed. This is the signal to expand the specialist team.

## Adding a New Language

1. Add a row to this table (the marker file and the new agent name).
2. Create `agents/lang-<x>.md` following the same front-matter pattern as existing language agents.
3. Create `rules/<x>/base.md` with language conventions.
4. Create `rules/<x>/frameworks/` when specific frameworks are confirmed.

No other files need to change.

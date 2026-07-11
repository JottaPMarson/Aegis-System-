# Docker Conventions

Rules for Dockerfiles and docker-compose files. The `infra-engineer` agent applies these to every Docker output.

---

## Dockerfile

### Base image
- Use distroless, Alpine, or slim variants (e.g., `python:3.12-slim`, `node:20-alpine`). Never bare `ubuntu` or `debian`.
- Pin the exact digest for production images: `FROM python:3.12-slim@sha256:<digest>`. Tag alone (`python:3.12-slim`) can change without warning.
- Never use `latest` in production Dockerfiles.

### Multi-stage builds
- Always use multi-stage for compiled languages (Go, Rust, Java, C++, C#) and for any image that installs build tools.
- The final stage contains ONLY the runtime artifact + runtime dependencies. Build tools, compilers, and test frameworks must not appear in the final layer.
- Name stages explicitly (`FROM base AS builder`, `FROM runtime AS final`).

### Layer optimization
- Combine related `RUN` commands with `&&` to minimize layers.
- Copy dependency manifests and install before copying source code — this preserves the cache when only source changes.
  ```dockerfile
  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt
  COPY src/ src/
  ```
- Order: FROM → ENV → install deps → copy source → build → entrypoint.

### Security
- Never run as root. Add a non-root user in the final stage:
  ```dockerfile
  RUN addgroup --system app && adduser --system --ingroup app app
  USER app
  ```
- Do not copy `.env`, `*.pem`, `*.key`, or any secret file into the image.
- Do not `RUN` commands that download and execute scripts from the internet (`curl | bash`, `wget | sh`).
- Use `--no-cache` for package managers to avoid stale layer caches: `apk add --no-cache`, `apt-get install -y --no-install-recommends`.
- Always run `apt-get clean && rm -rf /var/lib/apt/lists/*` after apt installs to remove package lists.

### HEALTHCHECK
- Every service container must declare a `HEALTHCHECK`. Orchestrators (Docker Swarm, ECS) use it for restart decisions.
  ```dockerfile
  HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
  ```

### EXPOSE and ENTRYPOINT
- `EXPOSE` the port the service listens on (documentation only — does not publish the port).
- Prefer `ENTRYPOINT` + `CMD` over bare `CMD` for the main process:
  ```dockerfile
  ENTRYPOINT ["python", "-m", "uvicorn"]
  CMD ["main:app", "--host", "0.0.0.0", "--port", "8080"]
  ```
- Use the exec form (`["cmd", "arg"]`), not shell form (`cmd arg`), so the process receives signals correctly.

---

## docker-compose

### Version and structure
- Use `compose.yaml` (preferred) or `docker-compose.yml`. Avoid the deprecated `version:` key (Compose v2+ ignores it).
- One service per logical role. Do not put multiple apps in a single container.

### Networking
- Define explicit named networks. Do not rely on the default bridge network for production-like setups.
- Services that do not need to talk to each other should be on separate networks.
- Do not bind services to `0.0.0.0` unless they are intended to be externally reachable.

### Secrets and environment
- Never hardcode secrets in `docker-compose.yml` or `.env` files checked into version control.
- Use Docker secrets (`secrets:` key) or reference environment variables that are injected by CI:
  ```yaml
  environment:
    - DATABASE_URL=${DATABASE_URL}
  ```
- Add `.env` to `.gitignore`. Commit `.env.example` with placeholder values only.

### Volumes
- Use named volumes for persistent data:
  ```yaml
  volumes:
    postgres_data:
  ```
- Do not bind-mount the entire project root into a service in production-like compose files.

### Dependency ordering
- Use `depends_on` with `condition: service_healthy` (not just `service_started`) when a service requires another to be ready:
  ```yaml
  depends_on:
    postgres:
      condition: service_healthy
  ```
- This requires `healthcheck:` defined on the dependency service.

---

## Image scanning
- Run `docker scout cves <image>` or `trivy image <image>` before pushing to a registry.
- Block on CRITICAL CVEs. Review HIGH CVEs before merging. Do not ship unreviewed CRITICAL vulnerabilities.

# OWASP Top 10 — 2025

Source: https://owasp.org/Top10/2025/  
Review this file periodically — the OWASP may publish updates or errata after the initial 2025 release.

---

## A01 — Broken Access Control

**What changed in 2025**: SSRF (Server-Side Request Forgery) was absorbed into this category. Previously a standalone category (A10:2021-SSRF), it is now treated as one of the access control failure modes.

**What to check**:
- Authorization enforced on every endpoint — not just at the controller level.
- Vertical privilege escalation: user accessing admin-only functions.
- Horizontal privilege escalation: user accessing another user's data by manipulating IDs.
- SSRF: server making HTTP requests to URLs supplied or influenced by the user — validate and restrict outbound destinations.
- CORS misconfiguration: wildcards allowing untrusted origins.
- JWT/session tokens accepted after logout or revocation.

---

## A02 — Security Misconfiguration

**What to check**:
- Default credentials not changed.
- Unnecessary features enabled (admin panels, debug endpoints, verbose error messages in production).
- Missing security headers (`Content-Security-Policy`, `X-Frame-Options`, `Strict-Transport-Security`, `X-Content-Type-Options`).
- Cloud storage buckets not private by default.
- Stack traces and internal paths exposed in error responses.
- Unused ports or services open.

---

## A03 — Software Supply Chain Failures

**What changed in 2025**: Expanded significantly from the 2021 "Vulnerable and Outdated Components". Now covers the entire software supply chain: build systems, CI/CD pipelines, dependency registries, distribution infrastructure, and developer tooling.

**What to check**:
- Outdated dependencies with known CVEs — run `npm audit`, `pip audit`, `cargo audit`, `bundle audit`, etc.
- Pinned dependency versions (lock files committed and up to date).
- Dependency confusion attacks: internal package names resolvable from public registries.
- Build pipeline integrity: `git` actions and CI scripts from untrusted sources.
- Docker base images: unpinned tags, images from unofficial registries, images not scanned.
- `package.json` scripts running arbitrary code during install (`postinstall`, `prepare`).

---

## A04 — Cryptographic Failures

**What to check**:
- Data transmitted in cleartext (HTTP instead of HTTPS, unencrypted database connections).
- Weak or deprecated algorithms: MD5, SHA-1, DES, RC4. Use AES-GCM, ChaCha20-Poly1305, SHA-256+.
- Hardcoded keys, secrets, or passwords in source code or config files.
- Weak key sizes: RSA < 2048 bits, EC < 256 bits.
- IV reuse in symmetric encryption.
- Passwords stored without proper hashing (must use bcrypt, Argon2id, or scrypt — not SHA-256 alone).
- TLS < 1.2 accepted.

---

## A05 — Injection

**What to check**:
- SQL injection: user input concatenated into queries. Use parameterized queries or ORMs that prevent string interpolation into SQL.
- Command injection: user input passed to shell (`exec`, `system`, `os.popen`). Avoid shell=True / child_process.exec with user input.
- LDAP injection, XPath injection, NoSQL injection (MongoDB `$where`, Elasticsearch `_search`).
- Template injection: user-controlled template strings rendered server-side.
- Log injection: user input written to logs without sanitization (enables log forging).

---

## A06 — Insecure Design

**What to check**:
- Missing rate limiting on authentication endpoints (brute-force enablement).
- Business logic flaws: negative quantities, price manipulation, skipping mandatory steps in a flow.
- No account lockout or CAPTCHA after repeated failed attempts.
- Sensitive operations without re-authentication (password change, fund transfer).
- Threat modeling not performed for new features touching sensitive data.

---

## A07 — Authentication Failures

**What to check**:
- Weak password policies (no minimum length, no complexity).
- No MFA for privileged accounts or sensitive operations.
- Session IDs not regenerated after login (session fixation).
- Session tokens exposed in URLs.
- "Remember me" tokens not expiring or not revocable.
- Credential stuffing not mitigated (no rate limiting, no breach detection).

---

## A08 — Software and Data Integrity Failures

**What to check**:
- CI/CD pipeline using third-party actions or scripts without pinning to a specific commit SHA.
- Deserialization of untrusted data without validation (Java `ObjectInputStream`, Python `pickle`, PHP `unserialize`).
- Auto-update mechanisms downloading and executing unsigned code.
- CDN-hosted libraries included without Subresource Integrity (SRI) hashes.

---

## A09 — Security Logging and Alerting Failures

**What to check**:
- Authentication failures not logged.
- Logs not including enough context to reconstruct an incident (timestamp, user ID, IP, action, outcome).
- Logs containing sensitive data (passwords, full credit card numbers, PII beyond what is needed).
- No alerting on repeated failures, privilege escalation, or unexpected data access patterns.
- Log files accessible to unauthorized users.
- Log data not retained long enough for forensic investigation.

---

## A10 — Mishandling of Exceptional Conditions *(new in 2025)*

**What changed**: New category in 2025. Covers errors, logic failures, and fail-open scenarios that the 2021 Top 10 did not address explicitly.

**What to check**:
- Exceptions swallowed silently (`catch(e) {}` or `rescue => e; nil`): the code continues in an undefined state.
- Fail-open authorization: if the permission check throws, access is granted instead of denied.
- Null/None/undefined values reaching code that does not handle them, causing crashes or unexpected behavior.
- Partial transaction failures: some operations succeed, others fail, leaving the system in an inconsistent state.
- Unhandled promise rejections (JavaScript) or unhandled `Result::Err` (Rust) propagated silently.
- Third-party API failures not handled gracefully (cascading failures, data corruption).

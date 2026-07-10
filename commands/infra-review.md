---
description: Review a Dockerfile, Kubernetes manifest, Terraform/CloudFormation config, or CI/CD pipeline. Usage — /aegis:infra-review <path or scope>
allowed-tools: Task, Read, Bash, Glob
---

Dispatch the **Infra Engineer** specialist (`agents/infra-engineer.md`) to review:

> $ARGUMENTS

## Instructions

1. If `$ARGUMENTS` is empty, scan for infra files:
   - `Glob` for: `Dockerfile*`, `docker-compose*.yml`, `*.tf`, `k8s/**/*.yaml`, `.github/workflows/*.yml`, `.gitlab-ci.yml`.
   - If found, use them as the review scope.
   - Otherwise ask: "What should be reviewed? (Dockerfile, k8s manifest, Terraform, CI pipeline)"

2. Dispatch to `infra-engineer` with:
   - The file(s) in scope.
   - The technology (Docker, Kubernetes, Terraform, CI/CD — infer from file extension and content).
   - Any security-relevant context: does this touch IAM, networking, or secrets?

3. Apply two-stage review on return:
   - **Stage 1 — Compliance**: all in-scope files reviewed? Security baseline checklist present?
   - **Stage 2 — Quality**: is the security baseline met? Are there least-privilege or secrets-in-code issues?

4. Present findings to the user:
   - Files reviewed.
   - Security baseline compliance (least privilege, secrets externalized, minimal image, network isolation).
   - If the Infra Engineer flagged a security review: dispatch `/aegis:security-review` on the specific resources.
   - If the Infra Engineer flagged a DB hand-off: dispatch `/aegis:db-review` on the relevant resources.
   - Deployment notes.

This command is scoped to infra files only. For application code review, use `/aegis:code-review`. For a full pre-deploy check, use `/aegis:deploy-check`.

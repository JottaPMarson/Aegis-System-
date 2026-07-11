# Kubernetes Conventions

Rules for Kubernetes manifests and Helm charts. The `infra-engineer` agent applies these to every K8s output.

---

## Workloads (Deployments, StatefulSets, DaemonSets)

### Resource requests and limits
- Every container must declare `resources.requests` and `resources.limits`. Without them, the scheduler cannot make placement decisions and containers can starve the node.
  ```yaml
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
  ```
- Do not set CPU limit equal to CPU request unless you need guaranteed QoS. Burstable QoS (request < limit) is the safe default for most services.

### Replicas and availability
- Production Deployments: minimum 2 replicas.
- Define a `PodDisruptionBudget` for any workload with 2+ replicas:
  ```yaml
  spec:
    minAvailable: 1
    selector:
      matchLabels:
        app: my-service
  ```
- Use `RollingUpdate` strategy with `maxUnavailable: 0` and `maxSurge: 1` for zero-downtime deploys.

### Health probes
- Every container must declare both `livenessProbe` and `readinessProbe`.
- `readinessProbe` gates traffic — use it to signal when the container is actually ready to serve.
- `livenessProbe` triggers restarts — set conservative thresholds to avoid restart storms.
  ```yaml
  readinessProbe:
    httpGet:
      path: /health/ready
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
  livenessProbe:
    httpGet:
      path: /health/live
      port: 8080
    initialDelaySeconds: 15
    periodSeconds: 20
    failureThreshold: 3
  ```

### Image pull policy
- Use `imagePullPolicy: IfNotPresent` for tagged images (not `latest`).
- Use `imagePullPolicy: Always` only when the tag is mutable (which it should not be in production).
- Never use `latest` in production manifests.

---

## Security

### Pod security
- Every Pod spec must set a `securityContext`:
  ```yaml
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
  ```
- Avoid `privileged: true`. If required, flag it for `security-reviewer` before shipping.

### Secrets
- Never store secrets in ConfigMaps. Use Kubernetes Secrets, and mount them as files (not environment variables when avoidable — env vars leak into crash reports).
- For production, use an external secrets operator (External Secrets Operator + AWS Secrets Manager, Vault Agent Injector, or Sealed Secrets) instead of bare K8s Secrets.
- Do not commit `Secret` manifests with real values to git. Commit only the encrypted form (if using Sealed Secrets) or a reference template.

### RBAC
- Follow least privilege: create a dedicated `ServiceAccount` for each workload. Do not use the `default` service account.
- Roles and ClusterRoles: grant only the verbs and resources actually needed.
- Never use `cluster-admin` for workloads. Flag any `ClusterRoleBinding` for `security-reviewer` review.

### Network policies
- Define a `NetworkPolicy` for every namespace in production: default-deny all ingress and egress, then explicitly allow only what is needed.
  ```yaml
  # Default deny-all baseline
  spec:
    podSelector: {}
    policyTypes:
      - Ingress
      - Egress
  ```

---

## Configuration and secrets injection

- Use `ConfigMap` for non-sensitive configuration (feature flags, connection strings to public services).
- Mount ConfigMaps as files when config is large or complex. Env vars are acceptable for small, simple values.
- Reference ConfigMap and Secret keys by name in Pod specs — do not inline values.

---

## Labels and annotations

- Every resource must carry these labels:
  ```yaml
  labels:
    app.kubernetes.io/name: <service>
    app.kubernetes.io/version: <image-tag>
    app.kubernetes.io/component: <frontend|backend|worker|database>
    app.kubernetes.io/part-of: <product>
    app.kubernetes.io/managed-by: <helm|kubectl|flux>
  ```
- Use annotations for non-identifying metadata (Prometheus scrape config, cert-manager issuer, etc.).

---

## Namespaces

- One namespace per environment (e.g., `prod`, `staging`, `dev`), not per service.
- Set `ResourceQuota` and `LimitRange` on every namespace to prevent runaway resource consumption.
- Never `kubectl delete namespace` without confirming PVC data backup — PVCs are deleted with the namespace.

---

## Helm charts (when applicable)

- Pin chart and dependency versions. Do not use version ranges (`>=`, `*`).
- Always run `helm lint` and `helm template | kubeval` in CI before merging chart changes.
- Use `values.yaml` for defaults; override in `values-<env>.yaml`. Never hardcode environment-specific values in the chart itself.
- Document every value in `values.yaml` with a comment.

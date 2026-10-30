---
review:
  status: unreviewed
  notes: "Drafted from session discussion of ESO/VSO vs Agent Injector for keeping secrets out of etcd. Examples adapted from integration/README.md; commands not cluster-verified."
description: Vault Agent init, sidecar, and injector patterns that deliver secrets without Kubernetes Secret objects
---

# Vault Agent injection — secrets out of etcd

> **Audience:** Platform and app teams choosing how Pods consume Vault secrets on Kubernetes / OpenShift.
>
> **Purpose:** Decide when Agent injection beats ESO/VSO sync, and apply init-only, sidecar, or webhook-injector patterns without putting secret material in etcd.

**Related:** [Vault integration (multi-cluster)](integration/README.md) · [ESO + RHACM example](../rhacm/examples/secret-management/3_external_secrets_operator/README.md)

---

## The constraint

ESO and default VSO sync Vault data into a Kubernetes `Secret`.
That object is stored in **etcd** (base64, not encryption-at-rest unless you configure it).
Pods then consume via `env` / `envFrom` or a projected volume.

When the requirement is **secret material never enters etcd**, sync operators are the wrong tool.
Vault Agent (injector or manual) authenticates from the Pod, renders into a shared **tmpfs** volume, and leaves no `Secret` object behind.

Caveat: values still appear as **files on a memory-backed filesystem** inside the Pod (`/vault/secrets/...`).
Anyone with `exec` into the container can read them.
"Out of etcd" is not "invisible to the node" or "no filesystem path."

| Approach | In etcd? | On node disk? | In container |
|----------|----------|---------------|--------------|
| ESO / default VSO → K8s `Secret` | Yes | Usually tmpfs when mounted | File or env |
| Vault Agent (init / sidecar / injector) | No | No (`emptyDir: medium: Memory`) | Files under `/vault/secrets` |
| VSO CSI (`CSISecrets`, Vault Enterprise) | No | Ephemeral CSI volume | Files under mount path |
| App Vault SDK / API | No | No | Process memory only |

---

## How Agent delivery works

```
Pod CREATE
    │
    ▼
[Injector webhook]  ← optional; mutates PodSpec from annotations
    │
    ├─ init: vault-agent-init  → auth + render once, exit
    ├─ sidecar: vault-agent    → renew leases / re-render (optional)
    └─ volume: emptyDir Memory → shared path for app containers
```

1. Pod ServiceAccount authenticates to Vault (Kubernetes auth).
2. Agent fetches secrets and writes templates to the shared volume.
3. App reads files (or `source`s a shell fragment) from `/vault/secrets`.

No Kubernetes `Secret` is created for the payload.

---

## Pattern A — Injector webhook (preferred when available)

Install the Vault Agent Injector (Vault Helm chart `injector.enabled`, or equivalent).
Annotate the Pod; the mutating webhook adds init, optional sidecar, and the memory volume.

### Init + sidecar (long-lived Deployments)

Use when secrets may rotate, leases need renewal, or the app should see refreshed files without a full redeploy.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: prod-apps
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "my-app-prod"
        vault.hashicorp.com/agent-inject-secret-db: "secret/data/prod-apps/my-app/db"
        vault.hashicorp.com/agent-inject-template-db: |
          {{- with secret "secret/data/prod-apps/my-app/db" -}}
          export DB_USER="{{ .Data.data.username }}"
          export DB_PASS="{{ .Data.data.password }}"
          {{- end -}}
        # Vault Enterprise namespace (omit on OSS / root namespace):
        # vault.hashicorp.com/namespace: "prod"
    spec:
      serviceAccountName: my-app
      containers:
        - name: app
          image: my-app:1.0.0
          command: ["/bin/sh", "-c"]
          args:
            - source /vault/secrets/db && exec /app/start
```

The injector mounts `/vault/secrets` on every container in the Pod.
You do not declare that volume in the Deployment YAML.

### Init only (Jobs, CronJobs, static KV)

```yaml
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/agent-pre-populate-only: "true"
  vault.hashicorp.com/role: "my-job"
  vault.hashicorp.com/agent-inject-secret-token: "secret/data/jobs/api-token"
```

`agent-pre-populate-only: "true"` skips the sidecar so Jobs can terminate cleanly.

### Useful annotations

| Annotation | Effect |
|------------|--------|
| `agent-inject: "true"` | Enable mutation |
| `agent-pre-populate` | Init container (default `true`) |
| `agent-pre-populate-only` | Init only — no sidecar |
| `agent-inject-secret-<name>` | Vault path → `/vault/secrets/<name>` |
| `agent-inject-template-<name>` | Template body for that file |
| `role` | Vault Kubernetes auth role |
| `namespace` | Vault Enterprise namespace |

Upstream: [Injector](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/injector) · [Annotations](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/injector/annotations).

---

## Pattern B — Manual init + sidecar (no webhook)

Same mechanics, fully explicit in the PodSpec.
Use when the injector is unavailable, or GitOps must show every container without relying on admission mutation.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: prod-apps
spec:
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      serviceAccountName: my-app

      initContainers:
        - name: vault-agent-init
          image: hashicorp/vault:1.15
          args:
            - agent
            - -config=/vault/config/agent.hcl
            - -exit-after-auth
          env:
            - name: VAULT_ADDR
              value: "https://vault.example.com:8200"
          volumeMounts:
            - name: vault-config
              mountPath: /vault/config
            - name: vault-secrets
              mountPath: /vault/secrets

      containers:
        - name: app
          image: my-app:1.0.0
          volumeMounts:
            - name: vault-secrets
              mountPath: /vault/secrets
              readOnly: true
          command: ["/bin/sh", "-c"]
          args:
            - source /vault/secrets/database && exec /app/start

        # Omit for init-only / Job workloads
        - name: vault-agent
          image: hashicorp/vault:1.15
          args:
            - agent
            - -config=/vault/config/agent.hcl
          env:
            - name: VAULT_ADDR
              value: "https://vault.example.com:8200"
          volumeMounts:
            - name: vault-config
              mountPath: /vault/config
            - name: vault-secrets
              mountPath: /vault/secrets
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 128Mi

      volumes:
        - name: vault-config
          configMap:
            name: vault-agent-config
        - name: vault-secrets
          emptyDir:
            medium: Memory
            sizeLimit: 10Mi
```

### Agent ConfigMap sketch

```hcl
pid_file = "/home/vault/.pid"

auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role = "my-app-prod"
    }
  }
}

template {
  destination = "/vault/secrets/database"
  contents = <<EOH
{{- with secret "secret/data/prod-apps/my-app/db" -}}
export DB_USER="{{ .Data.data.username }}"
export DB_PASS="{{ .Data.data.password }}"
{{- end -}}
EOH
}

vault {
  address = "https://vault.example.com:8200"
}
```

Pin Vault policy to the Pod's ServiceAccount:

```bash
vault write auth/kubernetes/role/my-app-prod \
  bound_service_account_names=my-app \
  bound_service_account_namespaces=prod-apps \
  policies=my-app-prod \
  ttl=1h
```

---

## When to use which

| Pattern | Use when |
|---------|----------|
| **Injector + init + sidecar** | Long-lived Deployments; dynamic secrets or lease renewal |
| **Injector + `pre-populate-only`** | Jobs / CronJobs; static KV; no refresh needed |
| **Manual init (+ optional sidecar)** | No injector; full PodSpec must live in Git |
| **ESO / default VSO** | Native K8s `Secret` consumption is fine; etcd storage acceptable |
| **VSO CSI** | Vault Enterprise; want CR-gated mounts without Agent sidecars |

Sidecar cost is real: CPU/memory per Pod, and Pod startup depends on Vault availability.
That is the usual reason fleets default to ESO for ordinary app config and reserve Agent injection for compliance-sensitive or short-lived credentials.

For a tiered fleet model (RHACM / ESO / Agent), see [Option 3 and the hybrid recommendation](integration/README.md#option-3-vault-agent-sidecar-injection) in the multi-cluster integration guide.

---

## Limits (be explicit)

- **Not encryption in use.** tmpfs files are readable in-container; protect with RBAC, no shared Privileged access, and short TTLs.
- **App must tolerate a file path** (or source a shell env file). Pure env-from-Secret without etcd is not what Agent gives you.
- **Autoscaling couples to Vault.** Failed auth or Vault outage blocks new Pods that need the init container.
- **Templates are Consul Template syntax**, not ESO's Go templates — migration from ESO sync needs a rewrite of render logic.

---

## References

- [Vault Agent Injector](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/injector)
- [Injector annotations](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/injector/annotations)
- [Kubernetes integrations comparison](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/comparisons) — VSO, CSI, Agent Injector
- [VSO CSI protected secrets](https://developer.hashicorp.com/vault/docs/deploy/kubernetes/vso/csi) — Enterprise alternative to Agent for out-of-etcd mounts
- Workspace: [integration/README.md](integration/README.md) (Option 3 + Tier 3 examples)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

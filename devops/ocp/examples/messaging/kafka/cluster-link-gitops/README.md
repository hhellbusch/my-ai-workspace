---
review:
  status: unreviewed
  notes: "Example scaffold for Cluster Link GitOps — Pattern A (CRD) and Pattern B (reconcile Job); not wired to a live cluster."
---

# Cluster Link GitOps — example scaffold

**Audience:** Kafka/platform engineers adopting Argo CD who need copy-paste starting points for link management.

**Purpose:** Example **desired-state specs**, a **reconcile script**, **ClusterLink CRs**, and **Argo/Kubernetes Job** manifests aligned with [CLUSTER-LINK-GITOPS.md](../CLUSTER-LINK-GITOPS.md).

**Related:** [Cross-DC Cluster Linking](../cross-dc-cluster-linking.md) · [BROKER-IPAM.md](../cross-dc-kafka-net-helm/BROKER-IPAM.md) · [Rollout inventory](../../../networking/cross-dc-rollout/README.md)

---

## Layout

```text
cluster-link-gitops/
  README.md
  desired/          # Pattern B — script input (not a CFK CR)
  crd/              # Pattern A — ClusterLink CR examples
  scripts/          # reconcile + bootstrap helpers
  k8s/              # Job, ConfigMap, ServiceAccount for Pattern B/C
  argo/             # Application wiring sync waves + hooks
```

---

## GitOps maturity ladder (cluster links)

Use this to pick a pattern before chasing full automation.

| Level | What “done” looks like | Pattern |
|---|---|---|
| 0 — Ad hoc | Link created in Control Center UI; bootstrap copied by hand | Anti-pattern |
| 1 — Scripted | curl/CLI checked into Git; runbook for failover | E (partial) |
| 2 — Declarative spec | `desired/*.yaml` is source of truth; script applies on demand | B |
| 3 — Sync hook | Argo Job runs reconcile after Kafka/NAD waves | B + C |
| 4 — Native CR | `ClusterLink` CR in Git; CFK operator reconciles | A |
| 5 — Drift-aware | CronJob `--check-only` or ACM health on link spec | D (+ A or B) |

Move up the ladder only when the **gap checklist** in [CLUSTER-LINK-GITOPS.md](../CLUSTER-LINK-GITOPS.md#gap-discovery-checklist) passes for the next level.

---

## Quick start (Pattern B — reconcile Job)

1. Copy `desired/dc-a-to-dc-b.example.yaml` → `desired/dc-a-to-dc-b.yaml` and fill `source.clusterId`, auth, mirror topics.
2. Set **`bootstrapEndpoint`** to remote **REPLICATION** Multus IPs (not `.svc` DNS) — use [render-bootstrap-from-inventory.example.sh](scripts/render-bootstrap-from-inventory.example.sh) with static inventory.
3. Dry-run locally:

```bash
export KAFKA_REST_URL="https://kafka.confluent.svc.cluster.local:8090"
export KAFKA_CLUSTER_ID="<destination-cluster-id>"
./scripts/reconcile-link.example.sh --spec desired/dc-a-to-dc-b.yaml --dry-run
```

4. Apply (requires Admin REST reachability + credentials):

```bash
export KAFKA_REST_BASIC_AUTH_USER="..."
export KAFKA_REST_BASIC_AUTH_PASS="..."
./scripts/reconcile-link.example.sh --spec desired/dc-a-to-dc-b.yaml --apply
```

5. Wire [k8s/job-reconcile-dc-a-to-dc-b.example.yaml](k8s/job-reconcile-dc-a-to-dc-b.example.yaml) into your Argo Application ([argo/application-dc-b-confluent.example.yaml](argo/application-dc-b-confluent.example.yaml)).

Repeat on DC-A for `dc-b-to-dc-a` for bidirectional pre-staged DR.

---

## Quick start (Pattern A — ClusterLink CR)

1. Edit [crd/clusterlink-dc-a-to-dc-b.example.yaml](crd/clusterlink-dc-a-to-dc-b.example.yaml) — `bootstrapEndpoint`, `clusterID`, `KafkaRestClass` refs, TLS/SASL blocks.
2. Sync via Argo with sync wave **after** Kafka CR (see CR metadata annotations).
3. **Do not** also run the reconcile script for the same logical link — CFK may delete API-managed mirrors.

---

## Bootstrap from inventory

Static broker IPs from rollout inventory:

```bash
./scripts/render-bootstrap-from-inventory.example.sh \
  ../../../networking/cross-dc-rollout/inventory-dc-a.static.example.yaml
# → 10.200.1.21:9095,10.200.1.22:9095,10.200.1.23:9095
```

For whereabouts mode, render bootstrap **after** brokers are up (from `network-status` or your IPAM artifact) — see [BROKER-IPAM.md](../cross-dc-kafka-net-helm/BROKER-IPAM.md).

---

## Customization checklist

| Item | Where |
|---|---|
| Logical link name (bidirectional pair must match) | `spec.linkName` / `ClusterLink.spec.name` |
| Destination cluster Admin REST | Job env / `KafkaRestClass` |
| Remote REPLICATION bootstrap | `bootstrapEndpoint` only |
| Mirror topic list / prefix | `mirrorTopics` |
| Sync ordering | Argo waves: Kafka `10`, link `20`–`30` |
| Credentials | Kubernetes Secrets — not in Git |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

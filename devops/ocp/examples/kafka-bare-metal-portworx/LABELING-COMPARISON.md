# Rack labeling — zone/region vs custom labels

**Audience:** Platform engineers choosing how to represent physical racks on bare-metal OpenShift for Kafka + Portworx.

**Purpose:** Compare two supported labeling models side by side so you can pick one per cluster and keep inventory, Strimzi, Portworx, and ACM manifests aligned.

**Related:** [README.md](README.md) · [manifests/README.md](manifests/README.md)

---

## Pick one model per cluster

| | [zone-region](manifests/zone-region/) | [custom-rack](manifests/custom-rack/) |
|---|--------------------------------------|--------------------------------------|
| **Rack label** | `topology.kubernetes.io/zone: rack-a` | `platform.example.com/rack: rack-a` |
| **Site label** | `topology.kubernetes.io/region: dc1` | `platform.example.com/site: dc1` |
| **Strimzi `rack.topologyKey`** | `topology.kubernetes.io/zone` | `platform.example.com/rack` |
| **CFK `rackAssignment.nodeLabels`** | `[topology.kubernetes.io/zone]` | `[platform.example.com/rack]` |
| **Spread / anti-affinity `topologyKey`** | `topology.kubernetes.io/zone` | `platform.example.com/rack` |
| **Portworx rack label** | `px/rack: rack-a` | `px/rack: rack-a` *(unchanged)* |
| **Example rack values** | `rack-a`, `rack-b`, `rack-c` | same |

Replace `platform.example.com` with your org domain (e.g. `kafka.company.com`).

**Portworx always uses `px/rack`** — that is Portworx's API, not Kubernetes topology. Both variants set `px/rack` to the same rack ID as the Kafka failure-domain label.

---

## Side-by-side: node labels

### Post-install (`oc label`)

**Zone/region variant** — [`zone-region/node-labels.example.yaml`](manifests/zone-region/node-labels.example.yaml)

```bash
oc label node worker-a1.example.com \
  topology.kubernetes.io/zone=rack-a \
  topology.kubernetes.io/region=dc1 \
  px/rack=rack-a
```

**Custom-rack variant** — [`custom-rack/node-labels.example.yaml`](manifests/custom-rack/node-labels.example.yaml)

```bash
oc label node worker-a1.example.com \
  platform.example.com/rack=rack-a \
  platform.example.com/site=dc1 \
  px/rack=rack-a
```

---

## Side-by-side: ACM BMAC annotations

**Zone/region** — [`zone-region/acm-bmh-worker-host.example.yaml`](manifests/zone-region/acm-bmh-worker-host.example.yaml)

```yaml
bmac.agent-install.openshift.io/node-label.topology.kubernetes.io/zone: rack-a
bmac.agent-install.openshift.io/node-label.topology.kubernetes.io/region: dc1
bmac.agent-install.openshift.io/node-label.px/rack: rack-a
```

**Custom-rack** — [`custom-rack/acm-bmh-worker-host.example.yaml`](manifests/custom-rack/acm-bmh-worker-host.example.yaml)

```yaml
bmac.agent-install.openshift.io/node-label.platform.example.com/rack: rack-a
bmac.agent-install.openshift.io/node-label.platform.example.com/site: dc1
bmac.agent-install.openshift.io/node-label.px/rack: rack-a
```

---

## Side-by-side: Strimzi

**Zone/region** — `rack.topologyKey` and spread constraints:

```yaml
spec:
  kafka:
    rack:
      topologyKey: topology.kubernetes.io/zone
# KafkaNodePool template:
      topologySpreadConstraints:
        - topologyKey: topology.kubernetes.io/zone
```

**Custom-rack**:

```yaml
spec:
  kafka:
    rack:
      topologyKey: platform.example.com/rack
# KafkaNodePool template:
      topologySpreadConstraints:
        - topologyKey: platform.example.com/rack
```

Files: [`zone-region/strimzi/`](manifests/zone-region/strimzi/) vs [`custom-rack/strimzi/`](manifests/custom-rack/strimzi/)

---

## Side-by-side: Confluent (CFK)

**Zone/region** — `rackAssignment` + pod anti-affinity:

```yaml
spec:
  oneReplicaPerNode: true
  rackAssignment:
    nodeLabels:
      - topology.kubernetes.io/zone
  podTemplate:
    serviceAccountName: kafka-rack
    affinity:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values: [prod-kafka]
            topologyKey: topology.kubernetes.io/zone
```

**Custom-rack**:

```yaml
spec:
  rackAssignment:
    nodeLabels:
      - platform.example.com/rack
  podTemplate:
    affinity:
      podAntiAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: platform.example.com/rack
```

Files: [`zone-region/confluent/`](manifests/zone-region/confluent/) vs [`custom-rack/confluent/`](manifests/custom-rack/confluent/) · RBAC: [`common/confluent-kafka-rbac.yaml`](manifests/common/confluent-kafka-rbac.yaml)

---

## Side-by-side: Confluent vs Strimzi

| Concern | Strimzi / AMQ Streams | Confluent (CFK) |
|---------|----------------------|-----------------|
| Set `broker.rack` from node label | `spec.kafka.rack.topologyKey` | `spec.rackAssignment.nodeLabels` (list) |
| One broker per node | `podAntiAffinity` on `kubernetes.io/hostname` | `spec.oneReplicaPerNode: true` + hostname anti-affinity |
| Spread across racks | `topologySpreadConstraints` on rack key | `podAntiAffinity` on rack key (or pod overlay for spread constraints) |
| RBAC for rack lookup | Operator handles internally | ServiceAccount + ClusterRole (`get`/`list` nodes, pods) |
| Storage class | `KafkaNodePool.spec.storage.class` | `spec.storageClass.name` + `dataVolumeCapacity` |
| KRaft | `Kafka` + `KafkaNodePool` CRs | `KRaftController` + `Kafka` CRs |

---

## Side-by-side: inventory (Ansible)

| Inventory field | Zone/region label key | Custom-rack label key |
|-----------------|----------------------|------------------------|
| `rack` | `topology.kubernetes.io/zone` | `platform.example.com/rack` |
| `site` / `region` | `topology.kubernetes.io/region` | `platform.example.com/site` |
| `rack` (Portworx) | `px/rack` | `px/rack` |

See [`zone-region/inventory-workers.example.yaml`](manifests/zone-region/inventory-workers.example.yaml) and [`custom-rack/inventory-workers.example.yaml`](manifests/custom-rack/inventory-workers.example.yaml).

---

## What does NOT change between variants

| Artifact | Why |
|----------|-----|
| [`common/portworx-storageclass-kafka.yaml`](manifests/common/portworx-storageclass-kafka.yaml) | `racks: "rack-a,rack-b,rack-c"` references **values**, not K8s label keys |
| [`common/machineconfig-kafka-tuning.yaml`](manifests/common/machineconfig-kafka-tuning.yaml) | Optional; `role: worker` — rationale, refs, Kafka + non-Kafka trade-offs in header |
| Replication / minISR Kafka config | Logical rack awareness via `broker.rack`, not label key name |

---

## When to use which

### Use `topology.kubernetes.io/zone` (zone-region variant)

- You want alignment with **Kubernetes well-known labels** and many Helm charts that assume `zone`.
- You may run **other workloads** that already spread on `topology.kubernetes.io/zone`.
- You want **MCO upgrade drain ordering by zone** (alphabetical by zone, then oldest node) — MCO only understands `topology.kubernetes.io/zone` for this, not custom keys.

### Use custom labels (custom-rack variant)

- `zone` / `region` are **already used** for real AZ semantics (hybrid cloud, stretched cluster) and you need rack without overloading zone.
- Your **inventory / CMDB** already names attributes `rack` and `site` and you want 1:1 mapping to label keys.
- **Governance** requires a private domain prefix (`company.com/rack`) so topology is explicit and not confused with cloud provider zones.

### Hybrid (avoid if possible)

Some teams set **both** `topology.kubernetes.io/zone` and `platform.example.com/rack` to the same value. That works but duplicates source of truth — pick one key for Strimzi `topologyKey` and document which inventory field owns it.

---

## Operational differences

| Concern | Zone/region | Custom-rack |
|---------|-------------|-------------|
| Strimzi / Kafka `broker.rack` | From `topology.kubernetes.io/zone` | From `platform.example.com/rack` |
| CFK `rackAssignment` | Reads `topology.kubernetes.io/zone` | Reads `platform.example.com/rack` |
| Pod spread across racks | Strimzi: `topologySpreadConstraints`; CFK: `podAntiAffinity` on rack key | Same pattern, different label key |
| MCO drain order by failure domain | **Yes** — drains by zone alphabetically | **No** — MCO ignores custom keys; drains by node age cluster-wide |
| Portworx replica placement | `px/rack` (same both) | `px/rack` (same both) |
| ACM BMAC Day-0 labels | Annotation key = label key | Annotation key = label key |
| Tools expecting cloud AZ | May misread bare-metal `zone` as cloud AZ | Clearer semantics |

The **MCO drain ordering** row is the main operational tradeoff: custom labels give semantic clarity but you lose zone-aware sequential drains unless you also set `topology.kubernetes.io/zone` or accept oldest-first ordering on bare metal.

---

## Verification (compare variants)

```bash
# Zone/region variant
oc get nodes -l node-role.kubernetes.io/worker \
  -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone,RACK:.metadata.labels.px/rack

# Custom-rack variant
oc get nodes -l node-role.kubernetes.io/worker \
  -o custom-columns=NAME:.metadata.name,RACK:.metadata.labels.platform\\.example\\.com/rack,PX:.metadata.labels.px/rack
```

---

## Manifest layout

```
manifests/
├── README.md
├── common/                    # shared (both variants)
├── zone-region/               # topology.kubernetes.io/zone + region
│   ├── node-labels.example.yaml
│   ├── acm-bmh-worker-host.example.yaml
│   ├── inventory-workers.example.yaml
│   ├── confluent/
│   └── strimzi/
└── custom-rack/               # platform.example.com/rack + site
    ├── node-labels.example.yaml
    ├── acm-bmh-worker-host.example.yaml
    ├── inventory-workers.example.yaml
    ├── confluent/
    └── strimzi/
```

*Example configurations — see [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md).*

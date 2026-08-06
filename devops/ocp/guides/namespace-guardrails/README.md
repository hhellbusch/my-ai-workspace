---
review:
  status: unreviewed
  notes: "AI-assisted guide from research session 2026-08-06. Quota numbers are starting templates — validate against cluster size and tenant mix."
---

# Namespace guardrails beyond CPU and memory

How to limit what a namespace can put into etcd and the control plane — not just what it can schedule on nodes.

**Audience:** Platform operators defining multi-tenant OpenShift namespace policy.

**Purpose:** Choose quota keys, tier defaults, and wiring (project templates, ClusterResourceQuota) so tenant namespaces cannot exhaust control plane storage or API throughput.

**Related:** [Container density / overcommit](../../notes/container-density-overcommit.md) (node packing) · [API slowness troubleshooting](../../troubleshooting/api-slowness-web-console/README.md) (when guardrails are missing) · [QUICK-REFERENCE.md](QUICK-REFERENCE.md)

---

## On this page

- [Two different problems](#two-different-problems)
- [Mechanisms](#mechanisms)
- [Object count quotas](#object-count-quotas)
- [Control plane and etcd impact](#control-plane-and-etcd-impact)
- [Tested maximums vs tenant defaults](#tested-maximums-vs-tenant-defaults)
- [Hidden limits](#hidden-limits)
- [Tiered templates](#tiered-templates)
- [Project request templates](#project-request-templates)
- [ClusterResourceQuota](#clusterresourcequota)
- [Operational playbook](#operational-playbook)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Two different problems

| Problem | What breaks | Typical lever |
|---------|-------------|---------------|
| **Node capacity** | Scheduler cannot place pods; nodes OOM or throttle | `requests.cpu`, `limits.memory`, `requests.storage` |
| **Control plane capacity** | etcd fills or slows; API lists time out; controllers lag | Object **counts**, object **size**, **churn** |

CPU and memory quotas answer: *"How much can this namespace schedule?"*
Object count quotas answer: *"How many API objects can this namespace store and force the platform to watch?"*

A tenant can stay under CPU/memory quotas while still degrading the cluster — thousands of ConfigMaps from a misconfigured operator, runaway CronJobs creating Jobs, or Deployment revisions leaving dozens of ReplicaSets per app.

Kubernetes documents object-count quotas explicitly as protection against **control plane storage exhaustion** — not only fairness on workers.

---

## Mechanisms

Three objects work together. They are not interchangeable.

| Object | Scope | Limits |
|--------|-------|--------|
| **LimitRange** | Per pod / container / PVC | Min, max, default request/limit on individual objects |
| **ResourceQuota** | Per namespace | Aggregate compute, storage, and **object counts** |
| **ClusterResourceQuota** (OCP) | Selected namespaces | Same quota keys, aggregated across matching projects |

**LimitRange** shapes individual pods at admission.
**ResourceQuota** caps namespace totals.
For a complete policy, use both: LimitRange for sane defaults, ResourceQuota for aggregate caps including object counts.

OpenShift does **not** apply ResourceQuotas to new projects by default.
Without a **project request template**, namespaces are born with no object limits.

Pair compute quotas with object counts when adopting density tooling.
See [container-density-overcommit](../../notes/container-density-overcommit.md) — step 1 there is namespace defaults including ResourceQuota.

---

## Object count quotas

### Specialized keys (core API)

These keys are built into the quota admission plugin:

| Quota key | Counts |
|-----------|--------|
| `pods` | Non-terminal pods |
| `services` | All Services |
| `services.loadbalancers` | `type: LoadBalancer` |
| `services.nodeports` | NodePort allocations |
| `secrets` | Secrets |
| `configmaps` | ConfigMaps |
| `persistentvolumeclaims` | PVCs |
| `replicationcontrollers` | ReplicationControllers |
| `resourcequotas` | ResourceQuota objects in the namespace |

### Generic `count/` syntax (any namespaced type)

For API kinds not in the specialized list — including CRDs and most OpenShift types:

```yaml
spec:
  hard:
    count/deployments.apps: "30"
    count/replicasets.apps: "60"
    count/jobs.batch: "20"
    count/cronjobs.batch: "10"
    count/statefulsets.apps: "10"
    count/networkpolicies.networking.k8s.io: "20"
    count/widgets.example.com: "100"   # CRD example
```

CLI equivalent:

```bash
oc create quota guardrails --hard=count/deployments.apps=30,count/secrets=50,count/pods=100 -n myproject
```

### OpenShift-specific keys

| Quota key | Resource |
|-----------|----------|
| `openshift.io/imagestreams` | ImageStreams |
| `count/routes.route.openshift.io` | Routes |
| `count/buildconfigs.build.openshift.io` | BuildConfigs |

OpenShift charges an object against quota when it **exists in server storage** — not when it is merely referenced.

### Objects that multiply silently

Watch these when setting counts; they often exceed what developers expect:

| Object | Multiplier |
|--------|------------|
| **ReplicaSets** | Each Deployment revision (default `revisionHistoryLimit: 10`) |
| **Jobs** | CronJob schedule + failed job retention |
| **Secrets** | TLS per Route, SA token mounts, Helm/operator releases |
| **ConfigMaps** | Helm releases, operator configs, `envFrom` per deployment |
| **Events** | Failing probes, crash loops — no quota key; use TTL and fix root cause |
| **Endpoints** (legacy) | Large Services — size limit ~1.5 MB per object |

Set `revisionHistoryLimit: 3` on Deployments when RS quota is tight.
The [API slowness guide](../../troubleshooting/api-slowness-web-console/README.md) recommends this for control-plane hygiene.

---

## Control plane and etcd impact

Every namespaced object is stored in etcd.
More objects → larger keyspace → more compaction, defragmentation, and read load on the API server.

### etcd disk quota (OpenShift)

Per etcd member, `spec.backendQuotaGiB` defaults to **8 GiB** (range **8–32 GiB**).
When usage exceeds quota despite compaction and defrag, etcd raises cluster-wide alarms and enters maintenance mode: **reads and deletes only** — writes fail.

Monitor:

| Metric | Meaning |
|--------|---------|
| `etcd_server_quota_backend_bytes` | Configured quota |
| `etcd_mvcc_db_total_size_in_use_in_bytes` | Actual usage after compaction |
| `etcd_mvcc_db_total_size_in_bytes` | Includes space awaiting defrag |

Alerts: `low space`, `excessive database growth`.
See [Performance considerations for etcd](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/etcd/performance-considerations-for-etcd) — OCP 4.19.

### Per-object size limit

etcd enforces ~**1.5 MB per key**.
Oversized Secrets, ConfigMaps, or monolithic **Endpoints** objects fail with `request is too large` or `Request entity too large`.

Kubernetes addressed large Services with **EndpointSlices** (multiple smaller objects).
Legacy Endpoints near 1.5 MB cap a Service at roughly 5,000 pod backends.

Prefer references (URLs, volume mounts) over embedding large blobs in API objects.

### Controller iteration cost

Red Hat's scalability documentation states that control loops must sometimes iterate **all objects of a type in a namespace**.
High per-namespace object density slows reaction to state changes — even when cluster-wide totals look fine.

### Churn matters as much as count

**Churn** — rate of creates/updates/deletes — stresses etcd and the API server independently of steady-state object count.

Factors Red Hat lists for scale planning:

- Pod create/delete rate
- Probe types and frequency
- NetworkPolicies per namespace
- Secrets, ConfigMaps, builds, routes per namespace
- API request rate: `sum(irate(apiserver_request_count{}[5m]))`

A namespace with modest counts but extreme churn can hurt the control plane more than a stable namespace with higher counts.

### Watch and list amplification

Controllers LIST and WATCH namespace-scoped resources.
Large objects (Endpoints before EndpointSlices) multiplied by node count produced multi-gigabyte transfer on single updates at scale.

Object count quotas reduce the ceiling; object **size** discipline reduces per-update cost.

---

## Tested maximums vs tenant defaults

Red Hat publishes **tested** cluster maximums — not hard absolute limits.
Exceeding them tends to reduce performance; it may not fail the cluster immediately.

Relevant cluster-wide tested maximums (large-cluster scenarios, OCP 4.19):

| Dimension | Tested max |
|-----------|------------|
| Namespaces | 10,000 |
| Pods per namespace | 25,000 |
| Services per namespace | 5,000 |
| Secrets (cluster) | 80,000 |
| ConfigMaps (cluster) | 90,000 |
| Deployments per namespace | 2,000 |

See [Planning according to object maximums](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/scalability_and_performance/planning-your-environment-according-to-object-maximums) — OCP 4.19.

### What Red Hat actually tested per namespace

At 500-node scale, example workload **per namespace**:

| Object | Tested per ns |
|--------|---------------|
| Secrets | 20 |
| ConfigMaps | 10 |
| Services | 15 |
| NetworkPolicies | 6 |
| ImageStreams | 57 |
| Builds | 57 |

Use tested per-namespace numbers as the basis for **tenant tier defaults**, not the cluster-wide maximums.
The [tier examples](examples/) in this guide sit between sandbox and those tested workloads.

---

## Hidden limits

Quotas do not cover every namespace-scoped failure mode.

### Services × pods (ARG_MAX)

When pods use **service environment variables** for discovery (not cluster DNS), the kubelet injects env vars for every Service in the namespace.
With ~5,000 Services, pods fail when total environment argument length exceeds `ARG_MAX` (~2 MiB on typical nodes).

Mitigations:

- Use cluster DNS for service discovery
- Set `enableServiceLinks: false` on pod specs that do not need service env injection
- Quota `services` below the danger zone

### Events

Events are stored in etcd.
There is no per-namespace Event quota key.
Noisy workloads (failing probes, crash loops) accumulate Events and slow API list operations.

Mitigations:

- Fix failing workloads
- Review event counts: `oc get events -A --no-headers | wc -l`
- Default event TTL is 1 hour; accumulation indicates ongoing failure

### Endpoints object size

Very large Services without EndpointSlices can hit the 1.5 MB etcd key limit.
Prefer EndpointSlices (default on modern clusters) and cap backends per Service in application design.

---

## Tiered templates

Starting templates for three tenant sizes.
**Tune from measurement** — these are guardrails, not capacity planning outputs.

| Tier | File | Typical use |
|------|------|-------------|
| Small | [resourcequota-small.yaml](examples/resourcequota-small.yaml) | Sandboxes, personal projects |
| Medium | [resourcequota-medium.yaml](examples/resourcequota-medium.yaml) | Standard team production |
| Large | [resourcequota-large.yaml](examples/resourcequota-large.yaml) | High-churn or platform-adjacent tenants |

Shared LimitRange defaults: [limitrange-defaults.yaml](examples/limitrange-defaults.yaml)

Apply to an existing namespace:

```bash
oc apply -f examples/limitrange-defaults.yaml -n team-a
oc apply -f examples/resourcequota-medium.yaml -n team-a
```

Inspect usage:

```bash
oc describe quota -n team-a
oc describe limitrange -n team-a
```

---

## Project request templates

To inject quotas on **every new project**, add LimitRange and ResourceQuota objects to the cluster project request template.

Workflow (OCP 4.x):

1. Export or create template in `openshift-config`:

   ```bash
   oc get templates -n openshift-config
   ```

2. Add objects from [project-template-snippet.yaml](examples/project-template-snippet.yaml) **before** the `parameters:` section.

3. Create or update the template:

   ```bash
   oc create -f template.yaml -n openshift-config
   ```

4. Point cluster project config at the template:

   ```bash
   oc edit project.config.openshift.io/cluster
   ```

   ```yaml
   spec:
     projectRequestTemplate:
       name: project-request
   ```

New self-service projects receive the quota objects automatically.
**Existing projects are not retrofitted** — apply tier YAML manually or via GitOps.

See [Quotas — configuring explicit resource quotas](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/building_applications/quotas#quotas-setting-explicit-resource-quotas) — OCP 4.19.

---

## ClusterResourceQuota

When one user or team owns many projects, per-namespace quotas may allow excessive **aggregate** footprint.

`ClusterResourceQuota` aggregates usage across namespaces matching a label or annotation selector.

Example — cap all projects requested by one user:

```bash
oc create clusterresourcequota for-user \
  --project-annotation-selector openshift.io/requester=alice@example.com \
  --hard pods=200,secrets=150,configmaps=150,requests.cpu=16,requests.memory=32Gi
```

YAML: [clusterresourcequota-user.yaml](examples/clusterresourcequota-user.yaml)

Project admins **cannot** edit ClusterResourceQuota affecting their projects.
They can view applied limits via `AppliedClusterResourceQuota`:

```bash
oc get appliedclusterresourcequota -n team-a
```

Highly privileged system namespaces (`openshift`, `kube-system`, etc.) are excluded from multi-project quota mechanics.

---

## Operational playbook

### Audit object density

```bash
# Per-namespace counts (extend for types you quota)
for ns in $(oc get ns -o jsonpath='{.items[*].metadata.name}'); do
  pods=$(oc get pods -n "$ns" --no-headers 2>/dev/null | wc -l)
  cm=$(oc get cm -n "$ns" --no-headers 2>/dev/null | wc -l)
  secrets=$(oc get secrets -n "$ns" --no-headers 2>/dev/null | wc -l)
  svc=$(oc get svc -n "$ns" --no-headers 2>/dev/null | wc -l)
  echo "$ns: pods=$pods cm=$cm secrets=$secrets svc=$svc"
done
```

Find namespaces approaching quota:

```bash
oc describe quota -A | grep -E '^Name:|configmaps|secrets|pods'
```

### Signals that quotas may be too loose

| Signal | Action |
|--------|--------|
| Rising `etcd_mvcc_db_total_size_in_use_in_bytes` | Audit top namespaces by object count |
| `low space` or `excessive database growth` alerts | Increase etcd disk quota **and** tighten tenant object limits |
| API/console slowness, healthy workers | See [API slowness guide](../../troubleshooting/api-slowness-web-console/README.md) |
| Single namespace dominates object counts | Apply or lower tier quota; investigate operator or GitOps churn |
| High Event count | Fix failing workloads; not solvable with ResourceQuota |

### Adoption order

1. **LimitRange** on new namespaces (defaults so compute quotas work)
2. **ResourceQuota** with object counts — start medium tier, adjust
3. **Project request template** so self-service namespaces inherit policy
4. **ClusterResourceQuota** for users who own many projects
5. **Measure** — `oc describe quota`, etcd metrics, API latency — before widening tiers

---

## Troubleshooting

### `Forbidden: exceeded quota`

```text
pods "myapp-xyz" is forbidden: exceeded quota: tier-medium, requested: pods
```

Identify which quota and key:

```bash
oc describe quota -n <namespace>
```

Resolution paths:

- Delete unused objects (old ReplicaSets, completed Jobs, orphaned ConfigMaps)
- Raise the specific quota key (or move tenant to larger tier)
- Fix runaway automation (CronJob, broken controller)

### Quota present but pods fail on CPU/memory

ResourceQuota for `requests.cpu` / `limits.memory` requires pods to **declare** those fields when quota is active.
Use LimitRange defaults or require limits in pod specs.

### Oversized object rejected

```text
etcdserver: request is too large
Request entity too large: limit is 3145728
```

Object exceeds etcd (~1.5 MB) or API server request limit.
Split data across multiple objects, use PVC/volume mounts, or store externally.

### ClusterResourceQuota not visible to project admin

Expected — only cluster admins create `ClusterResourceQuota`.
Project admins use `oc get appliedclusterresourcequota`.

---

## References

### Kubernetes

- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/) — object counts, `count/` syntax, control-plane rationale
- [LimitRanges](https://kubernetes.io/docs/concepts/policy/limit-range/)
- [sig-scalability thresholds](https://github.com/kubernetes/community/blob/main/sig-scalability/configs-and-limits/thresholds.md) — 1.5 MB object size
- [Scaling networking with EndpointSlices](https://kubernetes.io/blog/2020/09/02/scaling-kubernetes-networking-with-endpointslices/)

### OpenShift (pinned 4.19 — verify for your minor)

- [Quotas](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/building_applications/quotas) — project quotas, ClusterResourceQuota, templates
- [Using quotas and limit ranges](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/scalability_and_performance/compute-resource-quotas) — object count quotas, `count/` examples
- [Planning according to object maximums](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/scalability_and_performance/planning-your-environment-according-to-object-maximums) — tested limits, churn, ARG_MAX
- [Performance considerations for etcd](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/etcd/performance-considerations-for-etcd) — disk quota, defrag, alerts

### Workspace

- [Container density / overcommit](../../notes/container-density-overcommit.md) — compute-focused namespace policy
- [API slowness troubleshooting](../../troubleshooting/api-slowness-web-console/README.md) — etcd and API degradation
- [Research drawer](../../../../research/ocp-namespace-guardrails/README.md) — source list

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

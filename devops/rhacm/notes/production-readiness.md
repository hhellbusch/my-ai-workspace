---
review:
  status: unreviewed
  notes: "AI-generated 2026-04-23. Production items sourced from ACM 2.16 install docs (https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/install/installing). Search PVC item confirmed in production session 2026-04-23. Cluster backup, infra nodes, availability config, OLM approval, observability, and sizing sections are doc-sourced but not all exercised in this environment — needs review pass against actual cluster state."
---

# ACM Production Readiness — Hub Setup Checklist

A working reference for validating a production ACM hub against the recommended configuration from the [ACM 2.16 install docs](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/install/installing). Intended as a planning and audit tool, not a deployment runbook.

Items are grouped by risk and whether they require active setup vs. verification of defaults.

---

## Quick Audit

Run this first to see the current state of the hub in one pass:

```bash
# Hub status, availability config, component states
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.status.phase}{"\n"}availabilityConfig: {.spec.availabilityConfig}{"\n"}{range .spec.overrides.components[*]}{.name}: {.enabled}{"\n"}{end}'

# Search PVC
oc get pvc -n open-cluster-management | grep search

# OLM subscription approval mode
oc get subscription advanced-cluster-management \
  -n open-cluster-management \
  -o jsonpath='installPlanApproval: {.spec.installPlanApproval}{"\n"}'

# Hub node capacity
oc get nodes -l node-role.kubernetes.io/worker \
  -o custom-columns='NAME:.metadata.name,CPU:.status.capacity.cpu,MEM:.status.capacity.memory'
```

---

## 1. Search Persistent Storage

**Default:** `emptyDir` — data lost on every pod restart, index rebuilds from scratch, drives OOMKill under load.

**Status check:**
```bash
oc get pvc -n open-cluster-management | grep search
oc get search search-v2-operator -n open-cluster-management \
  -o jsonpath='{.spec.dbStorage}{"\n"}'
```

**Required config** — add `spec.dbStorage` to the Search CR with a block RWO storage class:

```yaml
spec:
  dbStorage:
    size: 10Gi
    storageClassName: <block-rwo-storage-class>
```

Sizing: 10Gi default, ~20Gi for ~200 managed clusters. See [search-setup.md](./search-setup.md) for full setup and [search-service-503.md](../troubleshooting/search-service-503.md) for the OOMKill scenario.

**Risk if skipped:** Search index lost on every restart. OOMKill loop under normal load with multiple managed clusters.

---

## 2. Cluster Backup

**Default: disabled.** The `cluster-backup` component is explicitly off by default and must be enabled.

What it protects: managed cluster registrations, application subscriptions, policies, and hub configuration. Without it, a hub loss means manually re-importing every managed cluster and re-applying all policies and applications.

**Status check:**
```bash
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .spec.overrides.components[?(@.name=="cluster-backup")]}{.name}: {.enabled}{end}{"\n"}'
```

**Enable the component:**
```bash
oc patch MultiClusterHub multiclusterhub -n open-cluster-management \
  --type=json \
  -p='[{"op":"add","path":"/spec/overrides/components/-","value":{"name":"cluster-backup","enabled":true}}]'
```

**This is necessary but not sufficient.** The cluster-backup component installs OADP (OpenShift API for Data Protection). You must also configure a Velero backend with object storage (S3-compatible, Azure Blob, GCS) before backups actually run. Enabling the component without the storage backend leaves backup scheduled but not executing.

Reference: [ACM 2.16 — Business continuity](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/business_continuity/business-cont-overview)

**Risk if skipped:** Hub loss = full manual recovery of all managed cluster registrations, policies, and applications.

---

## 3. Infrastructure Nodes

**Default:** Hub components run on worker nodes, consuming OCP subscription quota.

The docs explicitly recommend infrastructure nodes for production to avoid charging OCP worker quota for ACM management workloads.

**Status check:**
```bash
# Do infra nodes exist?
oc get nodes -l node-role.kubernetes.io/infra

# Is the MCH scheduled to infra nodes?
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.spec.nodeSelector}{"\n"}'
```

**What it requires:**
- Infra nodes with `node-role.kubernetes.io/infra` label and `NoSchedule` taint
- MCH `spec.nodeSelector: node-role.kubernetes.io/infra: ""`
- OLM subscription updated with matching nodeSelector and toleration
- Add-ons updated via AddonDeploymentConfig

If ODF/Portworx CSI is in use, ensure CSI pods can also run on infra nodes.

Reference: [ACM 2.16 — Configuring infrastructure nodes](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/install/installing#config-infra-node-acm)

**Risk if skipped:** ACM pods count against OCP worker subscription quota. At scale this is a licensing and resource isolation concern, not an immediate operational failure.

---

## 4. Hub Availability Configuration

**Default: `High`** — each component gets `replicaCount: 2`. This is the correct default for production.

`Basic` (single replica) is only appropriate for SNO or dev environments.

**Status check:**
```bash
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='availabilityConfig: {.spec.availabilityConfig}{"\n"}'
# Blank output = High (the default). "Basic" needs changing.
```

If it shows `Basic`:
```bash
oc patch mch multiclusterhub -n open-cluster-management \
  --type=merge -p '{"spec":{"availabilityConfig":"High"}}'
```

**Risk if skipped (Basic on production):** Single replica per component — any pod failure takes the function offline until Kubernetes reschedules it.

---

## 5. OLM Subscription Approval

**Default: Automatic** — minor version updates apply without approval.

The docs recommend `Manual` for production so that updates are gated by a human notification.

**Status check:**
```bash
oc get subscription advanced-cluster-management \
  -n open-cluster-management \
  -o jsonpath='installPlanApproval: {.spec.installPlanApproval}{"\n"}'
```

If `Automatic` and you want manual control:
```bash
oc patch subscription advanced-cluster-management \
  -n open-cluster-management \
  --type=merge -p '{"spec":{"installPlanApproval":"Manual"}}'
```

Note: Minor updates (e.g., 2.16.1 → 2.16.2) come through the same channel. Major version upgrades always require a channel change regardless of this setting.

**Risk if skipped:** Patch updates apply automatically during the maintenance window OLM chooses, not yours.

---

## 6. Hub Node Sizing

From ACM 2.16 docs — minimum for a production hub (non-SNO):

| Requirement | Minimum |
|---|---|
| Worker/infra nodes | 3, across 3 availability zones |
| Reserved memory per node | 12 GB |
| Reserved CPU per node | 6 vCPU |
| Master nodes | 3, across 3 availability zones |

**Status check:**
```bash
# Node count and capacity
oc get nodes -o custom-columns='NAME:.metadata.name,ROLE:.metadata.labels.node-role\.kubernetes\.io/worker,CPU:.status.capacity.cpu,MEM:.status.capacity.memory,ZONE:.metadata.labels.topology\.kubernetes\.io/zone'

# Current resource usage on hub namespace
oc top pods -n open-cluster-management --sort-by=memory | head -20
```

**Risk if undersized:** Resource contention across hub components. The search OOMKill is a common symptom of an undersized hub, not just a misconfigured search service.

---

## 7. Observability (Multicluster Observability)

**Default: enabled in the MCH component list**, but functional observability requires a separate object storage backend.

Without object storage configured, the observability component runs but metrics are not persisted — no long-term visibility into managed cluster health.

**Status check:**
```bash
oc get multiclusterobservability observability \
  -n open-cluster-management 2>/dev/null || echo "not configured"

oc get pods -n open-cluster-management-observability 2>/dev/null | head -20
```

**What it requires:** An S3-compatible object store (AWS S3, MinIO, ODF/RADOS, Azure Blob, GCS) and a `MultiClusterObservability` CR with the storage config. Observability at scale needs its own infra nodes — the sizing table in the docs shows significant resource requirements for 100+ managed clusters.

Reference: [ACM 2.16 — Observability](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/observability)

**Risk if skipped:** No historical metrics from managed clusters. Alerts fire but there's no data to investigate trends.

---

## 8. FIPS Compliance (if required)

If your environment requires FIPS compliance, two SSL ciphers must be removed from the MCH before or during installation:

```bash
# Check current cipher list
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.spec.ingress.sslCiphers}{"\n"}'
```

Ciphers to remove: `ECDHE-ECDSA-CHACHA20-POLY1305` and `ECDHE-RSA-CHACHA20-POLY1305`.

This is a post-upgrade concern too — after a hub upgrade, verify these are not re-added to the default list.

---

## Summary — Effort vs. Risk

| Item | Production default | Setup effort | Risk if skipped |
|---|---|---|---|
| Search PVC | ❌ emptyDir | Low — one CR patch | OOMKill crash loop |
| Cluster backup | ❌ disabled | Medium — component + OADP storage backend | Hub loss = full manual recovery |
| Infra nodes | ❌ runs on workers | High — node provisioning + MCH/OLM reconfiguration | OCP subscription quota consumption |
| Availability config | ✅ High (default) | Verify only | Single pod failures take features offline |
| OLM approval | ❌ Automatic | Low — subscription patch | Uncontrolled patch update timing |
| Hub sizing | Depends on cluster | Verify only | Resource contention across hub components |
| Observability | Partial — component enabled, storage not configured | Medium — object storage + CR | No historical metrics from managed clusters |
| FIPS (if required) | ❌ non-compliant ciphers present | Low | Compliance gap |

**Recommended sequencing for a gap closure plan:**
1. Search PVC — already done
2. Cluster backup — highest risk gap; enable component and wire up OADP storage
3. OLM subscription to Manual — low effort, do alongside backup work
4. Observability object storage — if metrics are a requirement
5. Hub sizing validation — audit nodes, address if under spec
6. Infra nodes — plan for a maintenance window; MCH node selector change reschedules pods

---

## Related

- [search-setup.md](./search-setup.md) — search first-time setup and PVC config
- [search-service-503.md](../troubleshooting/search-service-503.md) — search 503 / OOMKill
- [networking-requirements-2.16.md](./networking-requirements-2.16.md) — hub-to-cluster port requirements

---

*This content was created with AI assistance and sourced from ACM 2.16 documentation. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

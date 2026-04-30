# ACM Observability: Platform Metrics Missing

---
**review:**
  status: unreviewed
  notes: |
    AI-generated troubleshooting guide documenting the root cause chain discovered 
    during session on 2026-04-30: Prometheus PVC full → TSDB write failures → 
    platform metric scrape targets fail → ACM hub dashboards show no platform metrics 
    while custom metrics continue flowing.
---

## Symptom

Your ACM Multicluster Observability hub is receiving **custom metrics** from managed clusters and they appear correctly in dashboards, but **platform metrics are completely absent** for one or more managed clusters:

- Missing metrics: CPU usage, memory utilization, node status, kubelet metrics, kube-state-metrics
- Custom application metrics continue to flow normally
- `ManagedClusterAddon` for observability exists and shows `Available` (not degraded)
- The managed cluster is reachable and responding to API requests
- Alert storm on the spoke cluster: `KubeAPIDown`, `KubeletDown`, `KubeControllerManagerDown`, and similar infrastructure alerts are firing

This scenario is **distinct from the addon-missing case** where no `ManagedClusterAddon` exists. Here, the addon is present and appears healthy, but Prometheus on the spoke cluster cannot persist scraped metrics due to storage exhaustion.

## How to Distinguish This From Actual Infrastructure Failure

The alerts firing (`KubeAPIDown`, `KubeletDown`, `KubeControllerManagerDown`) are the **same alerts that fire when cluster components genuinely fail**. The key distinguishing signals:

1. **Prometheus is running** — the pod is up and the alerts ARE firing (Prometheus can still write alert state to memory)
2. **Scrape targets show as down in Prometheus UI** — but the cluster is actually healthy
3. **External API access works** — running `oc get nodes` from outside the cluster succeeds, proving the API server is not actually down
4. **Custom metrics continue flowing** — if metrics-collector can forward custom metrics but not platform metrics, Prometheus is running but failing to persist platform scrapes

**Rule of thumb:** If Prometheus can fire alerts about infrastructure being down, but you can independently verify the infrastructure is up (API responds, nodes are Ready), suspect a Prometheus storage issue rather than actual component failure.

## Step 1: Check PVC Usage on the Spoke

Run these commands **on the managed cluster** (the spoke):

| Command | Purpose |
|---------|---------|
| `oc get pvc -n openshift-monitoring` | List all PVCs and their status |
| `oc exec -n openshift-monitoring prometheus-k8s-0 -- df -h /prometheus` | Check actual disk usage inside the Prometheus pod |

Example output showing the problem:

```
$ oc exec -n openshift-monitoring prometheus-k8s-0 -- df -h /prometheus
Filesystem      Size  Used Avail Use% Mounted on
/dev/rbd0        40G   40G     0 100% /prometheus
```

**If the Prometheus data volume is at or near 100% capacity, this is the root cause.** Full storage prevents TSDB from writing new samples, which causes all scrape attempts to fail.

## Step 2: Confirm TSDB Write Failures in Prometheus Logs

Verify the failure mode by examining Prometheus logs **on the spoke**:

| Command | Purpose |
|---------|---------|
| `oc logs -n openshift-monitoring prometheus-k8s-0 -c prometheus --since=2h \| grep -iE "tsdb\|no space\|write\|err"` | Search for TSDB errors and write failures |

Common log signatures indicating storage exhaustion:

- `level=error msg="opening storage failed" err="no space left on device"`
- `level=error msg="compaction failed" err="write /prometheus/...: no space left on device"`
- `level=error msg="WAL write failed"`
- `ts=... caller=db.go:... level=error msg="err opening chunk segment"`

These errors confirm that Prometheus cannot persist data due to full storage, even though scrape attempts continue.

## Step 3: Fix - Expand the PVC

OpenShift supports **online PVC expansion** for most storage classes (no pod restart required). Expand both Prometheus StatefulSet PVCs:

| Command | Purpose |
|---------|---------|
| `oc patch pvc prometheus-k8s-db-prometheus-k8s-0 -n openshift-monitoring -p '{"spec":{"resources":{"requests":{"storage":"<new-size>"}}}}'` | Expand prometheus-k8s-0 PVC |
| `oc patch pvc prometheus-k8s-db-prometheus-k8s-1 -n openshift-monitoring -p '{"spec":{"resources":{"requests":{"storage":"<new-size>"}}}}'` | Expand prometheus-k8s-1 PVC |

Example expanding from 40Gi to 80Gi:

```bash
oc patch pvc prometheus-k8s-db-prometheus-k8s-0 -n openshift-monitoring \
  -p '{"spec":{"resources":{"requests":{"storage":"80Gi"}}}}'

oc patch pvc prometheus-k8s-db-prometheus-k8s-1 -n openshift-monitoring \
  -p '{"spec":{"resources":{"requests":{"storage":"80Gi"}}}}'
```

**After expansion:**
- The underlying storage volume resizes automatically (storage class must support `allowVolumeExpansion: true`)
- Prometheus detects the new space and resumes writing samples
- Platform metrics begin flowing to ACM hub dashboards within minutes
- **No pod restart required** for online expansion

Verify expansion:

```bash
oc get pvc -n openshift-monitoring
oc exec -n openshift-monitoring prometheus-k8s-0 -- df -h /prometheus
```

## Step 4: Fix - Set Retention to Prevent Recurrence

Configure Prometheus retention limits via the `cluster-monitoring-config` ConfigMap to prevent the PVC from filling again.

| Command | Purpose |
|---------|---------|
| `oc edit configmap cluster-monitoring-config -n openshift-monitoring` | Edit cluster monitoring configuration |

If the ConfigMap doesn't exist, create it:

```bash
oc create configmap cluster-monitoring-config -n openshift-monitoring \
  --from-literal=config.yaml='enableUserWorkload: true'
```

Then edit to add retention settings:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    prometheusK8s:
      retention: 15d              # Time-based retention (stops accumulating beyond this window)
      retentionSize: 30GB         # Size-based hard cap (stops writing when reached)
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 80Gi       # PVC size (set higher than retentionSize)
```

**Recommended settings:**
- **`retention`** (time-based): `15d` to `30d` depending on observability requirements
- **`retentionSize`** (size-based): Set to ~60-75% of PVC size to leave headroom (e.g., `30GB` for a `40Gi` PVC, `60GB` for an `80Gi` PVC)
- **Both limits should be set** — Prometheus enforces whichever is reached first

After saving, Prometheus Operator applies the new configuration automatically (pods may restart).

## Prevention

**Recommended sizing guidance:**

- **Default behavior:** Prometheus defaults to 15 days retention with no size limit; OCP default PVC size varies by version (commonly 40Gi for 4.x clusters)
- **For active clusters** with many workloads, namespaces, or custom ServiceMonitors:
  - **PVC size:** 50-100Gi
  - **retentionSize:** 30-75GB (leave 20-25% headroom)
  - **retention:** 15-30d depending on debugging needs

**Set both `retention` and `retentionSize`** to prevent unbounded growth. Time-based retention alone won't protect against high-cardinality metrics filling storage before the time window expires.

**Monitoring best practices:**
- Alert on PVC usage before it reaches 85% (OpenShift includes `KubePersistentVolumeFillingUp` by default)
- Review retention settings when adding new ServiceMonitors or increasing cluster workload density
- Consider using Thanos or similar for long-term metric storage instead of extending Prometheus retention

**Reference:**
- [OpenShift Monitoring Configuration Docs](https://docs.openshift.com/container-platform/latest/monitoring/configuring-the-monitoring-stack.html)

## Quick Reference

| Check | Location | Command |
|-------|----------|---------|
| PVC usage | Spoke cluster | `oc get pvc -n openshift-monitoring` |
| Prometheus disk space | Spoke cluster | `oc exec -n openshift-monitoring prometheus-k8s-0 -- df -h /prometheus` |
| TSDB write errors | Spoke cluster | `oc logs -n openshift-monitoring prometheus-k8s-0 -c prometheus --since=2h \| grep -iE "tsdb\|no space"` |
| Expand PVC | Spoke cluster | `oc patch pvc prometheus-k8s-db-prometheus-k8s-0 -n openshift-monitoring -p '{"spec":{"resources":{"requests":{"storage":"80Gi"}}}}'` |
| Configure retention | Spoke cluster | `oc edit configmap cluster-monitoring-config -n openshift-monitoring` |
| ManagedClusterAddon status | Hub cluster | `oc get managedclusteraddon -A \| grep observability` |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

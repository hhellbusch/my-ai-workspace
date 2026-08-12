---
review:
  status: unreviewed
  notes: "Quick-stop reference for pod termination vs scale-to-zero; drafted from operational Q&A 2026-07-30."
---

# Pod Termination — Quick Stop vs Scale to Zero

> **Audience:** Operators who need to stop a set of processes quickly on OpenShift/Kubernetes — during incidents, maintenance, or load relief.
>
> **Purpose:** Compare `oc delete pod --grace-period=0` (with or without `--force`) to scaling a Deployment/ReplicaSet to zero, and choose the right sequence for the goal.

**Related:**

- [OpenShift useful commands](openshift-useful-commands.md) — force-delete one-liner for stuck pods
- [API slowness — scale down workloads](../troubleshooting/api-slowness-web-console/README.md#emergency-scale-down-workloads) — emergency cluster load relief
- [Namespace stuck terminating](../troubleshooting/namespace-stuck-terminating/README.md) — when `--force` is for API cleanup, not routine shutdown

---

## Two different intents

| Approach | What changes | Stops recreation? | Typical shutdown |
|----------|--------------|-------------------|------------------|
| `oc delete pod --grace-period=0` | Individual pod objects | **No** — controller recreates if desired replicas > 0 | Immediate (no grace wait) |
| `oc scale deployment --replicas=0` | Desired replica count on the controller | **Yes** | Normal SIGTERM → grace → SIGKILL |

**Rule of thumb:** force-delete kills *instances*; scale-to-zero stops the *workload*.
Using only force-delete on a managed Deployment often restarts one pod while leaving the workload "running."

---

## Normal delete vs grace-period=0

**Default delete** (`oc delete pod <name>`):

```
remove from Service endpoints → SIGTERM → wait (preStop + terminationGracePeriodSeconds) → SIGKILL
```

Default grace is 30 seconds unless the pod spec sets `terminationGracePeriodSeconds` or a `preStop` hook runs longer.

**`--grace-period=0`:**

```
remove from endpoints → SIGTERM → (no meaningful wait) → SIGKILL
```

The kubelet still sends SIGTERM first, but the grace window is effectively zero — containers die almost immediately.
`preStop` hooks are skipped.

### Is that like `kill -9`?

**Mostly yes** on a healthy node: `--grace-period=0` is the practical equivalent of "don't wait, kill it now."

Caveats:

| `kill -9` on the host | `delete --grace-period=0` |
|-----------------------|---------------------------|
| Signal goes directly to a PID | Signal path is API → kubelet → container runtime (CRI-O/containerd) |
| Process is targeted | All containers in the pod (app + sidecars) |
| Process dies or the kill fails visibly | **`--force`** can remove the API object even if the kubelet never confirmed kill — container may keep running on the node |

**`--force`** is mainly for pods **stuck in `Terminating`** — it forces API/etcd cleanup.
It is not a stronger kill signal.
On a healthy kubelet, `--grace-period=0` alone is usually enough for an immediate stop.

Modern `kubectl`/`oc` discourage `--force` for routine deletes; reserve it for stuck termination.

---

## Scale deployment to zero

```bash
oc scale deployment/<name> -n <namespace> --replicas=0
```

The Deployment controller terminates existing pods and sets desired state to zero — no replacements.

**Advantages:**

- Declarative — Deployment spec is preserved; scale back up when ready
- One command stops the whole replica set regardless of count
- Correct semantic for "stop this workload"

**Tradeoffs:**

- **Slower by default** — honors `terminationGracePeriodSeconds` and `preStop` unless you follow up with grace-period=0 deletes
- **PodDisruptionBudgets** can block or serialize scale-down
- **HorizontalPodAutoscaler** may scale back up — pause or remove the HPA first
- **Not universal** — DaemonSets don't scale this way; StatefulSets terminate in reverse ordinal order; bare Pods have no controller to scale

---

## Recommended sequences

### Stop a Deployment workload (keep it stopped)

```bash
# 1. Stop recreation
oc scale deployment/<name> -n <namespace> --replicas=0

# 2. Only if pods linger past acceptable wait
oc delete pod -l app=<label> -n <namespace> --grace-period=0
```

Document what you scaled down if this is incident response — restore replica count when the emergency passes.

### Maximum speed, graceful shutdown not required

```bash
oc scale deployment/<name> -n <namespace> --replicas=0
oc delete pod -l app=<label> -n <namespace> --grace-period=0 --wait=false
```

Scale first.
Without step 1, the controller replaces every pod you force-delete.

### Stuck pod in Terminating

```bash
oc delete pod <name> -n <namespace> --grace-period=0 --force
```

See [namespace stuck terminating](../troubleshooting/namespace-stuck-terminating/README.md) if finalizers or volume attachments block cleanup.

### Emergency API / cluster load relief

Scale non-critical workloads to zero rather than force-deleting individual pods.
See [API slowness — emergency scale down](../troubleshooting/api-slowness-web-console/README.md#emergency-scale-down-workloads).

---

## Controller-specific notes

| Controller | Quick-stop approach |
|------------|---------------------|
| **Deployment / ReplicaSet** | `oc scale deployment --replicas=0` |
| **StatefulSet** | `oc scale statefulset --replicas=0` (ordered termination — slower) |
| **DaemonSet** | Delete or cordon/drain node; no replica scale |
| **Job** | `oc delete job <name>` or let completion TTL handle it |
| **Bare Pod** (no owner) | `oc delete pod --grace-period=0` |
| **CronJob** | Suspend: `oc patch cronjob <name> -p '{"spec":{"suspend":true}}'` |

---

## Pre-flight checklist

Before a quick stop in production:

1. **HPA** — will it fight the scale-down?
2. **PDB** — will it block termination?
3. **Ingress / Service** — endpoint removal is fast but not instantaneous; in-flight requests may fail hard with grace-period=0
4. **Persistent volumes** — force-delete does not delete PVCs; StatefulSet scale-down retains PVCs by default
5. **Downstream consumers** — brokers, queues, and batch pipelines may need draining before a hard kill

---

## OCP version notes (4.18–4.22)

Runtime behavior for the patterns in this note is **the same across OCP 4.18, 4.20, 4.21, and 4.22** for typical Deployments and StatefulSets:

- `oc delete pod --grace-period=0` still sends SIGTERM before SIGKILL; grace is effectively zero.
- `oc scale … --replicas=0` still drives orderly termination via the workload controller.
- PDBs still gate **voluntary** evictions only (node drain, cluster upgrade), not node failure or `--grace-period=0` force-delete.

**Differences worth knowing:**

| Topic | 4.18–4.22 | What to check |
|-------|-----------|---------------|
| **Doc book layout** | Pod config and PDB content lives in *Nodes → Working with pods*; `terminationGracePeriodSeconds` is in *Workloads APIs → Pod [v1]*. Older `workloads/deployments` pod-lifecycle anchors are stale — do not copy them. | Pin links to your cluster minor (table below). |
| **Sidecar containers** (restartable init) | Available OCP 4.15+; stable from **4.16** (K8s 1.29+). Pods with sidecars terminate **main containers first**, then sidecars — a hard delete may look slower than a single-container pod. | `oc get pod -o yaml` — look for `restartPolicy: Always` on init containers. |
| **`kubectl` / `oc delete --force`** | Warnings against routine `--force` have strengthened; behavior for stuck `Terminating` pods is unchanged — API object removal, not a stronger kill signal. | Reserve `--force` for API cleanup; see [namespace stuck terminating](../troubleshooting/namespace-stuck-terminating/README.md). |
| **PDB API** | `policy/v1` `PodDisruptionBudget` only — no version-specific PDB schema change in this range. | `oc get pdb -A` before drain or upgrade. |

No OCP minor in this range changes the **scale-to-zero vs force-delete** decision tree above.

---

## References

Pin Red Hat doc links to the minor running on your cluster. All paths below verified for 4.18–4.22.

| OCP | Working with pods (restart, PDB) | Pod [v1] API (`terminationGracePeriodSeconds`, `preStop`) |
|-----|----------------------------------|-----------------------------------------------------------|
| **4.18** | [Nodes — Working with pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/nodes/working-with-pods) — §2.3 restart policy; §2.3.3 PDB | [Pod [v1]](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/workloads_apis/pod-v1) |
| **4.20** | [Nodes — Working with pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/nodes/working-with-pods) | [Pod [v1]](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/workloads_apis/pod-v1) |
| **4.21** | [Nodes — Working with pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/nodes/working-with-pods) | [Pod [v1]](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/workloads_apis/pod-v1) |
| **4.22** | [Nodes — Working with pods](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/nodes/working-with-pods) | [Pod [v1]](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/workloads_apis/pod-v1) |

**Deep links (same anchor IDs on 4.18–4.22):**

- PDB overview — `…/nodes/working-with-pods#nodes-pods-pod-distruption-about_nodes-pods-configuring` (Red Hat typo: *distruption*)
- Restart policy — `…/nodes/working-with-pods#nodes-pods-configuring-restart_nodes-pods-configuring`

Example for OCP 4.20 PDB section: [Understanding pod disruption budgets](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/nodes/working-with-pods#nodes-pods-pod-distruption-about_nodes-pods-configuring) — §2.3.3, *Nodes*

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

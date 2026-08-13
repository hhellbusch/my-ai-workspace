---
review:
  status: unreviewed
  notes: "GitOps patterns for Cluster Link management — CRD vs API reconcile; validate against installed CFK version."
---

# Cluster Link GitOps — CRD vs API reconcile patterns

**Audience:** The Kafka/platform team operating CFK via Argo CD who need the **cluster link** (not just brokers) defined in version control and kept in sync.

**Purpose:** Document **both** management approaches — native `ClusterLink` CRD and **API/CLI reconcile** (including Argo-driven Jobs) — so the team can choose or combine them after validating what their CFK version actually exposes.

**Related:** [Cross-DC Cluster Linking](cross-dc-cluster-linking.md) · [BROKER-IPAM.md](cross-dc-kafka-net-helm/BROKER-IPAM.md) · [Cross-DC rollout inventory](../../networking/cross-dc-rollout/README.md) · [Confluent: ClusterLink CRD](https://docs.confluent.io/operator/current/co-link-clusters.html) · [Argo CD multi-cluster](../../../../argo/examples/docs/deployment/multi-cluster-deployment.md)

---

## On this page

- [Why this doc exists](#why-this-doc-exists)
- [CRD vs API — what we know](#crd-vs-api--what-we-know)
- [Gap discovery checklist](#gap-discovery-checklist)
- [Decision matrix](#decision-matrix)
- [Pattern A — ClusterLink CRD + Argo CD](#pattern-a--clusterlink-crd--argo-cd)
- [Pattern B — Declarative spec in Git + reconcile Job](#pattern-b--declarative-spec-in-git--reconcile-job)
- [Pattern C — Argo PostSync / Sync hook Job](#pattern-c--argo-postsync--sync-hook-job)
- [Pattern D — CronJob drift detection](#pattern-d--cronjob-drift-detection)
- [Pattern E — External CI pipeline](#pattern-e--external-ci-pipeline)
- [Pattern F — Hybrid (CRD steady state, API break-glass)](#pattern-f--hybrid-crd-steady-state-api-break-glass)
- [Pattern G — Long-running reconciler Deployment](#pattern-g--long-running-reconciler-deployment)
- [Anti-patterns](#anti-patterns)
- [Suggested repo layout](#suggested-repo-layout)
- [GitOps maturity ladder](#gitops-maturity-ladder)
- [Open questions for the Kafka team](#open-questions-for-the-kafka-team)

---

## Why this doc exists

[Cross-DC Cluster Linking](cross-dc-cluster-linking.md) originally assumed links would be created via **Control Center or REST API** because that was the operational plan at design time — and because peers sometimes report the **`ClusterLink` CRD does not expose every link setting** they need.

CFK **does** ship a [`ClusterLink` CRD](https://docs.confluent.io/operator/current/co-link-clusters.html) with mirror topics, ACL/consumer filters, auth, and bidirectional modes — but **your installed CFK/CP versions and required link options must be validated** before picking an approach.

This doc compares GitOps patterns so Argo-managed clusters can still treat links as **desired state in Git**, whether that state becomes a CR or drives an API reconcile script.

---

## CRD vs API — what we know

### What the ClusterLink CRD covers (per Confluent docs)

Typical declarative fields:

- Link name, source/destination cluster references
- **`bootstrapEndpoint`** toward the remote cluster (must reach **REPLICATION** addresses in this design — not internal Service DNS)
- TLS, SASL/PLAIN, mTLS, OAuth auth blocks (PEM secrets)
- **`mirrorTopics`**, **`mirrorTopicOptions`** (prefix, auto-create)
- **`aclFilter`**, **`consumerGroupFilters`**
- Bidirectional mode (two CRs, same `spec.name`; CFK 3.2+ / CP 7.5+)
- Source-initiated vs destination-initiated link modes

CFK reconciles CRs periodically (~5 minutes by default) and requires **Admin REST / `KafkaRestClass`** on participating clusters.

### Documented CRD limitations / caveats

| Topic | Implication |
|---|---|
| **Mirror topics created outside CFK** (CLI/REST only) | CFK may **delete** them on operator restart if a `ClusterLink` CR also manages the same link — **do not mix** CRD and ad hoc API for the same link |
| **Cluster Linking with a proxy** | Not supported in CFK |
| **TLS rotation** | Not dynamic; updates apply on next reconcile cycle |
| **Bidirectional in CR** | Needs CFK 3.2+ / CP 7.5+; else maintain bidirectional links via API/CLI |
| **Confluent examples** | Often show `bootstrapEndpoint: kafka….svc:9092` — **wrong for this architecture**; use Multus REPLICATION IPs ([BROKER-IPAM](cross-dc-kafka-net-helm/BROKER-IPAM.md)) |

### Why a team might still choose API/CLI reconcile

Common reasons (confirm which apply locally):

- Required link/mirror settings **not in CRD schema** for your CFK version
- **`reverse-and-start` / `reverse-and-pause`** and other **operational** commands treated as runbooks, not steady-state spec
- Link to **non-CFK** Kafka with connection shapes the CRD doesn't model
- Historical links created in Control Center; migration risk to CRD ownership
- Org policy: only platform CI may call Admin REST, not CFK operator reconcile

**Action:** run the [gap discovery checklist](#gap-discovery-checklist) and record results in [Open questions](#open-questions-for-the-kafka-team).

---

## Gap discovery checklist

Before choosing Pattern A vs B, on a **non-production** cluster pair:

1. `oc get crd clusterlinks.platform.confluent.io -o yaml` — CRD present?
2. `oc explain clusterlink.spec` — compare fields to your link design (auth, mirror options, bidirectional, filters)
3. Export a **working link** created via CLI/Control Center; map each JSON field to CRD `spec` or mark **API-only**
4. Test **bidirectional pre-staged** shape: two CRs vs two API links — matches [cluster-linking design](cross-dc-cluster-linking.md#bidirectional-pre-staged-links-for-failover)?
5. Confirm **`bootstrapEndpoint`** accepts comma-separated REPLICATION `host:9095` list (Multus IPs)
6. Confirm **`KafkaRestClass`** / Admin REST reachable from CFK operator (in-cluster — management network, not replication VLAN)
7. If any required field is API-only → Pattern B or hybrid; if fully mappable → Pattern A

---

## Decision matrix

| Criterion | Pattern A — `ClusterLink` CR | Pattern B — Git spec + reconcile Job |
|---|---|---|
| GitOps native (Argo diff on CR) | Strong | Weaker (Job logs + optional drift check) |
| CFK operator owns reconcile | Yes | No — your script |
| Full link feature surface | Bounded by CRD schema | Bounded by REST/CLI (often wider) |
| Mix with manual Control Center | Risky — CRD may delete external mirrors | Easier if script is source of truth |
| Bootstrap from inventory | Template into CR YAML | Same spec file consumed by script |
| Failover ops (`reverse-and-start`) | Update CR or runbook | Script or runbook |
| Argo CD fit | Same as other CFK CRs | Job/CronJob in same Application |

**Default recommendation:** Pattern A if gap checklist passes; Pattern B (or hybrid) if not.

---

## Pattern A — ClusterLink CRD + Argo CD

**Shape:** link definition is a `ClusterLink` manifest in the Kafka team's Git repo; Argo CD Application syncs it to the **destination** cluster (and source cluster too for source-initiated / bidirectional).

```text
git: clusters/dc-b/confluent/clusterlink-from-dc-a.yaml
  → Argo Application (dc-b)
  → CFK reconciles ClusterLink
  → broker replication on net1 (already deployed)
```

**Multi-cluster:** one Application per cluster (ACM or cluster-specific Argo instances) — same model as [multi-cluster deployment](../../../../argo/examples/docs/deployment/multi-cluster-deployment.md).

**Sync ordering:** use Argo **sync waves** so `Kafka` CR + Multus NAD land before `ClusterLink`:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "20"   # after Kafka wave "10"
```

**Bootstrap list:** render from inventory static `replIp` rows ([BROKER-IPAM](cross-dc-kafka-net-helm/BROKER-IPAM.md#end-to-end-lifecycle-static)) or generated artifact post-broker-deploy.

**Secrets:** TLS/SASL via Kubernetes Secrets; reference from CR — not plain text in Git.

---

## Pattern B — Declarative spec in Git + reconcile Job

**Shape:** Git holds a **versioned link spec** (YAML/JSON — your schema, not necessarily a CR). An **idempotent script** (`confluent kafka link …` or REST) applies desired state. A **Kubernetes Job** (or CronJob) runs the script inside the cluster near Admin REST.

```text
git: cluster-links/dc-b/link-from-dc-a.desired.yaml
     cluster-links/scripts/reconcile-link.sh
  → ConfigMap/Volume from git (or init container clone)
  → Job runs reconcile-link.sh --file link-from-dc-a.desired.yaml
  → Admin REST / CLI → link created or updated
```

**Why Kafka teams like this on Argo CD:**

- Same repo and Application as CFK `Kafka` CRs
- Script can call settings **not in CRD** once identified
- Argo still tracks the **spec + script** in Git even if live link isn't a CR

**Job sketch:**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: reconcile-clusterlink-dc-a-to-dc-b
  annotations:
    argocd.argoproj.io/hook: Sync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: clusterlink-reconciler
      containers:
        - name: reconcile
          image: <your-image-with-confluent-cli>
          command: ["/scripts/reconcile-link.sh", "--spec", "/config/link.desired.yaml"]
          envFrom:
            - secretRef:
                name: clusterlink-admin-credentials
          volumeMounts:
            - name: spec
              mountPath: /config
      volumes:
        - name: spec
          configMap:
            name: clusterlink-dc-a-to-dc-b-spec
```

**Script requirements:**

- **Idempotent** — create if missing, update if spec drifted, no-op if matched
- **Exit non-zero** on failure so Argo marks sync failed
- **`bootstrap.servers`** built from REPLICATION addresses only
- **Dry-run / `--check-only`** mode for CronJob drift alerts

**ServiceAccount:** minimal RBAC — only needs to reach Admin REST (in-cluster Service) or exec pattern your platform allows; not cluster-admin.

---

## Pattern C — Argo PostSync / Sync hook Job

Same as Pattern B, but Job runs as an **Argo sync hook** after manifests apply — good when link must exist **only after** brokers pass readiness.

| Hook | Use when |
|---|---|
| `Sync` + `BeforeHookCreation` | Re-run reconcile every sync (ensure convergence) |
| `PostSync` | Kafka/NAD applied first in same Application |

Combine with **sync waves**: wave 10 Kafka, wave 20 NAD/policy, wave 30 link Job.

**Caution:** running a reconcile Job on **every** Argo sync can be noisy — gate with script no-op or use CronJob (Pattern D) for drift only.

---

## Pattern D — CronJob drift detection

**Steady state:** link created once (CR or Job). **CronJob** hourly/daily:

```bash
reconcile-link.sh --spec /config/link.desired.yaml --check-only
```

Fails → alert / Argo degraded / ticket. Optional `--apply` on scheduled reconcile for API-only management.

Useful when links change rarely but **drift from manual Control Center edits** must be caught.

---

## Pattern E — External CI pipeline

Git spec + reconcile script run from **GitHub Actions / GitLab CI** (outside cluster):

- CI has kubeconfig or REST endpoint reachability to Admin API
- `terraform plan`-style: PR shows link diff; merge applies

**Pros:** no Job RBAC in cluster; familiar pipeline reviews  
**Cons:** CI must reach both DCs' Admin endpoints; secrets in CI vault; not "pure" in-cluster GitOps

Fits if Kafka team already uses CI for topic provisioning ([Confluent blog — CFK GitOps](https://www.confluent.io/blog/resource-management-with-confluent-for-kubernetes/)).

---

## Pattern F — Hybrid (CRD steady state, API break-glass)

| Concern | Owner |
|---|---|
| Link definition, mirror topics, filters | `ClusterLink` CR (Pattern A) |
| Failover `reverse-and-start`, emergency pause | Documented runbook + API/CLI (not in Git) |
| Settings CRD lacks | Either escalate to Pattern B for that field, or patch CR when CFK adds support |

**Do not** create mirror topics via API while a `ClusterLink` CR manages the same link — CFK may delete them ([Confluent warning](https://docs.confluent.io/operator/current/co-link-clusters.html)).

---

## Pattern G — Long-running reconciler Deployment

Lightweight **Deployment** (not Job) running a loop:

```text
while true; do reconcile-link.sh --apply; sleep 300; done
```

Similar to CFK's 5-minute CR reconcile, but **your** logic and API surface. Heavier operationally than Job+CronJob unless you already run a custom operator framework.

Consider only if Jobs are insufficient (e.g. continuous offset/link health remediation).

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Link only in Control Center UI | No reproducibility at failover |
| **`bootstrapEndpoint` on internal Service or Route** | Wrong network path — see [routes trap](cross-dc-cluster-linking.md#the-routes-trap) |
| **Mix CRD + API** mirror management on same link | CFK may delete API-created mirrors |
| Job with cluster-admin SA | Unnecessary blast radius |
| Reconcile Job before brokers + REPLICATION listener ready | Link creates but replication never works |
| Storing TLS keys in Git | Use Secrets / ESO / Vault |

---

## Suggested repo layout

Alongside existing rollout artifacts:

```text
devops/ocp/examples/messaging/kafka/
  cross-dc-cluster-linking.md          # design (listeners, network)
  CLUSTER-LINK-GITOPS.md               # this file
  cluster-link-gitops/                 # example scaffold — see README
    README.md
    desired/
    scripts/
    crd/
    k8s/
    argo/
```

Render **`bootstrapEndpoint`** from [rollout inventory](../../networking/cross-dc-rollout/inventory-dc-a.example.yaml) — [render-bootstrap-from-inventory.example.sh](cluster-link-gitops/scripts/render-bootstrap-from-inventory.example.sh) for static mode, or post-broker artifact for whereabouts.

**Scaffold:** [cluster-link-gitops/README.md](cluster-link-gitops/README.md) — desired specs, reconcile script, CR examples, Job + Argo wiring, and [GitOps maturity ladder](cluster-link-gitops/README.md#gitops-maturity-ladder-cluster-links).

---

## GitOps maturity ladder

| Level | Cluster link posture | Pattern |
|---|---|---|
| 0 | Control Center UI only | Anti-pattern |
| 1 | Script in Git, manual run | E (partial) |
| 2 | Declarative `desired/*.yaml` + reconcile script | B |
| 3 | Argo sync hook Job after Kafka/NAD | B + C |
| 4 | Native `ClusterLink` CR | A |
| 5 | Scheduled drift check (`--check-only`) | D |

See [cluster-link-gitops/README.md](cluster-link-gitops/README.md#gitops-maturity-ladder-cluster-links) for detail.

---

## Open questions for the Kafka team

Fill this in after the gap checklist — it drives Pattern A vs B.

| # | Question | Answer |
|---|---|---|
| 1 | CFK / CP versions on both clusters? | |
| 2 | Which link settings are **required** but **missing** from `ClusterLink` CRD? | |
| 3 | Bidirectional: two CRs, two API links, or `reverse-and-start` for failback? | |
| 4 | Who owns Argo Applications — one per DC or ACM hub? | |
| 5 | Admin REST / `KafkaRestClass` already deployed? | |
| 6 | Static vs whereabouts broker IPs for bootstrap list stability? | |
| 7 | Accept CFK owning link lifecycle (CRD), or must API script remain source of truth? | |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

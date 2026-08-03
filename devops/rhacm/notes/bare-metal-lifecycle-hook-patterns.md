---
review:
  status: unreviewed
  notes: "AI-generated 2026-08-03. Synthesizes ClusterCurator API (v1beta1), AAP integration, Go alternatives, and workspace bare-metal examples. Not validated against a live hub in this environment."
---

# Bare Metal Lifecycle Hook Patterns — AAP, ClusterCurator, and Go

> **Audience:** Platform engineers implementing preflight validation, BMC discovery, and `BareMetalHost` automation around ACM-provisioned clusters.
> **Purpose:** Compare implementation patterns with enough detail to choose one, wire it up, and understand tradeoffs — including when Ansible is required and when Go or other runtimes fit better.

---

## How this relates to other notes

| Doc | Role |
|-----|------|
| [agent-install-preflight.md](./agent-install-preflight.md) | **When** in the lifecycle to run checks (timing map) |
| [acm-ansible-integration.md](./acm-ansible-integration.md) | **Native ACM→AAP** wiring (Resource Operator, four integration paths) |
| [greenfield-fleet-architecture.md](./greenfield-fleet-architecture.md) | **Fleet-wide** default stack and phased adoption |
| This doc | **How** to implement hooks — AAP, Go, operators, CI — with examples |

---

## The two decisions

### 1. Timing — when does automation run?

```text
[A] Before hub CRs exist     → external pipeline (inventory → render YAML → apply/Git)
[B] Before install activates → ClusterCurator prehook OR operator on paused ClusterDeployment
[C] After ISO boot           → Assisted Installer validations + Agent approval gate
[D] After cluster is up      → ClusterCurator posthook, GitOps, Tekton
```

See the lifecycle diagram in [agent-install-preflight.md](./agent-install-preflight.md).

### 2. Runtime — what executes the logic?

| Runtime | Invoked by ClusterCurator `prehook` natively? |
|---------|-----------------------------------------------|
| AAP / AWX Job Template | **Yes** — primary supported path |
| AAP Workflow Template | **Yes** — `Hook.type: Workflow` |
| Go (or any binary) in K8s Job | **No** — via `overrideJob`, external operator, or CI |
| Go inside AAP Execution Environment | **Indirect** — Ansible launches the binary |
| `ansible-core` without controller | **No** — not wired to Curator |

ClusterCurator `Hook.type` values `Job` and `Workflow` refer to **Ansible** template types, not Kubernetes Jobs ([clustercurator_types.go](https://github.com/stolostron/cluster-curator-controller/blob/main/pkg/api/v1beta1/clustercurator_types.go)).

---

## Pattern comparison matrix

| Pattern | Best for | AAP required? | Curator required? | Support / docs | Complexity |
|---------|----------|---------------|-------------------|----------------|------------|
| **P1** External render pipeline | BMH discovery before CRs | Optional | No | Community / your runbooks | Medium |
| **P2** ClusterCurator + AAP prehook | Day-0 site checks at install gate | **Yes** (or AWX) | Yes | **Red Hat primary** | Medium |
| **P3** Thin Ansible → Go binary in EE | Same timing as P2, Go implementation | Yes | Yes | Hybrid | Medium |
| **P4** `overrideJob` + Go container | Full custom curator flow | No | Yes | Advanced / BYO | High |
| **P5** Operator on paused `ClusterDeployment` | Go-first, no AAP | No | No | BYO | High (build operator) |
| **P6** CI / Tekton on Git apply | Pre-apply validation, render | No | No | Common GitOps | Low–medium |
| **P7** Agent approval watcher | Post-discovery per-host gate | Optional | No | Common | Medium |

---

## Pattern P1 — External pipeline (discover → render → apply)

**Use when:** Redfish/inventory discovery must complete **before** `ClusterDeployment`, `InfraEnv`, or `BareMetalHost` objects exist on the hub.

### Flow

```text
Site inventory (CSV, CMDB, AAP inventory)
    → discover (Redfish / IPMI)
    → validate (CPU, RAM, NIC count, firmware)
    → render Jinja or Go templates
    → commit to Git OR kubectl apply on hub
    → bundle includes paused ClusterDeployment + ClusterCurator (optional)
```

### Example — Ansible render (from library pattern)

Aligns with [Automate OCP cluster deployment with RHACM and AAP](../../../library/automate-ocp-cluster-deployment-rhacm-aap.md): Jinja templates emit `AgentClusterInstall`, `InfraEnv`, `ClusterDeployment`, and optionally `ClusterCurator`.

```yaml
# Rendered fragment — BareMetalHost for Metal3/IPI path (illustrative)
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: worker-0
  namespace: openshift-machine-api
spec:
  online: true
  bmc:
    address: redfish+https://bmc-worker-0.example.com
    credentialsName: bmc-worker-0
  bootMACAddress: "aa:bb:cc:dd:ee:01"
```

Playbook outline:

```yaml
- hosts: bmc_hosts
  tasks:
    - name: Redfish system inventory
      community.general.idrac_redfish_info:
        baseuri: "{{ redfish_host }}"
        username: "{{ vault_bmc_user }}"
        password: "{{ vault_bmc_pass }}"
      register: hw

- hosts: localhost
  tasks:
    - name: Render and apply manifests
      kubernetes.core.k8s:
        kubeconfig: "{{ hub_kubeconfig }}"
        state: present
        definition: "{{ lookup('template', 'cluster-bundle.yaml.j2') }}"
```

### Example — Go CLI (same role)

```go
// Pseudocode — bm-render apply --site dc-east --inventory hosts.yaml
inv := loadInventory("hosts.yaml")
for _, host := range inv.Hosts {
    sys, err := redfish.GetSystem(ctx, host.BMC)
    if err != nil { fail(host.Name, err) }
    if sys.MemoryGiB < 64 { fail(host.Name, "insufficient RAM") }
    objs = append(objs, renderBMH(host, sys))
}
applyToHub(ctx, hubRestConfig, objs)
applyToHub(ctx, hubRestConfig, renderClusterBundle(site))
```

### Pros

- Natural place for **BMH / BareMetalAsset** creation from BMC discovery
- Fails **before** the hub starts provisioning — no partial cluster state
- Language choice is yours (Go, Ansible, Python)
- Fits GitOps: rendered manifests reviewed in PR

### Cons

- Not triggered by ClusterCurator — separate pipeline to maintain
- Two systems of record if inventory and Git drift
- You implement idempotency and secret handling

### Learn from in this repo

- [CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md](../examples/CLUSTER-IMPORT-AUTOMATION-STRATEGIES.md) — external orchestration framing
- [bare-metal-dev-sandbox preflight_validate](../../bare-metal-dev-sandbox/roles/preflight_validate/tasks/main.yml) — BMC and firewall checks to reuse
- [BARE-METAL-OPERATOR-INTEGRATION.md](../examples/BARE-METAL-OPERATOR-INTEGRATION.md) — `BareMetalAsset` / workflow 1

---

## Pattern P2 — ClusterCurator + AAP install prehook

**Use when:** Site-level checks must run **after** cluster CRs exist on the hub but **before** Assisted Installer / Hive activates provisioning.

### Prerequisites

1. [AAP Resource Operator — create custom resources](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-con_create_crs_resource_operator) on hub
2. Job template `bm-preflight-day0` with **Prompt on launch → Extra Variables**
3. Secret `aap-credentials` in cluster namespace
4. `ClusterDeployment` with `hive.openshift.io/reconcile-pause: "true"`

### Hub bundle example

```yaml
apiVersion: hive.openshift.io/v1
kind: ClusterDeployment
metadata:
  name: prod-bm-01
  namespace: prod-bm-01
  annotations:
    hive.openshift.io/reconcile-pause: "true"
spec:
  # ... platform, pull secret, cluster metadata ...
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: ClusterCurator
metadata:
  name: prod-bm-01
  namespace: prod-bm-01
spec:
  desiredCuration: install
  install:
    towerAuthSecret: aap-credentials
    prehook:
      - name: bm-preflight-day0
        extra_vars:
          cluster_name: prod-bm-01
          site: dc-east
          check_dns: true
          check_mirror: true
          check_firewall_matrix: true
    posthook:
      - name: set-ocm-subscription
        extra_vars:
          cluster_name: prod-bm-01
```

### Example playbook (`bm-preflight-day0`)

Runs on `localhost` with hub kubeconfig (AAP credential or in-cluster SA):

```yaml
---
- name: Day-0 preflight before Assisted Installer activates
  hosts: localhost
  gather_facts: false
  vars:
    cluster_name: "{{ cluster_name }}"
    assisted_ns: multicluster-engine

  tasks:
    - name: Assisted installer pods healthy
      kubernetes.core.k8s_info:
        kind: Pod
        namespace: "{{ assisted_ns }}"
        label_selectors:
          - app in (assisted-service, assisted-image-service)
      register: assisted_pods
      failed_when: assisted_pods.resources | selectattr('status.phase', 'equalto', 'Running') | list | length == 0

    - name: DNS — API record resolves
      ansible.builtin.command:
        argv: ["dig", "+short", "api.{{ cluster_name }}.example.com"]
      register: api_dns
      failed_when: api_dns.stdout | trim == ""

    - name: Hub mirror osImages present (disconnected)
      when: check_mirror | default(false) | bool
      kubernetes.core.k8s_info:
        api_version: agent-install.openshift.io/v1beta1
        kind: AgentServiceConfig
      register: asc
      failed_when: asc.resources | length == 0

    - name: BMC spot-check from site inventory
      ansible.builtin.include_tasks: check_bmc_batch.yml
      vars:
        bmc_hosts: "{{ lookup('file', '/runner/site/' + site + '/bmc.yaml') | from_yaml }}"
```

Curator injects `cluster_deployment` and `machine_pool` into `extra_vars` automatically — use `cluster_deployment.clusterName` in templates.

### Curator sequence

```text
prehook AnsibleJob (bm-preflight-day0)
    → activate-and-monitor (clears pause, watches install)
    → Assisted Installer / agents
    → posthook AnsibleJob (optional)
```

### Pros

- **Supported** Red Hat integration path
- Visible in ACM console (`ClusterCurator` status, `AnsibleJob` objects)
- Blocks install until prehook succeeds
- Reuses existing AAP RBAC, audit, job history

### Cons

- Requires AAP/AWX + Resource Operator
- Prehook runs **before** agents exist — cannot validate post-ISO hardware detail
- Job templates must allow extra var override (common gotcha)
- **Does not** replace P1 for full BMH discovery unless BMH already applied

### Audit commands

```bash
oc get clustercurator -n prod-bm-01 -o yaml
oc get ansiblejob -n prod-bm-01
oc logs job/$(oc get clustercurator -n prod-bm-01 -o jsonpath='{.spec.curatorJob}') -n prod-bm-01 -c prehook-ansiblejob
```

### Learn from in this repo

- [cluster-curator/README.md](../examples/ocm-subscription-automation/cluster-curator/README.md)
- [acm-ansible-integration.md](./acm-ansible-integration.md)
- [acm-bare-metal-network-requirements.md](./acm-bare-metal-network-requirements.md)

---

## Pattern P3 — Thin Ansible wrapper around a Go binary

**Use when:** You want **P2 timing and ACM visibility** but prefer **Go** for BMC logic, validation, and CR patching.

### Architecture

```text
ClusterCurator prehook
    → AnsibleJob → AAP Job Template
        → playbook: command: /usr/local/bin/bm-preflight
        → custom Execution Environment image (Go binary + CA certs + kubeconfig mount)
```

### Execution Environment

```dockerfile
# Containerfile — illustrative
FROM registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel8
COPY bm-preflight /usr/local/bin/bm-preflight
USER 1000
```

### Minimal playbook

```yaml
---
- hosts: localhost
  gather_facts: false
  tasks:
    - name: Run Go preflight
      ansible.builtin.command:
        argv:
          - /usr/local/bin/bm-preflight
          - --cluster-name
          - "{{ cluster_deployment.clusterName }}"
          - --namespace
          - "{{ cluster_deployment.clusterName }}"
          - --site
          - "{{ site | default('default') }}"
      environment:
        KUBECONFIG: /runner/kubeconfig/hub
      register: preflight
      failed_when: preflight.rc != 0
```

Pass `site` via Curator `extra_vars` as in P2.

### Go binary responsibilities (example flags)

```text
bm-preflight \
  --cluster-name prod-bm-01 \
  --namespace prod-bm-01 \
  --site dc-east \
  --apply-bmh=false          # true only on Metal3 path when BMH not yet applied
```

Typical checks inside Go:

- Parse `ClusterDeployment` / `AgentClusterInstall` from hub API
- DNS lookups for API/ingress/apps wildcard
- Redfish batch from site config
- Optional: patch `BareMetalHost` objects if `apply-bmh=true`

### Pros

- Curator + AAP orchestration **unchanged**
- Go for complex logic; Ansible only as launcher
- Single binary testable locally without hub
- Team can standardize on one EE image per release

### Cons

- Still need AAP licensing/ops (unless AWX)
- Two artifacts to version (EE image + playbook)
- Debugging spans AAP UI and binary logs
- `cluster_deployment` shape is Ansible-passed — binary should accept explicit flags, not depend on env JSON unless documented

### When to choose P3 over P2

Choose P3 when playbook complexity would grow unwieldy (many Redfish calls, structured validation, generated patches). Keep P2 when checks are a handful of `kubernetes.core` and `dig` tasks.

---

## Pattern P4 — `install.overrideJob` (custom curator Job)

**Use when:** You need a **fully custom** curator job — for example Go init containers — and accept owning the entire flow.

### API field

```yaml
spec:
  install:
    overrideJob:
      apiVersion: batch/v1
      kind: Job
      spec:
        template:
          spec:
            restartPolicy: Never
            serviceAccountName: cluster-curator-custom
            initContainers:
              - name: go-preflight
                image: quay.io/myorg/bm-preflight:v1.2.0
                env:
                  - name: CLUSTER_NAMESPACE
                    valueFrom:
                      fieldRef:
                        fieldPath: metadata.namespace
                volumeMounts:
                  - name: hub-kubeconfig
                    mountPath: /etc/kubeconfig
                    readOnly: true
              - name: activate-and-monitor
                # You must supply equivalent logic OR unpause CD in go-preflight
                # Illustrative only — pin the image shipped with your ACM/MCE version, not :latest
                image: quay.io/stolostron/cluster-curator-controller:<acm-version-tag>
                # ... upstream curator image init container pattern ...
            containers:
              - name: complete
                image: registry.access.redhat.com/ubi9/ubi-minimal
                command: ["true"]
```

**Warning:** `overrideJob` **replaces** the default job (`prehook-ansiblejob` → `activate-and-monitor` → `posthook-ansiblejob`). You must either:

- Replicate `activate-and-monitor` behavior (unpause `ClusterDeployment`, watch provisioning), or
- Perform unpause inside your Go container and exit only when safe

This pattern is for teams willing to read [cluster-curator-controller](https://github.com/stolostron/cluster-curator-controller) job templates and own upgrades.

### Pros

- No AAP dependency for hook execution
- Any language in container
- Full control of job graph

### Cons

- **Highest** operational burden
- Easy to break provisioning if unpause/monitor is wrong
- Not the documented happy path — test on every ACM/MCE upgrade
- Loses AAP audit unless you add it yourself

### Learning exercise

1. Deploy a test cluster with `reconcile-pause` only — no Curator.
2. Run your Go Job manually; verify it can unpause CD and watch `AgentClusterInstall` status.
3. Only then embed in `overrideJob`.

---

## Pattern P5 — Go operator on paused `ClusterDeployment`

**Use when:** Go is the primary platform language and you **do not** want AAP or Curator.

### Flow

```text
Git applies ClusterDeployment (reconcile-pause: true) + install CRs
    → Operator sees CD with pause annotation
    → Creates Job OR runs in-controller checks
    → On success: removes reconcile-pause annotation
    → Hive / Assisted Installer proceeds
```

### Reconcile pseudocode

```go
func (r *PreflightReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    cd := &hivev1.ClusterDeployment{}
    if err := r.Get(ctx, req.NamespacedName, cd); err != nil { return ctrl.Result{}, client.IgnoreNotFound(err) }

    paused := cd.Annotations["hive.openshift.io/reconcile-pause"] == "true"
    if !paused { return ctrl.Result{}, nil }

    if err := r.runPreflight(ctx, cd); err != nil {
        r.Recorder.Event(cd, "Warning", "PreflightFailed", err.Error())
        return ctrl.Result{RequeueAfter: 5 * time.Minute}, nil
    }
    delete(cd.Annotations, "hive.openshift.io/reconcile-pause")
    return ctrl.Result{}, r.Update(ctx, cd)
}
```

Optionally watch `ClusterCurator` CRs — not required.

### Pros

- Native Kubernetes pattern (controller-runtime)
- No AAP, no Curator hook limitations
- Status via CR conditions and Prometheus metrics
- Go tests with envtest / fake client

### Cons

- You build and ship an operator (RBAC, OLM or manual deploy, upgrades)
- No ACM console integration for hook status unless you integrate UI yourself
- Duplicates what Curator + AAP already provide if you have AAP

### When it fits

Greenfield Go-heavy platform teams that already run hub-side operators (ESO, custom admission, etc.).

---

## Pattern P6 — CI / Tekton on Git apply

**Use when:** Preflight and render happen in **pipeline** before manifests reach the hub.

### Flow

```text
PR changes sites/dc-east/cluster.yaml
    → CI: bm-preflight --inventory sites/dc-east/hosts.yaml (Go or Ansible)
    → CI: bm-render --output rendered/dc-east/
    → merge → Argo CD syncs to hub
```

Tekton sketch (post-install variant in [cluster-curator README](../examples/ocm-subscription-automation/cluster-curator/README.md)):

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: bare-metal-site-validate
spec:
  params:
    - name: site
  tasks:
    - name: preflight
      taskRef:
        name: bm-preflight
      params:
        - name: site
          value: $(params.site)
    - name: render-bundle
      runAfter: [preflight]
      taskRef:
        name: bm-render-apply
```

### Pros

- Familiar to GitOps teams; PR is the gate
- No hub-side AAP for pre-apply checks
- Easy local reproduction (`make preflight SITE=dc-east`)

### Cons

- Not tied to ACM lifecycle events after apply (unless you add watchers)
- Drift: emergency `oc apply` bypasses pipeline
- ClusterCurator prehook becomes redundant if CI already gated

### Combine with P2

CI for **render + static validation**; Curator prehook for **last-mile hub checks** (assisted pods up, mirror CR present) that only make sense on the live hub.

---

## Pattern P7 — Agent approval gate (post-discovery)

**Use when:** Custom logic must run **after** hosts boot the discovery ISO and register as `Agent` CRs.

### Ansible watcher (scheduled job on hub)

```yaml
- hosts: localhost
  vars:
    cluster_ns: prod-bm-01
  tasks:
    - name: List unapproved agents
      kubernetes.core.k8s_info:
        api_version: agent-install.openshift.io/v1beta1
        kind: Agent
        namespace: "{{ cluster_ns }}"
      register: agents

    - name: Approve when custom checks pass
      kubernetes.core.k8s:
        api_version: agent-install.openshift.io/v1beta1
        kind: Agent
        name: "{{ item.metadata.name }}"
        namespace: "{{ cluster_ns }}"
        merge_type: merge
        definition:
          spec:
            approved: true
      loop: "{{ agents.resources }}"
      when:
        - not (item.spec.approved | default(false))
        - item.status.validationsInfo | default([]) | selectattr('status', 'equalto', 'passed') | list | length > 0
        # Add custom: role label present, disk size, etc.
```

### Go equivalent

Controller watches `Agent` objects; `Approve()` only when validation helpers pass. Same semantics, stronger typing for disk/NIC rules.

### Pros

- Correct timing for per-host hardware decisions
- Complements (does not replace) P1/P2

### Cons

- Agents must exist — useless for pure Day-0 site checks
- Race with `autoApprove: true` if misconfigured

---

## Provisioning model affects BMH placement

| Install model | Where BMH gets created | Recommended pattern |
|---------------|------------------------|---------------------|
| **CIM / agent ISO** | Often post-install on spoke (Metal3); control plane via agents | P1 for inventory; P7 for host gate; prehook for site only |
| **Metal3 / IPI on hub** | Hub or spoke `BareMetalHost` before Ironic provisions | P1 or P3 with `--apply-bmh` in prehook |
| **Ansible-as-provisioner (legacy)** | Ansible playbook today | Migrate toward P1+P2 per [CLUSTERCURATOR-ARCHITECTURE-DECISION.md](../examples/ocm-subscription-automation/cluster-curator/CLUSTERCURATOR-ARCHITECTURE-DECISION.md) |

---

## Recommended combinations

### Greenfield + AAP already planned

```text
P1 (render bundle + BMH) → Git/Argo apply → P2 (Curator prehook day-0) → P7 (agent approval)
```

### Greenfield + Go-first, no AAP

```text
P6 (CI preflight + render) → Git/Argo apply → P5 (operator unpause) → P7 (Go agent watcher)
```

### Minimal change to existing Ansible provisioning

```text
Keep current Ansible provisioner → add P2 posthook only (OCM subscription) → migrate P1 later
```

Path A in [CLUSTERCURATOR-ARCHITECTURE-DECISION.md](../examples/ocm-subscription-automation/cluster-curator/CLUSTERCURATOR-ARCHITECTURE-DECISION.md).

---

## Anti-patterns

| Anti-pattern | Why it fails |
|--------------|--------------|
| Prehook expects `Agent` inventory | Agents do not exist until after ISO boot |
| Only Curator prehook for full BMH discovery on agent install | Wrong timing — use P1 or P7 |
| `overrideJob` with single container and no unpause | Install never starts |
| `autoApprove: true` + P7 approval logic | Race — pick one gate |
| Duplicate gates in CI and Curator with different rules | Operators cannot tell which failed |
| Forking curator without upgrade plan | Breaks on ACM/MCE bump |

---

## AAP integration checklist (P2 / P3)

| Step | Action |
|------|--------|
| 1 | Install AAP Resource Operator (`stable-2.x-cluster-scoped`) |
| 2 | Create EE with collections (`kubernetes.core`, Redfish) or Go binary (P3) |
| 3 | Job template: **Prompt on launch** for Extra Variables |
| 4 | `oc create secret generic aap-credentials` in cluster namespace |
| 5 | Bundle: `ClusterDeployment` paused + `ClusterCurator` + install CRs |
| 6 | Verify: `oc get ansiblejob`, curator job logs |

---

## Related reading

| Topic | Location |
|-------|----------|
| Lifecycle timing map | [agent-install-preflight.md](./agent-install-preflight.md) |
| AAP ↔ ACM native paths | [acm-ansible-integration.md](./acm-ansible-integration.md) |
| Greenfield stack | [greenfield-fleet-architecture.md](./greenfield-fleet-architecture.md) |
| Fleet ad-hoc / node diagnostics | [fleet-ad-hoc-data-gathering.md](./fleet-ad-hoc-data-gathering.md) |
| Curator vs Ansible provisioner | [CLUSTERCURATOR-ARCHITECTURE-DECISION.md](../examples/ocm-subscription-automation/cluster-curator/CLUSTERCURATOR-ARCHITECTURE-DECISION.md) |
| ClusterCurator CRD examples | [cluster-curator/README.md](../examples/ocm-subscription-automation/cluster-curator/README.md) |
| CIM hub setup | [cim-hub-setup.md](./cim-hub-setup.md) |
| BMC preflight tasks | [bare-metal-dev-sandbox preflight_validate](../../bare-metal-dev-sandbox/roles/preflight_validate/tasks/main.yml) |
| NVMe fabric check (post-install node) | [nvme-tcp ansible](../../ocp/troubleshooting/nvme-tcp-storage-network/ansible/README.md) |
| ClusterCurator upstream API | [clustercurator_types.go](https://github.com/stolostron/cluster-curator-controller/blob/main/pkg/api/v1beta1/clustercurator_types.go) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

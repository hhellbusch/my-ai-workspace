---
review:
  status: unreviewed
  notes: "Drafted 2026-09-10 from an AAP 2.7 operator install on OCP. Architecture claims pinned to verified 2.7 planning/install docs; live object names from that session."
---

# AAP operator on OpenShift — what Kubernetes you get

> **Audience:** People who know Ansible Automation Platform as VMs, an installer inventory, and control / execution / hop nodes, and are looking at the operator on OpenShift for the first time.
>
> **Purpose:** Map the old topology onto OpenShift objects so day-2 is `oc` and custom resources, not SSH to a controller host. Decide what is still “AAP product” vs what is now cluster operations.

The product is the same: organizations, credentials, projects, job templates, execution environments.

The **install topology and day-2 ops** are not.

This note is the OpenShift-native side.
It is not a migration runbook from RPM, and it is not a full operator install guide.

---

## Two supported install models in 2.7

The RPM installer was deprecated in 2.5 and **removed in 2.7**.
What remains:

| Mode | Where it runs | Who owns the machines |
|---|---|---|
| **Containerized** | RHEL VMs / bare metal, Podman | You. Control, hybrid, execution, and hop nodes still exist as hosts. |
| **Operator** | OpenShift | The cluster. The control plane is pods in a namespace. |

Official table: [Installation and deployment models](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/html/planning_your_installation/plan-ref_installation_deployment_models) in *Planning your installation* (AAP 2.7).

If the memory is “inventory.ini with `[automationcontroller]` and `[execution_nodes]`,” that is containerized (or old RPM), not this.
On the operator, that inventory is an `AnsibleAutomationPlatform` custom resource.

---

## Topology swap

| Traditional (RPM / VM / containerized hosts) | Operator on OpenShift |
|---|---|
| Installer inventory: control, hybrid, execution, hop | One `AnsibleAutomationPlatform` CR; child CRs for controller, hub, EDA, metrics |
| systemd, nginx, postgres on hosts | Deployments, StatefulSets (postgres, redis), Jobs for migrations |
| Scale by adding VMs / mesh nodes | Scale with replica fields on the CR |
| Receptor mesh is the default execution plane | Default execution is **in-cluster container groups** (job pods). RHEL execution nodes are optional via `AutomationControllerMeshIngress` |
| VIP / load balancer you build | OpenShift Route (TLS at the edge) in front of **platform gateway** |
| Local disk or NFS you mount | PersistentVolumeClaims and StorageClasses. Hub file storage needs **ReadWriteMany** |
| `setup.sh` backup | Backup / Restore CRs (`AnsibleAutomationPlatformBackup`, and per-component kinds) |
| `journalctl` on the controller host | `oc logs`, events, CSV / CR status |
| Direct URLs to controller, hub, EDA | Gateway is the external front door. Controller API is `/api/controller/v2/`, not `/api/v2/` |

On operator deployments, Red Hat’s capacity planning is explicit: there are **no hybrid or control nodes**.
The control plane is container groups on the cluster.
See [Capacity plan for node types and workload characteristics](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/optimize-ref_controller_capacity_planning) in the 2.6 operations material (same operator model; 2.7 planning still points at this split).

---

## Kubernetes objects that replace the old stack

Names below are the kinds you will see in the AAP namespace after a fresh operator install.
Instance names follow the CR (`example-aap`, `example-aap-controller`, …).

### Lifecycle (OLM)

- `Subscription` on channel `stable-2.7` (namespace-scoped) or `cluster-scoped-2.x`
- `ClusterServiceVersion` — operator install health (`Succeeded`)
- Several operator Deployments in the same bundle: gateway, controller, hub, EDA, metrics, Lightspeed, resource operator

Install entry: [Install the Ansible Automation Platform Operator through OperatorHub](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-assembly_install_aap_operator) in *Install on OpenShift Container Platform* (AAP 2.7).

### Instance as CRs

The parent CR is `AnsibleAutomationPlatform` (`aap.ansible.com/v1alpha1`).
It owns the platform gateway and nested specs for components.

Typical children:

| Kind | What it was on VMs |
|---|---|
| `AutomationController` | Controller web + task |
| `AutomationHub` | Private automation hub / Galaxy NG |
| `EDA` | Event-Driven Ansible |
| `MetricsService` | Metrics service |
| `AutomationControllerMeshIngress` | Optional: expose Receptor so **RHEL execution nodes** can join. Absent until you need mesh |
| `*Backup` / `*Restore` | Installer backup playbooks |

CR shapes: [Ansible Automation Platform custom resources](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-assembly_appendix_operator_crs) (appendix) and [AnsibleAutomationPlatform API](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/reference-ansibleautomationplatform__aap_ansible_com_v1alpha1_).

GitOps the **CR**, not `settings.py` on disk.

### Workloads

- **Deployments** — gateway, controller-web, controller-task, hub-api / content / web / worker, EDA API / workers / event-stream
- **StatefulSets** — postgres, redis
- **Jobs** — one-shot work such as controller schema migration
- **User jobs** — Pods in a container group (often `automation-job-*` in the AAP namespace), not `ansible-runner` on an execution VM

A short sleep in the playbook is enough to catch that job pod with `oc get pods -n <aap-ns> -w`.
See [015 — AAP hello world smoke test](examples/015_aap_hello_world_smoke/README.md).

### Networking

- ClusterIP **Services** per component (postgres headless, hub content, EDA stream, …)
- **One Route** to the gateway on a typical 2.7 install (edge TLS, redirect HTTP → HTTPS)
- In-cluster DNS for the rest (`…-controller-service`, `…-postgres-15`, …)

2.7 makes gateway the **sole external entry**.
Direct routes to controller / hub / EDA APIs are out of the supported picture.
Playbooks that still call `/api/v2/` against the gateway hostname 404 — that is the [AAP 2.5+ token 404](troubleshooting/aap-controller-token-404/README.md) class of bug, not a down controller.

Removed-feature note: [Removed features](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/whats_new-removed_features) (AAP 2.7).

### Storage

| Claim | Typical access | Why |
|---|---|---|
| Postgres PVC | RWO | Database |
| Hub redis PVC | RWO | Cache |
| Hub **file** PVC | **RWX** filesystem | API, content, and worker pods share `/var/lib/pulp` |

Default StorageClass is often Ceph RBD.
RBD does **not** give RWX filesystem.
Hub file storage wants CephFS (or other RWX filesystem), or object storage (`storage_type: s3` / Azure) instead of file.

That mismatch shows up as a Pending PVC and hub pods stuck on volume bind — not as “Ceph is down.”

### Identity and policy

- **ServiceAccounts** per component (`…-controller`, `…-hub`, operator SAs)
- **Roles / RoleBindings** created by the operators
- **Secrets** for admin password, postgres, pull credentials — not files under `/etc/tower`
- SCC / `restricted-v2`, image pull secrets, resource requests, probes — inherited from the cluster

`oc get secret -n <aap-ns> <instance>-admin-password` is the gateway `admin` password.
There is no published default password.

### Cluster facilities you inherit

These are not AAP features. You get them because the control plane is a tenant of OpenShift:

- Scheduler, placement, taints / tolerations (if you set them on the CR)
- Cluster logging, metrics, `must-gather`
- GitOps of the AAP CR (Argo CD / ACM)
- Idle / replica knobs on the CR instead of stopping a VM

Day-2 becomes **OpenShift day-2** (storage class, routes, operators, PVCs) **plus** AAP day-2 (templates, creds, RBAC).

---

## What did not become Kubernetes objects

| Still in the controller / hub database | Not a CR |
|---|---|
| Organizations, teams, users (after first login) | |
| Credentials, inventories, projects, job templates | |
| Subscription / manifest | |
| Execution Environment *definitions* | Still images. On OCP they run as pods |

CaC of those objects is still `ansible.controller` / `ansible.platform` / `infra.aap_configuration` against the **gateway API**.
That is a different layer from GitOps of the operator CR.
The [AAP SDLC draft](aap-sdlc/README.md) is about the former.

---

## Day-2 habits that change

**Do not SSH to “the controller” to edit settings.**
Change the CR (or a Secret the CR references) and let the operator reconcile.

**Scale** is `spec.controller` / hub replica fields, not another hybrid VM.

**Execution leaving the cluster** (Windows, isolated L2, “this job must not run next to etcd”) is still Receptor mesh — you add `AutomationControllerMeshIngress` and RHEL execution nodes.
A small demo usually has none of that.
Jobs stay in-cluster.

**Upgrades** are OLM channel + CSV, then CR image/version fields, sitting on an OpenShift upgrade cadence you now share.

**Failure domain** includes etcd, SDN, and the StorageClass.
A Pending Hub PVC is an OpenShift storage problem even when AAP UI looks “installed.”

---

## What to look at on a live operator install

```bash
# Operator health
oc get csv,sub -n <aap-ns>

# Instance
oc get ansibleautomationplatform,automationcontroller,automationhub,eda -n <aap-ns>

# Workloads + the Route that is the UI
oc get deploy,sts,job,route,pvc -n <aap-ns>

# Optional mesh (empty until you attach RHEL execution nodes)
oc get automationcontrollermeshingress -n <aap-ns>

# After launching a job: the container-group pod
oc get pods -n <aap-ns> -w
```

Launch a long enough job (a `pause` / `sleep` of a minute or two) or the pod is gone before the console refreshes.

---

## Official docs

| Topic | Where |
|---|---|
| Containerized vs operator | [Installation and deployment models](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/html/planning_your_installation/plan-ref_installation_deployment_models) — *Planning your installation*, AAP 2.7 |
| OperatorHub install | [Install the AAP Operator through OperatorHub](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-assembly_install_aap_operator) — *Install on OpenShift Container Platform*, AAP 2.7 |
| Parent CR fields | [AnsibleAutomationPlatform API](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/reference-ansibleautomationplatform__aap_ansible_com_v1alpha1_) |
| Example CRs | [Custom resources appendix](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/install-assembly_appendix_operator_crs) |
| No control/hybrid nodes on operator | [Capacity plan for node types](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/optimize-ref_controller_capacity_planning) — AAP 2.6 (operator model) |
| RPM gone; gateway as front door | [Removed features](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/whats_new-removed_features) — AAP 2.7 |

---

## Related reading

- [AAP 2.5+ `ansible.controller.token` 404](troubleshooting/aap-controller-token-404/README.md) — gateway path `/api/controller/v2/` vs legacy `/api/v2/`
- [015 hello-world smoke test](examples/015_aap_hello_world_smoke/README.md) — localhost job plus a pause so the job pod is visible
- [AAP / Ansible SDLC](aap-sdlc/README.md) — CaC of controller objects (not the operator CR)
- [RHACM and AAP integration](../rhacm/notes/acm-ansible-integration.md) — `AnsibleJob` CRs from ACM; assumes a reachable controller, operator or not
- [AAP SSH MTU](../ocp/troubleshooting/aap-ssh-mtu-issues/README.md) — still applies when jobs SSH off-cluster from an EE pod

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

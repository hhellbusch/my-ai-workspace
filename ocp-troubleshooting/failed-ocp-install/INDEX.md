# Failed OCP Install – Index

Navigate by symptom or phase.

## By install phase

| Phase | Section in README |
|-------|-------------------|
| Bootstrap never completes | [Step 4 – API not reachable / Option B: Check bootstrap node](README.md#option-b-bootstrap-not-complete--check-bootstrap-node) |
| Bootstrap done, API not reachable | [Step 4 – API not reachable / Option A: SSH to control plane](README.md#option-a-you-have-ssh-to-a-control-plane-node) |
| API up, operators not ready | [Step 5 – API works, install not complete](README.md#step-5-api-works-install-not-complete) |
| Workers not joining | [Step 5d – Workers not joining](README.md#5d-workers-not-joining-workers-stay-not-ready-or-missing) |

## By symptom

| Symptom | Where to look |
|---------|----------------|
| `oc` connection refused / timeout | [Step 3 / Step 4](README.md#step-3-determine-which-phase-youre-in) – use control plane localhost kubeconfig |
| `oc` TLS / certificate errors | [Step 4 Option A](README.md#option-a-you-have-ssh-to-a-control-plane-node) + [API Server Certificate Deadlock](../apiserver-cert-deadlock/README.md) |
| Nodes stuck Pending / Not Ready | [Step 5a – Check pending CSRs](README.md#5a-check-for-pending-csrs) + [CSR Management](../csr-management/README.md) |
| Operators Progressing or Degraded | [Step 5b – Check cluster operators](README.md#5b-check-cluster-operators) |
| Bare metal node inspecting/provisioning | [Step 4 Option C](README.md#option-c-bare-metal--nodes-stuck-inspecting-or-provisioning) + [Bare Metal Node Inspection Timeout](../bare-metal-node-inspection-timeout/README.md) |
| Worker TLS/cert failures | [Worker Node TLS Certificate Failure](../worker-node-tls-cert-failure/README.md) |
| kube-controller-manager crash loop | [kube-controller-manager Crash Loop](../kube-controller-manager-crashloop/README.md) |
| Need install timeline and monitoring | [Control Plane Kubeconfigs / Installation Monitoring](../control-plane-kubeconfigs/INSTALL-MONITORING.md) |
| Destroy cluster without metadata | [Destroy Cluster Without Metadata](../destroy-cluster-without-metadata/README.md) |

## By role / task

| Task | Document |
|------|----------|
| First-time flow with explanations | [README.md](README.md) (full guide) |
| Fast commands only | [QUICK-REFERENCE.md](QUICK-REFERENCE.md) |
| Find section by phase or symptom | This index |
| Official Red Hat / OpenShift docs and support | [README – Red Hat and OpenShift Resources](README.md#red-hat-and-openshift-resources) |

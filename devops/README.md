# DevOps / Engineering Reference

Practical, runnable examples and references for infrastructure, platform, and operational tooling — built from real work and accumulated over time. Currently weighted toward enterprise Kubernetes and OpenShift environments; will grow as work and interests do.

**What belongs here:** Runnable examples, troubleshooting guides, lab exercises, and integration patterns for any infrastructure, platform, or operational tool. Not essays or case studies (those live in [`docs/`](../docs/)) and not research workspaces ([`research/`](../research/)).

---

## Contents

### [Ansible](ansible/)

Automation patterns built from real operational needs.

- **`examples/`** — 13 runnable playbooks: retry-on-timeout, error handling with logging, conditional blocks, virtual media ejection, block/rescue/retry patterns, parallel execution via bastion, ISO boot monitoring, IP subnet validation, global defaults across roles, Dell memory validation, parallel inventory updates, REST API result filtering, SMB-to-Vault credential management
- **`troubleshooting/`** — AAP Controller token 404 on AAP 2.5.x (Gateway API path change); Ansible gather-facts unknown host

### [ArgoCD / GitOps](argo/)

GitOps patterns for multi-cluster OpenShift environments.

- **`examples/`** — Multi-hub GitOps pipelines, app-of-apps patterns, Helm charts, GitHub Actions workflows, ArgoCD framework with devspaces and team guidelines, test and validation scripts
- **`labs/`** — Hands-on exercises: ArgoCD sync patterns, GitOps fundamentals

### [CoreOS](coreos/)

Butane / Ignition configurations for first-boot automation.

- **`examples/`** — ISO ejection after installation, first-boot configuration automation

### [OpenShift (OCP)](ocp/)

The deepest product section — install, operations, and troubleshooting for enterprise OpenShift.

- **`examples/`** — OVN-Kubernetes networking, install config templates, SNO KVM lab setup
- **`troubleshooting/`** — 20 guides covering: API slowness, bare metal inspection timeouts, apiserver cert deadlock, CoreOS networking, CSR management, kube-controller-manager crashloops, KubeVirt VM provisioning, namespace termination, Portworx CSI, worker TLS cert failures, image registry auth, MCP deadlock, RHACM webhook rejection, OAuth healthz, and more
- **`notes/`** — Quick references: useful `oc` and `kubectl` commands
- **`install/`** *(gitignored)* — Local install working directory; never committed

### [RHACM](rhacm/)

Red Hat Advanced Cluster Management patterns for multi-cluster environments.

- **`examples/`** — Secret management patterns, cluster import with Ansible, ArgoCD RBAC integration, GitOps cluster integration, OCM subscription automation

### [Vault](vault/)

HashiCorp Vault integration patterns.

- **`integration/`** — Vault integration configurations and patterns for secrets management

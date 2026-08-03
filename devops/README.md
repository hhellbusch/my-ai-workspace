---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# DevOps / Engineering Reference

Practical, runnable examples and references for infrastructure, platform, and operational tooling — built from real work and accumulated over time. Currently weighted toward enterprise Kubernetes and OpenShift environments; will grow as work and interests do.

**Browse the site** (search, sidebar nav): [hhellbusch.github.io/my-ai-workspace](https://hhellbusch.github.io/my-ai-workspace/) — built from this tree with MkDocs Material on push to `main`.

**Symptom lookup:** [SYMPTOM-INDEX.md](SYMPTOM-INDEX.md) — generated from [`catalog.yaml`](catalog.yaml) `guides`.

**Example lookup:** [EXAMPLE-INDEX.md](EXAMPLE-INDEX.md) — generated from [`catalog.yaml`](catalog.yaml) `examples`.

**Build the site locally:** `pip install -r requirements-docs.txt && bash scripts/build-docs.sh` → `site/`

**Preview with live reload:** `bash scripts/serve-docs.sh` (refreshes staging automatically)

**What belongs here:** Runnable examples, troubleshooting guides, lab exercises, and integration patterns for any infrastructure, platform, or operational tool. Not essays or case studies (those live in [`docs/`](../docs/)) and not research workspaces ([`research/`](../research/)). Local LLM inference setup for consumer hardware lives here rather than in docs/ since it's practical reference, not essay.

**Organization:** [ORGANIZATION.md](ORGANIZATION.md) — where to put new content (platform vs workload, troubleshooting vs examples vs notes).

**External links:** Red Hat doc URLs (`docs.redhat.com`) — see [`rules/red-hat-docs-links.md`](../rules/red-hat-docs-links.md) (pin versions, verify slugs, searchable link text).

### Fleet control spectrum

Cross-cutting reference for how RHACM and Argo CD divide fleet work — multiple decision axes, not a single product choice.

- **[fleet-control-spectrum.md](fleet-control-spectrum.md)** — Reconciliation authority, compliance posture, lifecycle scope, and a reconsideration checklist for GitOps-heavy designs
- **[rhacm/notes/greenfield-fleet-architecture.md](rhacm/notes/greenfield-fleet-architecture.md)** — Default ACM + GitOps stack for a new fleet; when to add AAP/AWX
- **[rhacm/notes/acm-ansible-integration.md](rhacm/notes/acm-ansible-integration.md)** — Native ACM→Ansible integration paths and prerequisites
- **[rhacm/notes/fleet-ad-hoc-data-gathering.md](rhacm/notes/fleet-ad-hoc-data-gathering.md)** — Patterns for ad-hoc diagnostics across fleet nodes
- **[rhacm/notes/bare-metal-lifecycle-hook-patterns.md](rhacm/notes/bare-metal-lifecycle-hook-patterns.md)** — Preflight, BMH discovery, install gates — AAP/Curator vs Go/operator/CI
- **[rhacm/git-driven-configuration.md](rhacm/git-driven-configuration.md)** — RHACM hub and policy resources in Git; rebuild-from-scratch posture; delivery via Argo CD
- **[bigfix-gitops-on-ocp.md](bigfix-gitops-on-ocp.md)** — Food for thought: HCL BigFix on OpenShift with GitOps — ownership matrix and team discussion prompts
- **[fleet-management-ideas.md](fleet-management-ideas.md)** — Review log of doc and framework follow-ups (not a committed roadmap)

---

## Contents

### Bare Metal Dev Sandbox (`devops/bare-metal-dev-sandbox/`)

Local Redfish/BMC preflight harness for developing ACM bare-metal automation without dedicated hardware per developer.

- **[README.md](bare-metal-dev-sandbox/README.md)** — start here; fidelity tiers and promotion gates
- **[HARNESS.md](bare-metal-dev-sandbox/HARNESS.md)** — scenario runner and assertion model
- **[WORKSHOP.md](bare-metal-dev-sandbox/WORKSHOP.md)** — hands-on labs and peer teaching outline
- **`scenarios/`** — validation-gate scenarios (baseline pass, firewall blocks, BMC auth failure, kitchen-sink fail, and more)
- **`playbooks/`** + **`roles/preflight_validate/`** — Ansible validation gate against sushy-static mock BMCs

### [Ansible](ansible/)

Automation patterns built from real operational needs.

- **`examples/`** — 14 runnable playbooks: retry-on-timeout, error handling with logging, conditional blocks, virtual media ejection, block/rescue/retry patterns, parallel execution via bastion, ISO boot monitoring, IP subnet validation, global defaults across roles, Dell memory validation, parallel inventory updates, REST API result filtering, SMB-to-Vault credential management, Confluence page creation
- **`troubleshooting/`** — AAP Controller token 404 on AAP 2.5.x (Gateway API path change); Ansible gather-facts unknown host

### [ArgoCD / GitOps](argo/)

GitOps patterns for multi-cluster OpenShift environments.

- **`examples/`** — Multi-hub GitOps pipelines, app-of-apps patterns, Helm charts, GitHub Actions workflows, ArgoCD framework with devspaces and team guidelines, test and validation scripts
- **`labs/`** — Hands-on exercises: Argo CD sync patterns, GitOps fundamentals ([index](argo/labs/README.md))

### [CoreOS](coreos/)

Butane / Ignition configurations for first-boot automation.

- **`examples/`** — ISO ejection after installation, first-boot configuration automation

### [Git](git/)

Learning guide for developers who want to understand what git does, not just memorize commands.

- **`git-learning-guide.md`** — Content-addressable filesystem model, the staging area mental model, four core commands, branching strategy, undo/restore patterns, search and find, remote workflows, cheat sheet

### [KVM / libvirt](kvm/)

Host-side QEMU/KVM and libvirt on Linux.

- **`windows-vm-on-fedora.md`** — CLI setup for Windows 10/11 on Fedora: `virt-install`, VirtIO driver paths, common permission and Q35 gotchas ([index](kvm/README.md))

### [Learning paths](learning-path/)

Curated multi-topic curricula (may span OpenShift, GitOps, and labs in this repo).

- **`vmware-admins/`** — VMware platform engineers → Kubernetes, OpenShift, OpenShift Virtualization; includes a **Git / GitHub** prerequisite for GitOps; links to Red Hat docs, courses, and in-repo labs ([index](learning-path/README.md))
- **`git/`** — Staged Git curriculum with external resources and in-repo deep dive cross-links ([index](learning-path/git/README.md))

### [OpenShift (OCP)](ocp/)

The deepest product section — install, operations, workloads on OpenShift, and symptom guides.

- **`troubleshooting/`** — 25 catalog-backed guides ([index](ocp/troubleshooting/README.md), [SYMPTOM-INDEX](SYMPTOM-INDEX.md))
- **`examples/`** — Runnable scenarios by topic:
  - [bare-metal](ocp/examples/bare-metal/README.md) · [messaging/kafka](ocp/examples/messaging/kafka/README.md) · [networking](ocp/examples/networking/README.md) · [labs](ocp/examples/labs/README.md)
- **`notes/`** — Quick refs: [MachineConfig pools](ocp/notes/machine-config-pools.md), [network policy](ocp/notes/network-policy-observability.md), [density/CRO/VPA](ocp/notes/container-density-overcommit.md), [useful commands](ocp/notes/openshift-useful-commands.md)
- **`disconnected-install/`** — Quay + `oc-mirror` ([working guide](ocp/disconnected-install/working-guide.md))
- **`ibm-z/`**, **`gpu/`** — Platform variants
- **`install/`** *(gitignored)* — Local install working directory

### [RHACM](rhacm/)

Red Hat Advanced Cluster Management patterns for multi-cluster environments.

- **`notes/`** — Hub readiness, search setup, CIM, agent preflight, bare-metal networking, cluster destroy ([index](rhacm/notes/README.md))
- **`troubleshooting/`** — 6 symptom guides in [SYMPTOM-INDEX](SYMPTOM-INDEX.md) (`product: rhacm`) — MCH upgrade, cluster lease, observability, search 503, agent rootfs SSL ([index](rhacm/troubleshooting/README.md))
- **`examples/`** — Secret management patterns, cluster import with Ansible, ArgoCD RBAC integration, GitOps cluster integration, OCM subscription automation

### [Local LLM Setup](llm/)

Consumer inference setup guides: Ollama, RamaLama, LM Studio, LiteLLM proxy, and vLLM for maximum serving throughput.

- **`local-llm-setup.md`** — Hardware requirements, model selection with measured tok/s, Cursor/Claude Code integration, electricity measurement methodology
- **`local-llm-vllm.md`** — Full vLLM install (CUDA + ROCm), serve commands, container setup, context limits, cluster topology

### [Vault](vault/)

HashiCorp Vault integration patterns.

- **`integration/`** — Vault integration configurations and patterns for secrets management

### Workspace tooling

Agent and editor workflow for this repository — not infrastructure you deploy to clusters.

- **[Pi](pi/)** — Pi agent discovery, packages, startup behavior
- **[Paude](paude/)** — Container layering model and `paude.json`
- **[Paude Proxy](paude-proxy/)** — Reverse proxy, TLS, GitHub PAT scopes

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

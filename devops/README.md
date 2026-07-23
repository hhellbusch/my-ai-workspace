---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
---

# DevOps / Engineering Reference

Practical, runnable examples and references for infrastructure, platform, and operational tooling — built from real work and accumulated over time. Currently weighted toward enterprise Kubernetes and OpenShift environments; will grow as work and interests do.

**Browse the site** (search, sidebar nav): [hhellbusch.github.io/my-ai-workspace](https://hhellbusch.github.io/my-ai-workspace/) — built from this tree with MkDocs Material on push to `main`.

**Symptom lookup:** [SYMPTOM-INDEX.md](SYMPTOM-INDEX.md) — generated from [`catalog.yaml`](catalog.yaml).

**Build the site locally:** `pip install -r requirements-docs.txt && bash scripts/build-docs.sh` → `site/`

**Preview with live reload:** `bash scripts/serve-docs.sh` (refreshes staging automatically)

**What belongs here:** Runnable examples, troubleshooting guides, lab exercises, and integration patterns for any infrastructure, platform, or operational tool. Not essays or case studies (those live in [`docs/`](../docs/)) and not research workspaces ([`research/`](../research/)). Local LLM inference setup for consumer hardware lives here rather than in docs/ since it's practical reference, not essay.

**External links:** Red Hat doc URLs (`docs.redhat.com`) — see [`rules/red-hat-docs-links.md`](../rules/red-hat-docs-links.md) (pin versions, verify slugs, searchable link text).

### Fleet control spectrum

Cross-cutting reference for how RHACM and Argo CD divide fleet work — multiple decision axes, not a single product choice.

- **[fleet-control-spectrum.md](fleet-control-spectrum.md)** — Reconciliation authority, compliance posture, lifecycle scope, and a reconsideration checklist for GitOps-heavy designs
- **[rhacm/git-driven-configuration.md](rhacm/git-driven-configuration.md)** — RHACM hub and policy resources in Git; rebuild-from-scratch posture; delivery via Argo CD
- **[fleet-management-ideas.md](fleet-management-ideas.md)** — Review log of doc and framework follow-ups (not a committed roadmap)

---

## Contents

### Bare Metal Dev Sandbox (`devops/bare-metal-dev-sandbox/`)

Local Redfish/BMC preflight harness for developing ACM bare-metal automation without dedicated hardware per developer. *(In progress — not yet in tree; links will appear here when committed.)*

- **`scenarios/`** — validation-gate scenarios (baseline pass, firewall blocks, BMC auth failure, kitchen-sink fail, and more)
- **`playbooks/`** + **`roles/preflight_validate/`** — Ansible validation gate against sushy-static mock BMCs
- **`WORKSHOP.md`** — hands-on labs and peer teaching outline
- **`HARNESS.md`** — scenario runner and assertion model

### [Ansible](ansible/)

Automation patterns built from real operational needs.

- **`examples/`** — 13 runnable playbooks: retry-on-timeout, error handling with logging, conditional blocks, virtual media ejection, block/rescue/retry patterns, parallel execution via bastion, ISO boot monitoring, IP subnet validation, global defaults across roles, Dell memory validation, parallel inventory updates, REST API result filtering, SMB-to-Vault credential management
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

### [OpenShift (OCP)](ocp/)

The deepest product section — install, operations, and troubleshooting for enterprise OpenShift.

- **`examples/`** — OVN-Kubernetes networking, install config templates, SNO KVM lab, [secondary disk offload](ocp/examples/bare-metal-secondary-disk/README.md)
- **`disconnected-install/`** — Disconnected OCP 4.18.14 with Quay + `oc-mirror`: [working guide](ocp/disconnected-install/working-guide.md), [scope](ocp/disconnected-install/BRIEF.md)
- **`ibm-z/`** — OpenShift on IBM Z and LinuxONE (s390x): mental model, provisioning/automation (ACM, ABI, Metal3), external references ([index](ocp/ibm-z/README.md))
- **`troubleshooting/`** — 20+ guides covering: API slowness, bare metal inspection timeouts, apiserver cert deadlock, CoreOS networking, CSR management, kube-controller-manager crashloops, KubeVirt VM provisioning, namespace termination, NVMe host NQN duplicates, NVMe/TCP storage network, Portworx CSI, worker TLS cert failures, image registry auth, MCP deadlock, RHACM webhook rejection, OAuth healthz, and more
- **`notes/`** — Quick references: [MachineConfig pools](ocp/notes/machine-config-pools.md), useful `oc` and `kubectl` commands
- **`install/`** *(gitignored)* — Local install working directory; never committed

### [RHACM](rhacm/)

Red Hat Advanced Cluster Management patterns for multi-cluster environments.

- **`examples/`** — Secret management patterns, cluster import with Ansible, ArgoCD RBAC integration, GitOps cluster integration, OCM subscription automation

### [Local LLM Setup](llm/)

Consumer inference setup guides: Ollama, RamaLama, LM Studio, LiteLLM proxy, and vLLM for maximum serving throughput.

- **`local-llm-setup.md`** — Hardware requirements, model selection with measured tok/s, Cursor/Claude Code integration, electricity measurement methodology
- **`local-llm-vllm.md`** — Full vLLM install (CUDA + ROCm), serve commands, container setup, context limits, cluster topology

### [Pi Agent Configuration](pi/)

Reference for how pi discovers and displays resources in this workspace — skills, extensions, startup behavior, and troubleshooting.

- **`README.md`** — Directory layout, discovery rules, installed packages, startup display behavior, troubleshooting checklist

### [Paude](paude/)

Container tooling layering model for paude workspaces — where tools belong, how workspace config works, and this workspace's specific setup.

- **`README.md`** — Three-layer model (base image / workspace / runtime), decision guide, `paude.json` reference, domain aliases, mid-session domain unblocking

### [Paude Proxy](paude-proxy/)

Reverse proxy configuration, CA certificate management, and PAT (Personal Access Token) documentation for the workspace environment.

- **`README.md`** — Proxy architecture, environment variables, GitHub PAT scopes, TLS certificate details, and troubleshooting

### [Vault](vault/)

HashiCorp Vault integration patterns.

- **`integration/`** — Vault integration configurations and patterns for secrets management

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

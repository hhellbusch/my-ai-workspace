# AI-Assisted Engineering Workspace

A working example of using large language models for real engineering work — not chatbot Q&A, but structured workflows for research, technical writing, project planning, troubleshooting guides, and the meta-development patterns that emerge when you build with AI over time.

Started around Oct 2025 exploring how to get better results on customer work. Evolved into a set of reusable patterns worth sharing. The workspace itself is the example — everything here was built or refined with AI assistance.

## What's Here

### [Essays and Case Studies](docs/)

Practical insights on AI-assisted development, traced from real work in this repository.

**Start here:**
- [The Shift — Engineering Skills in the Age of AI](docs/ai-engineering/the-shift.md) — what changes when AI writes most of the first draft
- [AI-Assisted Development Workflows](docs/ai-engineering/ai-assisted-development-workflows.md) — daily patterns that work
- [The Meta-Development Loop](docs/ai-engineering/the-meta-development-loop.md) — the engineering pattern: gap → tool → apply → reshape

**Case studies** document specific decisions and patterns as they happened:
- [Debugging Your AI Assistant's Judgment](docs/case-studies/debugging-ai-judgment.md) — catching AI anchoring bias, building a structural fix
- [Choosing Scripts Over Services](docs/case-studies/choosing-scripts-over-services.md) — problem decomposition applied to tooling decisions
- [Building a Knowledge Management System with AI](docs/case-studies/building-knowledge-management-with-ai.md) — AI building the infrastructure for AI-assisted work

[Full reading order →](docs/README.md)

**Applied philosophy** — connecting principles from martial arts and Zen practice to engineering culture and ways of working. Primary lens is karate (Hayashi-ha Shito-ryu), drawing broadly from any source that applies. This track is in active development.
- [Ego, AI, and the Zen Antidote](docs/philosophy/ego-ai-and-the-zen-antidote.md) — how contemplative practice intersects with AI's impact on how we think and work

### DevOps Examples

Practical, runnable examples and troubleshooting guides for enterprise environments:

- **[Ansible](ansible/)** — 13 playbooks: retry patterns, error handling, parallel execution, BMC operations, Dell memory validation. [Troubleshooting](ansible/troubleshooting/) for AAP 2.5+.
- **[OpenShift](ocp/)** — 13+ [troubleshooting guides](ocp/troubleshooting/): API slowness, bare metal inspection, CSR management, kube-controller-manager crashes, namespace termination. [Examples](ocp/examples/) for OVN-Kubernetes, SNO KVM lab.
- **[ArgoCD](argo/)** — App-of-apps patterns, multi-environment configs, Helm charts, GitHub Actions workflows. [Labs](argo/labs/) for hands-on exercises.
- **[CoreOS](coreos/)** — Ignition/Butane configurations including [ISO auto-eject](coreos/examples/iso-eject-after-install/).
- **[RHACM](rhacm/)** — Secret management, multi-cluster management, policy and governance patterns.
- **[Vault](vault/)** — HashiCorp Vault integration patterns.

### Meta-Development System

The AI-assisted workflow system used to build this workspace. Optional — the examples and essays work independently.

Includes slash commands for planning, debugging, research, quality gates, and session management. Built on [TÂCHES CC Resources](https://github.com/glittercowboy/taches-cc-resources).

Details in [.cursor/README.md](.cursor/README.md).

## AI-Generated Content Notice

**The majority of content in this workspace was created with AI assistance, and the author has not personally reviewed most of it in detail.** The direction, intent, and key decisions are human; the prose, synthesis, and code are largely AI-generated. Some pieces have been read and validated, many have not.

This is an honest accounting, not a caveat — the project is partly an exploration of how far structured AI-assisted workflows can go. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for the full picture, including how to interpret review status.

## Getting Started

Browse the [essays](docs/) to understand the patterns. Explore the [examples](ansible/examples/) and [troubleshooting guides](ocp/troubleshooting/) for practical implementations. The [backlog](BACKLOG.md) shows what's in progress (rolling **Done** list; older completions in [BACKLOG-ARCHIVE.md](BACKLOG-ARCHIVE.md)).

```bash
git clone <repo-url>
# Start with the essays
cat docs/README.md
# Or jump to a specific tool
ls ansible/examples/
ls ocp/troubleshooting/
```

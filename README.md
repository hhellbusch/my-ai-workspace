# AI-Assisted Engineering Workspace

A public collection of essays, case studies, and practical examples documenting what AI-assisted work actually looks like over time — the patterns that work, the failure modes, the philosophical questions it raises, and the technical reference material built in the process.

Started in late 2025 capturing what was actually being learned while using AI tools on real work. Intended for a wide audience: engineers and practitioners using AI tools every day, managers and leaders thinking about how AI changes team skills and ways of working, and anyone curious about what shifts — professionally, culturally, and personally — when AI handles more of the first draft.

**This collection is itself built with the practices it documents.** Essays are AI-assisted, workflows are real, and where things haven't been personally validated, that's noted. [AI-DISCLOSURE.md](AI-DISCLOSURE.md) explains how to read the review status on individual pieces.

---

## Where to Start

Four entry points. Each works standalone.

**New to AI-assisted work with coding tools:**
[The Shift — Engineering Skills in the Age of AI](docs/ai-engineering/the-shift.md) — what changes when AI handles most of the implementation, and why the bottleneck moves rather than disappears.

**Curious about how AI shapes how we think — ego, agreement, sycophancy:**
[Ego, AI, and the Zen Antidote](docs/philosophy/ego-ai-and-the-zen-antidote.md) — what Zen practice offers as a structural (not just behavioral) response to AI's trained tendency to agree with you.

**Thinking about AI's impact on ways of working, skill development, and what we're building people for:**
[The Dojo After the Automation](docs/philosophy/the-dojo-after-the-automation.md) — a position paper on learning investment, organizational culture, and what happens to people when AI automates execution. Starting point for non-technical readers and leaders.

**Want a practical introduction to adversarial review and beginner's mind:**
[Sparring and Shoshin — Two Practices for AI-Assisted Work](docs/ai-engineering/sparring-and-shoshin.md) — two complementary practices for catching the most common ways AI-assisted work goes wrong. No prior reading required.

---

## Essays and Case Studies

Practical insights on AI-assisted development, philosophy, and ways of working — traced from real work in this repository. Three tracks.

### [AI-Assisted Engineering](docs/ai-engineering/)

Skills, workflows, and practical patterns — from the foundational shift in what engineering means, through daily working habits, to specific domains like legacy systems, open source contributions, local LLM deployment, and context window mechanics.

### [Philosophy and Practice](docs/philosophy/)

Connecting principles from martial arts and Zen practice to engineering culture, learning, and ways of working. Primary lens: karate. The questions are universal.

### [Case Studies](docs/case-studies/)

Documented examples from real sessions: tools built, failure modes caught, workflow decisions made and analyzed. Each traces what happened, what it demonstrates, and what's transferable — including a survivorship note about what doesn't get documented.

[Browse the full catalogue →](docs/README.md)

---

## Technical Reference

Practical, runnable examples and troubleshooting guides for enterprise infrastructure environments. *Skip this section if you're here for the essays — it's independent.*

- **[Ansible](ansible/)** — Playbooks, retry patterns, parallel execution, BMC operations, AAP 2.5+ troubleshooting
- **[OpenShift](ocp/)** — 13+ troubleshooting guides: API slowness, bare metal, CSR management, namespace termination, OVN-Kubernetes. SNO lab setup.
- **[ArgoCD](argo/)** — App-of-apps patterns, Helm charts, multi-environment GitOps, GitHub Actions workflows
- **[CoreOS](coreos/)** — Ignition/Butane configurations
- **[RHACM](rhacm/)** — Multi-cluster management, policy and governance
- **[Vault](vault/)** — HashiCorp Vault integration patterns

---

## Using This

**Read directly on GitHub** — essays and case studies are written for external readers. Any file link works standalone; relative links let you navigate the collection naturally from any starting point.

**Share specific pieces** — individual `docs/` files are the primary sharing unit. Sharing a direct GitHub link to an essay or case study is the intended workflow.

**Use as a template** — the `.cursor/` directory (slash commands, skills, rules) is designed to be portable. Clone the repo and add it as a reference folder in Copilot, VS Code, Cursor, or similar tools to load the workflow patterns into your own context.

Details and structure in [.cursor/README.md](.cursor/README.md). The [backlog](BACKLOG.md) shows what's actively in progress.

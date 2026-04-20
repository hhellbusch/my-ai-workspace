# Field Notes

*by [Henry Hellbusch](ABOUT.md) — engineering, philosophy, and practice in the age of AI.*

A practitioner's record of AI-assisted work: what it actually looks like over time, from inside the work rather than in retrospect. Essays, case studies, practical examples, and technical reference — built with the same tools and practices it documents. Meant to be shared, discussed, and argued with.

Intended for a wide audience: engineers and practitioners using AI tools every day, managers and leaders thinking through what AI means for their teams and organizations, and anyone asking what it means when AI becomes infrastructure — not just a faster tool, but a technology that reshapes how we think, learn, and define capability, as the internet did before it.

**This collection is built with the practices it documents.** Essays are AI-assisted, workflows are real, and where things haven't been personally validated, that's noted. [AI-DISCLOSURE.md](AI-DISCLOSURE.md) explains how to read the review status on individual pieces.

---

## Where to Start

Four entry points. Each works standalone.

**For anyone using AI tools today — the most shareable starting point:**
[Sparring and Shoshin — Two Practices for AI-Assisted Work](docs/ai-engineering/sparring-and-shoshin.md) — two complementary practices for catching the most common ways AI-assisted work goes wrong: adversarial review (get the AI to argue against itself) and beginner's mind (question what's been assumed). No prior reading required. Works in any AI tool, any workflow.

**For engineers and practitioners — the foundational framework:**
[The Shift — Engineering Skills in the Age of AI](docs/ai-engineering/the-shift.md) — what changes when AI handles most of the implementation, and why the bottleneck moves rather than disappears. Where the new skill priorities are, and where the risks concentrate.

**For managers, leaders, and non-technical readers — what AI means for organizations and teams:**
[The Full Cup — Why Nobody Can Learn When the Tap Is Always On](docs/philosophy/the-full-cup.md) — reframes the "empty your cup" idea from personal practice to organizational challenge. When AI compresses execution, does it create capacity for learning — or does it just fill the time with more output? A practical lens for thinking about what teams need to build. *(Companion playbook: [The Full Cup — Practitioner's Guide](docs/philosophy/the-full-cup-practitioners-guide.md).)*

**Curious about how AI shapes how we think — ego, agreement, sycophancy:**
[Ego, AI, and the Zen Antidote](docs/philosophy/ego-ai-and-the-zen-antidote.md) — AI assistants are trained to agree with you. This essay traces why that's a structural problem (not just a behavior to watch for), and what Zen practices offer as a structural — not just behavioral — response.

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

Practical, runnable examples and troubleshooting guides for infrastructure and platform tooling. *Skip this section if you're here for the essays — it's independent.*

[Browse the full reference index →](devops/README.md)

- **[Ansible](devops/ansible/)** — Playbooks, retry patterns, parallel execution, BMC operations, AAP 2.5+ troubleshooting
- **[OpenShift](devops/ocp/)** — 20+ troubleshooting guides: API slowness, bare metal, CSR management, namespace termination, OVN-Kubernetes. SNO lab setup.
- **[ArgoCD](devops/argo/)** — App-of-apps patterns, Helm charts, multi-environment GitOps, GitHub Actions workflows
- **[CoreOS](devops/coreos/)** — Ignition/Butane configurations
- **[RHACM](devops/rhacm/)** — Multi-cluster management, policy and governance
- **[Vault](devops/vault/)** — HashiCorp Vault integration patterns

---

## Using This

**Read directly on GitHub** — essays and case studies are written for external readers. Any file link works standalone; relative links let you navigate the collection naturally from any starting point.

**Share specific pieces** — individual `docs/` files are the primary sharing unit. Sharing a direct GitHub link to an essay or case study is the intended workflow.

**Use as a template** — the `.cursor/` directory (slash commands, skills, rules) is designed to be portable. Clone the repo and add it as a reference folder in Copilot, VS Code, Cursor, or similar tools to load the workflow patterns into your own context.

Details and structure in [.cursor/README.md](.cursor/README.md). The [backlog](BACKLOG.md) shows what's actively in progress.

---

## Library

The [`library/`](library/) directory is a personal reading collection — books, talks, articles, and videos with AI-enriched summaries and annotations. Entries are linked from essays and case studies where they're cited. The [catalog](library/catalog.md) is the full index.

---
review:
  status: unreviewed
  notes: "Devops directory taxonomy — placement rules for humans and agents."
---

# DevOps Reference — Organization

> **Audience:** Contributors (human or agent) adding or moving content under `devops/`.
>
> **Purpose:** Decide where a new guide, example, or note belongs so the catalog, site, and cross-links stay coherent as the tree grows.

## Top level

| Directory | What belongs here |
|-----------|-------------------|
| `ocp/` | OpenShift Container Platform — install, operations, workloads on OCP |
| `rhacm/` | Advanced Cluster Management — hub, fleet, CIM, policies |
| `ansible/`, `argo/`, `vault/` | Delivery and automation layers |
| `coreos/`, `kvm/` | Host and first-boot reference (Butane/Ignition, libvirt/KVM) |
| `learning-path/`, `git/`, `llm/` | Pedagogy and setup — not product runbooks |
| `pi/`, `paude/`, `paude-proxy/` | Workspace agent tooling (this repo's AI workflow) |
| `catalog.yaml`, `SYMPTOM-INDEX.md`, `EXAMPLE-INDEX.md` | Generated discovery — troubleshooting guides and OCP examples |
| `fleet-control-spectrum.md` | Cross-product fleet decision reference (RHACM vs Argo CD axes) |
| `fleet-management-ideas.md` | Review queue for fleet doc follow-ups (not a roadmap) |
| `README.md` | DevOps hub index |

**Essays and case studies** → `docs/`. **Raw research** → `research/`. **Enriched wiki entries** → `library/`.

## OpenShift (`devops/ocp/`)

Three **content types** — pick one before writing:

| Type | Directory | Use when |
|------|-----------|----------|
| **Troubleshooting** | `troubleshooting/<symptom>/` | Symptom → cause → fix; add entry to `devops/catalog.yaml` |
| **Examples** | `examples/<topic>/` | Runnable manifests, lab walkthroughs, apply-and-verify scenarios |
| **Notes** | `notes/` | Short quick refs, command lists, cross-cutting OCP reference |

**Topic subdirs under `examples/`** (grow here, not as new top-level products):

| Topic | Path | Examples |
|-------|------|----------|
| Bare metal | `examples/bare-metal/` | Secondary disk, `/var/log` offload |
| Messaging | `examples/messaging/kafka/` | Kafka on Portworx; future Connect/SR |
| Networking | `examples/networking/` | OVN install config, NAD, VLAN |
| Labs | `examples/labs/` | SNO KVM lab |
| Streaming | `examples/streaming/` | *(future)* Flink, etc. |

Install-time or platform-variant areas stay at `ocp/` root when they span topics: `disconnected-install/`, `ibm-z/`, `gpu/`.

## Platform vs workload

| Question | Placement |
|----------|-----------|
| How do I install/patch/secure **OpenShift**? | `ocp/` (troubleshooting, notes, or `examples/networking/`) |
| How do I run **Kafka/Flink** on OCP with OCP-specific bits? | `ocp/examples/messaging/` or `ocp/examples/streaming/` |
| Pattern portable to **any Kubernetes**? | `devops/workloads/` *(create when second portable guide exists)* |
| ACM hub firewall / CIM / cluster import? | `rhacm/notes/` or `rhacm/examples/` |
| Symptom on a **running cluster**? | `ocp/troubleshooting/` + `catalog.yaml` |

## Discovery for agents and humans

1. **Symptom** → `devops/SYMPTOM-INDEX.md` (from `catalog.yaml` `guides` — OCP, RHACM, Ansible today)
2. **Runnable example / scenario** → `devops/EXAMPLE-INDEX.md` (from `catalog.yaml` `examples` — OCP scenarios today)
3. **Product hub** → `devops/<product>/README.md`
4. **OCP topic** → `devops/ocp/examples/<topic>/README.md`
5. **Site browse** → MkDocs build (`scripts/build-docs.sh`) from staged `devops/` + `docs/`

When adding troubleshooting guides, update `catalog.yaml` and run `scripts/generate-symptom-index.py`.
When adding OCP examples, add an `examples:` entry and run `scripts/generate-example-index.py`.

**Labs placement:** `ocp/examples/labs/` for OpenShift lab walkthroughs; `argo/labs/` for GitOps instructor tracks — different audiences, both valid.

**Git pedagogy:** `learning-path/git/` is the staged curriculum; `devops/git/git-learning-guide.md` is the optional in-repo deep dive — cross-link both.

## Cross-linking checklist

- New example → topic `README.md` + `ocp/examples/README.md`
- Touches bare metal + hub → link both `ocp/examples/bare-metal/` and `rhacm/notes/`
- New note → `ocp/notes/README.md`

## Maturity lens

When adding or substantially updating `devops/` content, name which **maturity axis** it primarily exemplifies (one primary; optional secondary). Axes and levels: [trailhead](../docs/ai-engineering/software-systems-maturity.md). Corpus index: [artifact map](../research/software-systems-maturity/findings/artifact-map.md).

| Axis | Typical homes in this tree |
|---|---|
| Deployment & release | `argo/`, GitOps promotion, PR workflow examples |
| Platform & fleet | `rhacm/`, `fleet-control-spectrum.md`, OCP install variants |
| Security & secrets | `vault/`, RHACM secrets and policy examples |
| Monitoring & reliability | `ocp/troubleshooting/`, symptom guides in `catalog.yaml`, [slo-and-runbooks.md](slo-and-runbooks.md) |
| Builds & artifacts | CI in `argo/examples/`, operator installers |
| Architecture & change | Fleet notes, app-of-apps structure, GUIDELINES |
| Source control | `git/git-learning-guide.md` (pedagogy, not fleet policy) |
| Documentation & knowledge | READMEs, runbooks, cross-links — any durable guide |
| AI agents & harnesses | `pi/`, `paude/`, `paude-proxy/` |
| Testing & verification | Lab scenarios, validation scripts under examples |

This is **navigation**, not certification. Describe what the artifact *demonstrates*, not what the team claims to be. If it fills a gap in the artifact map, add or update a row there and link from the relevant [deep dive](../docs/ai-engineering/maturity/README.md).

## Planned (not in tree)

- `devops/bare-metal-dev-sandbox/` — local BMC preflight harness (see `devops/README.md`)
- `devops/workloads/` — platform-agnostic workload patterns

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

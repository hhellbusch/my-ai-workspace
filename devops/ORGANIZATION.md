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
| `learning-path/`, `git/`, `llm/` | Pedagogy and setup — not product runbooks |
| `pi/`, `paude/`, `paude-proxy/` | Workspace agent tooling (this repo's AI workflow) |
| `catalog.yaml`, `SYMPTOM-INDEX.md` | Generated discovery for **OCP troubleshooting** guides |

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

1. **Symptom** → `devops/SYMPTOM-INDEX.md` (from `catalog.yaml`)
2. **Product hub** → `devops/<product>/README.md`
3. **OCP topic** → `devops/ocp/examples/<topic>/README.md`
4. **Site browse** → MkDocs build (`scripts/build-docs.sh`) from staged `devops/` + `docs/`

When adding troubleshooting guides, update `catalog.yaml` and run `scripts/generate-symptom-index.py`.

## Cross-linking checklist

- New example → topic `README.md` + `ocp/examples/README.md`
- Touches bare metal + hub → link both `ocp/examples/bare-metal/` and `rhacm/notes/`
- New note → `ocp/notes/README.md`

## Planned (not in tree)

- `devops/bare-metal-dev-sandbox/` — local BMC preflight harness (see `devops/README.md`)
- `devops/workloads/` — platform-agnostic workload patterns

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "Code review of upstream IBM/Ansible-OpenShift-Provisioning v2.4.0; 2026-07-22."
---

# Ansible-OpenShift-Provisioning — Code Review

> **Audience:** Platform engineers evaluating or extending IBM's z/VM/LPAR/KVM OpenShift automation
> **Purpose:** DRY, maintainability, and ease-of-use assessment with remediation roadmap
> **Upstream:** [IBM/Ansible-OpenShift-Provisioning](https://github.com/IBM/Ansible-OpenShift-Provisioning) (reviewed at v2.4.0)
> **Fork work:** [ansible-openshift-provisioning-fork.md](ansible-openshift-provisioning-fork.md)

---

## Executive summary

AOP is **operator-friendly** (phased playbooks, templates, MkDocs) but **engineer-unfriendly** under the hood.
The largest debt is a **parallel HCP implementation** (`hcp.*` variables + ~15 `*_hcp` roles) instead of parameterizing the existing UPI/ABI path.

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Ease of use (operator) | **Good** | `site.yaml` pipeline, variable templates, published docs |
| DRY | **Poor** | HCP fork, repeated virt-install / agent-approval / firewall blocks |
| Maintainability | **Fair** | Clear phase numbers; `include_tasks` into role guts; dual config trees |
| Testability | **Poor** | ansible-lint on PR diff only; no Molecule for custom roles |

**Recommendation for adopters:** use AOP as a **reference for HMC/LPAR/KVM infra**; prefer **ABI/ACM** for cluster install where possible.
See [provisioning-and-automation.md](provisioning-and-automation.md).

---

## What works well

- **Phased playbooks** — `0_setup` → `7_ocp_verification` matches operator mental model; partial reruns possible.
- **Documentation** — [ibm.github.io/Ansible-OpenShift-Provisioning](https://ibm.github.io/Ansible-OpenShift-Provisioning/) with per-method runbooks.
- **Template-based secrets** — `secrets.yaml.template`, disconnected vars separated.
- **Validation** — `disconnected_check_vars`, `set_inventory` role.
- **Vendored collections** — reproducible in restricted networks.
- **`common` role** — architecture-specific vars (`roles/common/vars/<arch>/vars.yaml`).

---

## DRY violations (concrete)

### 1. HCP role fork (~15 `*_hcp` roles)

Parallel roles mirror UPI: `boot_LPAR` / `boot_LPAR_hcp`, `create_bastion` / `create_bastion_hcp`, etc.
HCP roles often import UPI templates via `../roles/...` paths — coupling without shared task logic.

### 2. Dual variable trees

| Path | Config |
|------|--------|
| UPI/ABI | `inventories/default/group_vars/all.yaml` + `secrets.yaml` |
| HCP | `playbooks/secrets.yaml` + `group_vars/hcp.yaml` |

Package lists duplicated in `roles/install_packages/defaults/` and `hcp.yaml.template`.

### 3. Repeated task blocks

| Pattern | Locations |
|---------|-----------|
| LPAR `host_vars` existence checks | `playbooks/0_setup.yaml` — `lpar1`, `lpar2`, `lpar3` copy-paste |
| HCP agent wait / approve (`oc get agents` + patch) | `boot_LPAR_hcp`, `boot_zvm_nodes_hcp` |
| HiperSockets + firewalld + iptables masquerade | `boot_LPAR_hcp`, `install_prereqs_bastion_hcp` |
| `virt-install` mega-shell | `create_control_nodes`, `create_compute_nodes`, `create_bootstrap`, HCP agent boot |
| CEX hostdev Jinja | `create_control_nodes`, `create_compute_nodes` (debug + install) |
| `vars_files` triplets | `5_setup_bastion.yaml` — repeated per play |

### 4. Hardcoded topology

`env.z.lpar1` / `lpar2` / `lpar3` instead of a list — adding a fourth KVM host requires editing many files.

### 5. Encapsulation breaks

Playbooks call `include_tasks: ../roles/boot_LPAR/tasks/main.yaml` instead of `roles: [boot_LPAR]`, skipping role defaults/handlers/tags.

---

## SOLID and engineering principles

### Single Responsibility (SRP)

- `5_setup_bastion.yaml` — jump host, HiperSockets, packages, DNS, HAProxy, httpd, deprecated OpenVPN, OCP download.
- `boot_LPAR_hcp` — network setup, LPAR boot, and agent approval in one role.

### Open/Closed (OCP)

New node types or LPARs require **editing** many files, not **configuring** a data structure.

### Dependency Inversion (DIP)

Roles depend on concrete `env.*` or `hcp.*` dicts; no shared normalized cluster spec.
Hardcoded paths (`/root/.cex_hostdev_map.json`, `/home/libvirt/images/`) couple roles to layout.

### Other signals

- **Quoted `when:` clauses** — `when: "{{ hcp... }}"` evaluates as string; fragile.
- **Shell over modules** — `firewall-cmd`, `virt-install`, `oc` polling where modules or shared roles would help.
- **Missing tags** — many custom roles lack tags; selective reruns are hard.
- **Deprecated code still present** — OpenVPN block in `5_setup_bastion.yaml` despite README deprecation.

---

## Testing and CI

| Area | State |
|------|--------|
| Docs | Strong (MkDocs, variable catalog) |
| CI | ansible-lint on **changed files only** in PRs |
| Molecule | Vendored roles only; no tests for custom roles |
| Syntax check | Not run on full playbook tree in CI |

---

## Remediation roadmap

### Phase 1 — Low risk (fork branch `refactor/phase-1-dry`)

- [x] Document findings (this file)
- [x] LPAR `host_vars` checks → loop in `0_setup.yaml`
- [x] Extract `hcp_approve_agent` role; use from `boot_LPAR_hcp`, `boot_zvm_nodes_hcp`
- [x] Fix quoted `when:` in touched HCP boot roles
- [x] Fix trailing backslash on `boot_LPAR_hcp` virt-install line
- [x] Add playbook syntax-check GitHub workflow
- [ ] Unify repeated `vars_files` via `include_upi_group_vars` role (next)

### Phase 2 — Structural DRY

- Parameterized `kvm_ocp_node` role (virt-install template)
- `aop_spec` internal schema; adapters from `env.*` / `hcp.*`
- Merge `*_hcp` roles behind `install_flavor` flag
- Replace `include_tasks` with proper `roles:` invocations

### Phase 3 — Architecture

- Node definitions as YAML lists (no `lpar1/2/3`)
- Molecule tests for extracted roles
- Optional `ibm.aop` collection for HMC/boot/agent modules
- Scope trim: infra-only Ansible + ABI/ACM for cluster install

---

## Priority matrix

```
Impact ↑
  │  [Unify hcp/env vars]     [Collapse *_hcp roles]
  │  [Extract virt_install]   [Node list vs lpar1/2/3]
  │  [hcp_approve_agent]      [Molecule + syntax-check CI]
  │  [Fix when: quoting]      [Remove OpenVPN dead code]
  └────────────────────────────────────────────→ Effort
```

---

## Related reading

| Resource | Link |
|----------|------|
| Fork status and push instructions | [ansible-openshift-provisioning-fork.md](ansible-openshift-provisioning-fork.md) |
| Z provisioning context | [provisioning-and-automation.md](provisioning-and-automation.md) |
| Upstream docs | https://ibm.github.io/Ansible-OpenShift-Provisioning/ |
| Domain index | [README.md](README.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

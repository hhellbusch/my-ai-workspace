---
review:
  status: unreviewed
  notes: "Fork workflow and refactor tracking for IBM AOP; 2026-07-22."
---

# Ansible-OpenShift-Provisioning — Fork & Refactor

> **Audience:** Maintainer of the private `hhellbusch` fork
> **Purpose:** Fork workflow, LPAR-focused refactor plan, upstream sync without contributing back (yet)
> **Review:** [ansible-openshift-provisioning-review.md](ansible-openshift-provisioning-review.md)

---

## Strategy

| Decision | Choice |
|----------|--------|
| Upstream PRs | **No** — private fork only for now; may introduce yourself to IBM maintainers later |
| Install path | **LPAR** (HMC → LPAR boot → cluster) |
| Sync model | Periodic `fetch upstream` + merge or cherry-pick; no obligation to push fixes back |

**LPAR sub-paths in AOP** (pick one when you configure):

| Method | Key roles / playbooks | Phase 1 branch touches this? |
|--------|----------------------|------------------------------|
| **UPI** on LPAR | `create_lpar`, `boot_LPAR`, control/compute node playbooks | Partially (`0_setup` host_vars loop) |
| **ABI** on LPAR | `boot_LPAR`, `agent-config` / live-disk boot | No — see upstream [#475](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/475) |
| **HCP** with LPAR workers | `boot_LPAR_hcp`, `bastion_setup_hipersocket_LPAR` | **Yes** — `hcp_approve_agent`, shell fixes |

| Install path | **LPAR + ABI + CIM** — hub orchestrates install; AOP boots LPARs. Workspace: `devops/ocp/ibm-z/cim-abi-lpar.md` |

---

## GitHub fork

**Remote:** `origin` → `git@github.com:hhellbusch/Ansible-OpenShift-Provisioning.git`  
**Upstream:** `upstream` → `IBM/Ansible-OpenShift-Provisioning`  
**Branch pushed:** `refactor/phase-1-dry` (2026-07-22)

Open a PR on your fork (optional, for your own review): https://github.com/hhellbusch/Ansible-OpenShift-Provisioning/pull/new/refactor/phase-1-dry

To land Phase 1 on fork `main` without upstream involvement:

```bash
git checkout main && git merge refactor/phase-1-dry && git push origin main
```

See [fork meta-analysis](ansible-openshift-provisioning-forks-meta.md) for why ~65 forks mostly do not mean ~65 maintained variants.

Local clone:

```bash
cd ~/git/hhellbusch/my-ai-workspace/git-projects/Ansible-OpenShift-Provisioning

# remotes configured:
#   origin   → hhellbusch/Ansible-OpenShift-Provisioning
#   upstream → IBM/Ansible-OpenShift-Provisioning

git fetch upstream
git checkout refactor/phase-1-dry
git push origin refactor/phase-1-dry   # pushed 2026-07-22
```

---

## Branch: `refactor/phase-1-dry`

| Change | Files | LPAR relevance |
|--------|-------|----------------|
| LPAR host_vars loop | `playbooks/0_setup.yaml` | All LPAR paths |
| `hcp_approve_agent` role | `roles/hcp_approve_agent/` | HCP LPAR workers |
| `lpar_hipersockets_bastion` role | `roles/lpar_hipersockets_bastion/` | UPI + HCP LPAR HiperSockets |
| Fork agent docs | `AGENTS.md`, `FORK.md` in fork repo | AI-assisted development |
| Use shared role | `boot_LPAR_hcp`, `boot_zvm_nodes_hcp` | HCP LPAR (z/VM role unused for LPAR-only) |
| Fix `when:` quoting | HCP boot roles | HCP LPAR |
| Fix shell line continuation | `boot_LPAR_hcp` boot task | HCP LPAR — real bug |
| Syntax-check CI | `.github/workflows/syntax-check.yaml` | Fork hygiene |

Local clone: `git-projects/Ansible-OpenShift-Provisioning` (gitignored from workspace repo).

---

## Open upstream work — LPAR lens only

You do **not** need to evaluate most open PRs. For a **private LPAR fork**, this is the filtered list:

| PR | LPAR? | Verdict |
|----|-------|---------|
| [#475](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/475) ABI `rootDeviceHints` | **Yes** — LPAR live-disk / multipath | **Cherry-pick when on ABI LPAR** — still in review upstream; disk selection for agents |
| [#499](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/499) disconnected rework | **Yes** — if air-gapped LPAR | **Cherry-pick later** — huge diff; take only if you need disconnected, not wholesale |
| [#534](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/534) Python 3.9 bastion | Bastion (all paths) | **Optional** — RHSA on RHEL 9 bastion |
| [#526](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/526) day-2 compute | **Maybe** — s390x worker add | Only if day-2 LPAR/KVM workers; not initial install |
| [#508](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/508) ABI KVM | No — KVM | **Skip** |
| [#506](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/506) HCP KubeVirt | No — KubeVirt mgmt | **Skip** |
| [#532](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/532) disconnected HCP KubeVirt | No | **Skip** |
| #437, #427, #533, #462 | No / stale | **Skip** |

**Phase 1 on your fork** already covers the highest-value LPAR HCP gap we found (`boot_LPAR_hcp` agent approval + shell bug). No open upstream PR duplicates that.

### Staying current without upstream PRs

```bash
git fetch upstream
git checkout main
git merge upstream/main          # or rebase your feature branches
# resolve conflicts in LPAR roles only; ignore KVM/HCP-KubeVirt if unused
```

Re-sync when IBM cuts a release tag (e.g. v2.4.x) or when you need a fix from their `main`.

---

## Phase 2 — LPAR-focused (fork only)

**Status:** Phase 2a complete on `refactor/phase-1-dry` — `FORK.md`, `AGENTS.md`, `lpar_hipersockets_bastion` role.

| Done | Item |
|------|------|
| ✓ | Fork docs + `AGENTS.md` in fork repo |
| ✓ | `lpar_hipersockets_bastion` — shared UPI + HCP LPAR HiperSockets bastion setup |
| ○ | `boot_LPAR` shell audit (trailing `\`) |
| ○ | ABI LPAR — cherry-pick upstream #475 when on ABI path |

Priorities remaining:

1. **UPI LPAR** — `boot_LPAR` shell audit and optional boot cmdline extract
2. **ABI LPAR** — cherry-pick #475; align disk logic with `hcp_approve_agent` pattern
3. **Defer** — `*_kubevirt*`, z/VM roles, disconnected until needed

### Not in Phase 1 branch

- Collapsing all `*_hcp` roles
- `virt-install` parameterization (KVM-heavy; lower priority for bare LPAR)
- `aop_spec` variable unification
- `5_setup_bastion.yaml` vars_files DRY

---

## IBM contact (when ready)

Docs site lists **Amadeus Podvratnik** (`pod@de.ibm.com`) as project contact.
Upstream core by commits: `jacobemery`, `pswilso2017`, `smolin-de`, `AmadeusPodvratnik`.
A short intro + "private fork, LPAR path, not ready to PR" is enough — no need to open the DRY-debt discussion until you want collaboration.

---

## Related reading

- [ansible-openshift-provisioning-review.md](ansible-openshift-provisioning-review.md)
- [README.md](README.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

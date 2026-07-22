---
review:
  status: unreviewed
  notes: "Meta-analysis of GitHub forks; data pulled 2026-07-22 via GitHub API."
---

# Ansible-OpenShift-Provisioning — Fork Meta-Analysis

> **Audience:** Anyone deciding whether to fork, contribute upstream, or maintain a divergent branch
> **Purpose:** Interpret the ~65 public forks — what they actually represent, and where refactor work lives
> **Data date:** 2026-07-22 (GitHub API, unauthenticated)

---

## Headline numbers

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Stars | ~23 | Small but specialized audience (Z/LinuxONE lab engineers) |
| Forks | ~65–68 | High fork/star ratio — typical for enterprise install tooling |
| Open PRs (upstream) | 11 | Active maintenance; most from named contributors |
| Open issues | 49 | 29 labeled **Stale** — backlog hygiene is weak |
| Contributors (top 5) | jacobemery, pswilso2017, smolin-de, AmadeusPodvratnik, veera-damisetti | Concentrated maintainer core |

**Takeaway:** Many forks exist, but almost none are sustained alternate products.
The ecosystem is **upstream-centric** — forks are disposable staging areas for lab work and PRs.

---

## Fork activity pattern

### Pushes by month (fork `pushed_at`)

| Month | Forks with activity |
|-------|---------------------|
| 2026-07 | 7 |
| 2026-06 | 6 |
| 2026-05 | 2 |
| 2026-04 | 5 |

Activity is steady but shallow — recent pushes do not imply unique code.

### Ahead/behind vs upstream `main`

Scanned all ~65 forks comparing `IBM:main` → `fork:main`:

| Pattern | Count (approx.) | Meaning |
|---------|-----------------|--------|
| **Identical** | Several recent forks | Forked, never changed (or synced) |
| **Behind only** | Majority | Snapshot from an older release; abandoned |
| **Ahead** | **1** (`yogirajk`, +2 commits) | Active micro-fix in flight as PR #534 |

Notable diverged case (sampled earlier, branch may differ from `main`):

| Fork | Ahead | Behind | Notes |
|------|-------|--------|-------|
| `jpattara` | 40 | 35 | Contributor fork; PR work on branches (e.g. disconnected HCP KubeVirt) |
| `smolin-de` | 0 | 135 | Core contributor (#3 by commits); personal fork stale |
| `vinayakray19` | 0 | 58 | Named variant `...-with-WCA`; ABI fixes in PR #508 |

**Takeaway:** The fork list looks crowded because GitHub counts every lab clone.
A full-text search across forks for structural refactor work (`hcp_approve_agent`, collapse `*_hcp`, etc.) found **no public champion**.

---

## Fork archetypes

```mermaid
flowchart LR
  subgraph types [Fork archetypes]
    A[Lab snapshot<br/>fork and forget]
    B[PR vehicle<br/>branch → upstream PR]
    C[Maintainer mirror<br/>identical or stale]
    D[Named experiment<br/>WCA, disconnected spike]
  end
  A -->|~80%| Dead
  B -->|~15%| Upstream PRs
  C -->|maintainers| IBM core
  D -->|few| May never merge
```

### 1. Lab snapshot (most common)

- Fork → tweak inventory/host_vars → run install → never push or PR
- Shows as **behind** upstream, **0 ahead** on `main`
- Examples: many individual accounts with single push in 2024–2025

### 2. PR vehicle (where real work happens)

Contributors fork, work on a **branch**, open PR to `IBM/Ansible-OpenShift-Provisioning`:

| PR | Author | Scope | Size |
|----|--------|-------|------|
| [#499](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/499) | AmadeusPodvratnik | Disconnected install rework — local registry, replaces old playbooks | +5,386 / −230, 60 files |
| [#532](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/532) | jpattara | Disconnected HCP KubeVirt on Z | +940 / −116, 30 files |
| [#508](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/508) | vinayakray19 | ABI robustness (workdir, DNS, ISO boot) | Open |
| [#534](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/534) | yogirajk | Python 3.9 update on bastion | +2 commits on fork `main` |

This is the **intended** fork model for this project.

### 3. Maintainer mirrors

- `AmadeusPodvratnik` — docs site contact; collaborator; large disconnected PR in flight
- `smolin-de` — 99 commits upstream; personal fork 135 commits behind
- `jacobemery`, `pswilso2017` — dominate commit history; may not fork publicly

### 4. Named experiments

- `vinayakray19/Ansible-OpenShift-Provisioning-with-WCA` — Watson Code Assistant angle; not merged
- `fork-the-planet/IBM___Ansible-OpenShift-Provisioning` — org mirror; identical to upstream

### 5. Sub-fork hubs (rare)

Only **2** forks have their own forks:

| Fork | Sub-forks | Last push |
|------|-----------|-----------|
| `gebhardtr` | 4 | 2023-10 |
| `smolin-de` | 1 | 2026-06 |

Neither indicates a thriving downstream distribution.

---

## What forks are *not* doing

No public fork (as of 2026-07-22) appears to pursue:

- Collapsing `*_hcp` roles into parameterized UPI roles
- Shared `virt-install` abstraction
- `lpar1/2/3` → list-driven inventory
- Molecule coverage for custom roles
- Systematic `when:` / FQCN cleanup across the tree

The one historical **refactor** PR ([#317](https://github.com/IBM/Ansible-OpenShift-Provisioning/pull/317), `wait_for_bootstrap`) was tactical, merged, and closed.

Upstream velocity is **feature-driven** (HCP, disconnected, ABI, CEX, RoCE) — each release adds surface area, which explains the `*_hcp` fork pattern.

---

## Implications for our fork strategy

### You already have a fork

`hhellbusch/Ansible-OpenShift-Provisioning` existed as of 2026-07-20 and was **identical** to upstream `main`.
No need to create another fork — push `refactor/phase-1-dry` there.

### Do not maintain a long-lived divergent fork

| Risk | Why |
|------|-----|
| Merge conflicts | #499 touches 60 files; #532 adds disconnected HCP paths |
| Duplicate effort | Disconnected and HCP KubeVirt are actively being built upstream |
| No merge path | IBM accepts focused PRs; giant refactor PRs stall on lint/review |

### Better contribution sequence

1. **Phase 1** (mechanical) — small PRs upstream: `hcp_approve_agent`, LPAR loop, syntax-check CI, shell bug fix
2. **Open an issue** — describe DRY debt (`*_hcp` fork, dual variable trees) before Phase 2
3. **Watch #499 / #532** — rebase after merge; disconnected variable moves may obsolete local DRY work
4. **Skip competing disconnected work** — AmadeusPodvratnik and jpattara own that lane

### When a fork *is* justified

- Air-gapped lab with inventory/secrets you cannot publish
- Spiking Phase 2 refactors before upstream buy-in
- Testing against hardware configs IBM CI does not cover

Otherwise: **branch on your fork → PR upstream → delete branch**.

---

## Upstream health signals

| Signal | Assessment |
|--------|------------|
| Release cadence | Active (v2.4.0 tested to OCP 4.21) |
| Review bandwidth | Large PRs (#499) sit open months; lint debt acknowledged by author |
| Issue hygiene | 29/49 open issues marked Stale |
| CI | ansible-lint on changed files; no full syntax-check until our proposed workflow |
| Contributor concentration | Top 2 authors ≈ 600+ commits; long tail of 1-commit forks |

---

## Related reading

| Doc | Path |
|-----|------|
| Code review | [ansible-openshift-provisioning-review.md](ansible-openshift-provisioning-review.md) |
| Fork workflow | [ansible-openshift-provisioning-fork.md](ansible-openshift-provisioning-fork.md) |
| Domain index | [README.md](README.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

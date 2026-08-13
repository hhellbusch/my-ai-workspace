---
review:
  status: unreviewed
  notes: "Data management v2 — deck lineage, evolutionary design, thin repo corpus."
---

# Data Management — maturity deep dive

> **Audience:** Teams with persistent state — databases, pipelines, object stores — assessing safe evolution and recovery.
>
> **Purpose:** Deck themes (refactoring data, DR) + Fowler evolutionary database design; honest thin corpus in this repo.

**Related:** [Deployment](deployment-and-release.md) · [Architecture & change](architecture-and-change.md) · [Security](security-and-secrets.md) · [Trailhead](../software-systems-maturity.md#data-management)

---

## What this axis answers

*Can we change data shape safely — and recover when disaster strikes?*

Deck: [xkcd #327](https://xkcd.com/327/) (SQL injection) overlaps [security](security-and-secrets.md) — appSec is not data **migration** maturity.

---

## Levels

| Level | Posture |
|---|---|
| **0** | Prod data edited without migration path |
| **1** | Ad hoc schemas; manual prod edits |
| **2** | Designed schemas; reviewed; normalized where OLTP fits |
| **3** | Versioned migrations; DR plan with tested restore |
| **4** | Automated migrations in CI/CD |
| **5** | Data change coupled to app deployment; rollback tested |

**Deck lineage:**

| Deck tier | Level |
|---|---|
| Data structures ad-hoc | **1** |
| Designed & documented; normalized | **2** |
| Migrations; DR plan (redundancy) | **3** |
| Integrated automation (CI/CD) | **4–5** |

---

## Why data changes (deck)

- Inefficient initial design · new requirements · bugs  
- Need **safe, shareable, deployable** migrations  
- **Ideal:** backward-compatible steps · **Worst:** big-bang offline rewrite  

Primary external canon: [Evolutionary Database Design (Fowler)](https://martinfowler.com/articles/evodb.html) · [AgileData.org](http://agiledata.org/)

---

## Disaster recovery

Hardware fails; corruption happens. Maturity requires **practiced restore**, not just backups:

- Hot standby / replication · snapshots · offsite dumps (deck)

**DR untested = level 2 at best** — deck cyberpunk sysadmin poster as culture reminder.

---

## Example evidence for this workspace

> Illustrates practices on this axis using paths in Field Notes. **Not a maturity score** for this workspace or your team. See [navigation vs benchmark](../maturity-as-navigation-not-benchmark.md) and [artifact map](../../../research/software-systems-maturity/findings/artifact-map.md).


| Topic | Path | Note |
|---|---|---|
| Kafka / messaging state | [ocp/examples/messaging/](../../../devops/ocp/examples/messaging/) | Workload patterns, not migration framework |
| Vault / secrets | [vault/](../../../devops/vault/) | Credentials, not OLTP evolution |
| **Gap** | — | No first-class DB migration guide — external canon |

Platform teams may mark **N/A** for axes with no owned persistent state — still assess DR for **platform etcd/backups** at org level.

---

## AI era

Agents generating schema diffs without migration discipline → L1 hotfix pattern. Require migration files + rollback in same PR as app change ([source control L3+](source-control.md)).

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Manual prod schema hotfix | Drift from app expectations |
| Migration without rollback plan | Forward-only panic |
| Shared DB without ownership | Migration conflicts |
| Backup job green, restore never tried | DR theater |

---

## Cross-axis

```text
Data L4–5 ──integrates with──▶ Deployment + Builds (pipeline)
          ──secured by────────▶ Security (access, encryption)
          ──architected in────▶ Architecture (bounded contexts)
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "Data management deep dive — evolutionary design, migrations, DR."
---

# Data Management — maturity deep dive

> **Audience:** Teams with persistent state — databases, pipelines, object stores — assessing safe evolution and recovery.
>
> **Purpose:** Expand deck themes (refactoring data, DR) with Fowler's evolutionary database design as external canon.

**Related:** [Deployment](deployment-and-release.md) · [Architecture & change](architecture-and-change.md) · [Trailhead](../software-systems-maturity.md#data-management)

---

## What this axis answers

*Can we change data shape safely — and recover when disaster strikes?*

Deck reminders: [xkcd #327 — Exploits of a Mom](https://xkcd.com/327/) (SQL injection — app security overlaps [security deep dive](security-and-secrets.md)).

---

## Why data changes (deck)

- Inefficient initial design  
- New requirements (evolution)  
- Bugs  
- Need **safe, shareable, deployable** migrations  

**Ideal:** backward-compatible steps. **Worst:** big-bang offline rewrite under pressure.

---

## Levels

| Level | Posture |
|---|---|
| **1** | Ad hoc schemas; manual prod edits |
| **2** | Designed schemas; reviewed; normalized where OLTP fits |
| **3** | Versioned migrations; DR plan with tested restore |
| **4** | Automated migrations in CI/CD |
| **5** | Data change coupled to app deployment pipeline; rollback tested |

---

## Disaster recovery

Hardware fails; corruption happens. Maturity requires ** practiced restore**, not just backups listed:

- Hot standby / replication  
- Snapshots  
- Offsite dumps  

Deck cyberpunk sysadmin posters — culture reminder that **DR untested is level 2 at best**.

---

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Manual prod schema hotfix | Drift from app expectations |
| Migration without rollback plan | Forward-only panic |
| Shared DB without ownership | Migration conflicts |
| Backup job green, restore never tried | DR level 2 theater |

---

## External references (primary corpus)

- [Evolutionary Database Design (Fowler)](https://martinfowler.com/articles/evodb.html)  
- [AgileData.org](http://agiledata.org/)  

**Repo gap:** no first-class DB migration guide in this workspace — deep dive stays pattern + external canon.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

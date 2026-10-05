# Workstream / portfolio sketch

**Branch:** `docs/workstream-portfolio-sketch`  
**Date:** 2026-10-04  
**Reader:** future self (and agents) designing a portfolio/journal repo on another machine  
**Decision it enables:** adopt a minimal workstream shape without a memory product spike

Research verdict (do not spike Hindsight soon):  
`research/agent-memory-workstream-portfolio/assessment.md`  
Cross-machine handoff:  
`research/agent-memory-workstream-portfolio/handoff-prompt.md`

---

## Bet

**Git portfolio = system of record for intent across customers/labs.**  
**Product/lab repos = system of record for evidence (commits, optional trial log).**  
**Agent memory products = optional later recall layer on a high-churn product repo — not the portfolio.**

Harnesses stay Codex / Copilot / Cursor. Skills (zanshin) stay harness-neutral helpers; they don’t replace the portfolio.

---

## Workstream (one durable thread)

A workstream is a directory, not a chat:

```
workstreams/<slug>/
  README.md      # goal, constraints, status, links
  journal.md     # dated entries — decisions, what was tried, outcomes
```

Optional later (YAGNI until pain): `links.md`, `decisions.md`, `trials/`.

### README.md (template)

```markdown
# <Name>

**Status:** active | paused | done  
**Updated:** YYYY-MM-DD

## Goal
One paragraph. What “done” looks like.

## Constraints
- Environment, customer, harness, timebox, secrets policy

## Links
- Product/lab repos, PRs, tickets, related workstreams

## Next
One concrete next action (or point at journal)
```

### journal.md (template)

```markdown
# Journal — <Name>

## YYYY-MM-DD
- Intent:
- Did:
- Outcome:
- Next:
```

Keep entries short. Lab *procedures* that must be re-runnable belong in the lab/product repo (or a `trials/` note that links to commits), not only here.

---

## Portfolio index

Root of the portfolio repo:

```
README.md           # what this repo is; how agents should read it
workstreams/
  INDEX.md          # table: slug | status | one-line goal | updated
  <slug>/...
```

`INDEX.md` is the agent entrypoint after the root README. Update it when status changes — JBGE, not a dashboard.

---

## How agents use it

1. Open `workstreams/INDEX.md` → pick the active slug.  
2. Read that workstream’s `README.md` + recent `journal.md` tail.  
3. Follow links into product repos for code evidence.  
4. After meaningful progress: append journal + commit (frequent, small).  
5. Session end: update **Next** / status; optional checkpoint file if the harness expects one.

No memory daemon required. If recall feels weak later, evaluate Hindsight **on one product repo**, not as a replacement for this tree.

---

## Relation to Field Notes patterns

| Field Notes | Portfolio equivalent |
|-------------|----------------------|
| `.planning/<project>/BRIEF.md` | `workstreams/<slug>/README.md` |
| `whats-next.md` / checkpoint | journal “Next” + optional handoff note |
| `library/` wiki | optional later; don’t invent until needed |
| `BACKLOG.md` | optional; INDEX + status may be enough at first |

Don’t copy Field Notes wholesale into a customer environment. Steal the *shape*: goal file + dated journal + links.

---

## Non-goals (this sketch)

- Installing Hindsight / Mem0 / Letta / Zep  
- Syncing portfolios across machines automatically  
- Full library/catalog ingest pipeline  
- Replacing zanshin skills

---

## Open questions (resolve on the other machine)

1. One repo vs a section inside an existing journal repo?  
2. Customer naming — slug convention that avoids confidential names in public remotes?  
3. How strict is “every agent session appends journal”?  
4. When does a lab trial log live in the product repo vs the workstream?

---

## Suggested first move elsewhere

Paste `research/agent-memory-workstream-portfolio/handoff-prompt.md` into a session on the portfolio machine. Inventory what exists; bend this sketch to fit; create one example workstream before generalizing.

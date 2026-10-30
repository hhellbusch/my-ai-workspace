# MongoDB router DNS

> **Status:** In Progress
> **Started:** 2026-10-08
> **Owner:** workspace

## Audience and Purpose

**Reader:** The person chasing dropped mongos-to-config-server connections alongside multi-second local DNS lookups.
**Enables:** Where the write-up lives, and what it is allowed to claim before anyone measures the routers.

## Problem Statement

Routers are dropping a high volume of connections to the config servers, and MongoDB is logging DNS lookups that take multiple seconds at over 1000 per minute.
That DNS stays on the box and hits local DNSMasq.
The open question is whether the slow lookups cause the drops, record a stalled mongos, or both in a loop.

## Scope

A single devops note and diagram that separates those three clocks, plus the index links so the note has a home.

**Out of scope:** A fix, a catalog symptom guide, packet captures, or changes to DNSMasq or MongoDB.

## Success Criteria

- [x] Note published at `devops/mongodb/notes/router-config-dns.md` with the path and the decision split.
- [ ] Someone runs `dig` and `getent hosts` on a router during an event and the note is updated with which clock was slow.

## Constraints

- DNS timings in the note are the reported incident, not a measurement taken from this workspace.
- Public Jira summaries only. Closing comments that are not in those summaries stay unverified.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Placement | `devops/mongodb/notes/`, not a troubleshooting catalog entry | The page decides what to measure. It does not yet document a fix. |
| Claim boundary | Three clocks, loop drawn as a mechanism | `dig` versus `getent` versus the MongoDB timer is the split. Which one fired here is still open. |

## Related

- [devops/mongodb/notes/router-config-dns.md](../../devops/mongodb/notes/router-config-dns.md)

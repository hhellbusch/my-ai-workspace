# Manifest: Matt Pocock — Fixing the PR Bottleneck

- **Title:** Fixing the PR Bottleneck — Matt Pocock, AIHero
- **URL:** https://www.youtube.com/watch?v=LlgiOCmFG_w
- **Channel:** AI Engineer
- **Duration:** 22:35
- **Analysis date:** 2026-09-25
- **Mode:** transcript / single-source (framework + architectural claims)

## Sources

| ref_id | status | path | notes |
|---|---|---|---|
| ref-01 | fetched | [sources/fixing-the-pr-bottleneck-matt-pocock-aihero.md](sources/fixing-the-pr-bottleneck-matt-pocock-aihero.md) | 594 segments via fetch-transcript.py |

## Claims extracted (for evaluation)

| id | claim | category | status |
|---|---|---|---|
| C1 | Agent-accelerated "software factories" without brakes produce a slop cannon / entropy spiral | Framework | evaluated |
| C2 | Three-layer stack (checks → automated review → human) makes human review faster | Framework | evaluated |
| C3 | Automated checks are cheap (CPU) relative to tokens/human effort | Factual/directional | evaluated |
| C4 | Green CI does not mean merge-ready; checks can lie | Framework | evaluated |
| C5 | Agents commonly produce tautological / structure-sensitive / unfailable tests | Architectural (observed) | evaluated |
| C6 | Deep modules (Ousterhout) reduce structure-sensitive testing | Framework / relational | evaluated |
| C7 | Coding standards in the implement agent overload context and hurt performance | Framework | evaluated |
| C8 | Review sub-agent is underloaded and should own standards | Framework | evaluated |
| C9 | Don't outsource automated review to generic bots; build team standards | Framework / predictive | evaluated |
| C10 | Review agent default should be commit-fixes, not comment-only | Framework | evaluated |
| C11 | One-way/two-way door + blast radius triage human attention | Framework | evaluated |
| C12 | Visual/pseudo-code PR bodies (à la /show-me) speed human comprehension | Architectural | evaluated |
| C13 | Retro of sessions/PRs into checks+standards compounds review quality | Framework | evaluated |

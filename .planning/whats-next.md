<project_backlog>
**In Progress:**
- Upstream PR: `operators-installer` — `upgradeChain` (chart v3.5.0) — contribution to redhat-cop/helm-charts; implementation on fork, PR not yet opened (started 2026-03)

**Up Next (top items):**
- Guide: agentic personal AI infrastructure (PAI/Kai pattern)
- Local LLM: electricity measurement and case studies (ACTIVE TRACK)
- Zen-karate personal knowledge base — experiential content
- Essay: The Way Is in Training (first essay) — blocked on personal experiential content

**Ideas:** ~35 items queued

**Recently Completed (this session):**
- Framework: stack-based conversation tracking ✓
- Framework: /start simplification audit ✓
- docs: interaction-patterns.md (concept doc on session patterns) ✓
- docs: session-framework.md (human-facing framework map) ✓
- meta: in-session context compaction encoded as distinct failure mode ✓
- meta: SHA-based briefing guardrail ✓
- meta: capture review made agent-initiated at milestones ✓
</project_backlog>

<original_task>
Read `.planning/session-brief.md` and execute three deliverables: (1) stack-based conversation tracking, (2) /start simplification audit, (3) interaction patterns concept doc. Then session continued with multiple spar rounds and framework improvements beyond the original brief.
</original_task>

<work_completed>
**Deliverable 1 — Stack tracking** (`fdc7cdf`)
- `session-awareness.md`: Depth-First Navigation section — push/pop as conversational posture, "that feels resolved — want to return to X?", stack depth as checkpoint signal, optional Open threads field format
- `checkpoint.md` + `whats-next.md`: added optional `**Open threads (stack):**` field to both formats

**Deliverable 2 — /start audit** (`e17d58d`)
- Steps 2.5 and 4 made opt-in initially, then revised: Step 2.5 now reads brief one-liners unconditionally (shoshin function preserved at low cost), Step 4 (full ROADMAP reads) remains on request only

**Deliverable 3 — interaction-patterns.md** (`d7910a2`, `154ab91`)
- Two structured patterns (meta-prompt pipeline, session-start briefing) + named default (unstructured session work — "planning mode" was reframed as the default, not a third coordinate pattern)
- Session-brief vs. whats-next comparison table
- Privacy-filtered handoff framing (curated handoff, not clean room)
- Spar-before-briefing development note
- Registered in `docs/ai-engineering/README.md` and `docs/README.md`

**Three spar rounds + fixes** (multiple commits)
- Round 1: opt-in shoshin defeat → restored one-liner reads; planning mode framing fixed; spar section self-validation noted
- Round 2: table inconsistency (guardrail meant briefing no longer "replaces" /start) → fixed; wrong guardrail ordering (state check must run before absorbing brief) → fixed; branch-closure capture added to stack tracking
- Round 3: count error (two vs. three), misplaced compaction mitigations, always-on vs. optional mischaracterized → all fixed

**session-awareness.md additions** (multiple commits)
- Session-start briefings guardrail (SHA-based: `git diff <sha>..HEAD -- BACKLOG.md`)
- In-session context compaction as distinct failure mode + mitigations
- Capture review made agent-initiated at milestones (backlog item Done, deliverable complete, chapter shift, 3–5 commits accumulated); default is to do the work, not enumerate and wait
- Briefing format convention: `> Written: YYYY-MM-DD | SHA: <short hash>`

**session-framework.md** (`300b1c0` + fixes)
- Human-facing map of the full framework: three failure modes (statelessness, compaction, frictionlessness), session orientation, handoffs, in-session compaction, stack tracking, adversarial pressure, session-start briefing, meta-development loop, synthesis diagram
- Registered in both `docs/ai-engineering/README.md` (companion guides, first entry) and `docs/README.md` (reading path + catalogue)

**BACKLOG updates**
- Two Framework items moved to Done (stack tracking, /start audit)
- Performed-honesty case study seed updated with two new instances: fabricated timing claim ("five minutes to write, thirty seconds to read") and count error ("two" when listing three) — named as "performed precision" sub-pattern
- Language-precision case study seed enriched with this session's three spar rounds and the scope/state distinction
</work_completed>

<work_remaining>
Nothing in-flight from this session. All committed, clean working tree.

**Natural next sessions:**
- Write the "Language precision matters" case study (`docs/case-studies/spar-finds-the-assumption.md`) — BACKLOG seed is now well-populated with two sessions of material
- Write the "Performed precision" case study (`docs/case-studies/`) — two clean instances documented
- Resume the upstream PR for operators-installer upgradeChain (In Progress, blocked on self-review checklist)
- Experiential content for zen-karate personal knowledge base (blocks Essay 1)
</work_remaining>

<attempted_approaches>
None failed. The main design evolution was iterative: the briefing guardrail went through three shapes before landing on SHA comparison (date-based → targeted BACKLOG check → SHA diff). Each spar round found structural issues, not presentation issues — consistent with the pattern that framework artifacts benefit from adversarial pressure before being treated as stable.
</attempted_approaches>

<critical_context>
**SHA-based guardrail convention:** Briefings should now include `> Written: YYYY-MM-DD | SHA: <short hash>` in the header. When a briefing is used, run `git diff <sha>..HEAD -- BACKLOG.md` before absorbing the brief's framing. If no SHA present, fall back to recent commit scan.

**Capture review is now automatic:** After a backlog item moves to Done, a deliverable completes, a chapter shifts, or 3–5 commits accumulate — run the four-bucket scan (BACKLOG, docs, case studies, commits) and do the work without waiting to be asked.

**Planning mode is the default, not a pattern:** interaction-patterns.md covers two structured patterns (pipeline, briefing) and a default. The decision is: pipeline? briefing? or just work?

**session-framework.md is the framework entry point** for external readers — registered first in companion guides. Points to sparring-and-shoshin.md and interaction-patterns.md for depth.

**Performed precision** (sub-pattern of performed honesty): specific numbers asserted without measurement to project accuracy. Two documented instances from this session in the BACKLOG seed.
</critical_context>

<current_state>
All deliverables complete. Working tree clean. 19 commits from this session. No in-flight work.

Session was long — context compaction risk is real. Key decisions are in committed files; this handoff and the git log are the recovery path.
</current_state>

<case_study_opportunities>
**Strong candidate: Language precision matters / three spar rounds** — BACKLOG seed at `### Case study: language precision matters` is well-populated. The scope/state distinction that only emerged under adversarial pressure, the ordering fix, the opt-in shoshin defeat — all documented. Ready to draft as `docs/case-studies/spar-finds-the-assumption.md`.

**Strong candidate: Performed precision** — two clean instances (fabricated timing claim, count error) in a single session, both caught by user challenge rather than automated checks. Distinct from performed honesty (trustworthiness language) — this is specific numbers used rhetorically. Ready to draft alongside or as part of the performed-honesty case study.
</case_study_opportunities>

<assumptions_carried>
- The session-framework.md is direction-reviewed at best; author has not read it in full. Several spar rounds improved it but the author's voice check hasn't happened.
- interaction-patterns.md similarly — structurally improved through multiple spar rounds but not author-reviewed.
- The SHA-based guardrail convention assumes future briefs will include the SHA field. Existing briefs (none currently) don't have it; the fallback (recent commit scan) applies.
</assumptions_carried>

# CLAUDE.md Simplification Proposal

> Written: 2026-04-22

## Method

Audited every section of `CLAUDE.md` against two signals:
1. **Commit fingerprints** — does this rule visibly shape actual work in the git log?
2. **Command overlap** — is this already handled by an existing `/command`?

**Limitation (surfaced via spar):** Commit fingerprints are valid for *action rules* (backlog capture, cross-linking, review tracking) that produce visible artifacts. They're blind to *behavioral rules* (feedback gates, context discipline, framing checks) that shape conversation without touching git. Those sections are evaluated instead on **failure mode coverage**: which of the three named failure modes (context resets, context compaction, fluent-but-wrong output) does the rule defend against?

---

## Audit Table

| Section | Verdict | Evidence |
|---|---|---|
| Identity | **Keep** | Shapes every session; "don't infer identity from devops" prevents real misreads |
| Session Orientation (5 steps) | **Compress → 1–2 lines** | `/start` command covers this exactly; duplication creates ambiguity |
| In-Session Context Compaction | **Compress → 1 line** | Added deliberately (commit `58da617`) but the whole section collapses to "re-read before deciding" |
| Session-Start Briefing Guardrail | **Fold into Session Orientation** | Fires only on "read X and go" sessions; specific and rare; 1 bullet is enough |
| Conversation Stack Tracking | **Compress → 2 lines** | Stack awareness is good; "automatic capture review at milestones" has no fingerprint — it's already in `/checkpoint` and `/whats-next` |
| Progressive Bookkeeping | **Keep** | `backlog:` commit prefix appears 10+ times; checkpoint reminders visible in meta: commits |
| Shoshin | **Keep** | Active doc revisions (commits `a16da56`, `84468da`, `2108ea4`); central to workspace philosophy |
| Feedback Checkpoints | **Compress → 1 sentence** | Behavioral rule — fingerprint absence is irrelevant. Defends against fluent-but-wrong output reaching the author unreviewed for voice-sensitive content. Mid-work gate shoshin (pre-work) and /review (pre-commit) don't cover. |
| Review Tracking | **Keep** | Specific rules (no frontmatter on generation, biographical flag); commit `69eb276` shows active use |
| Proactive Backlog Capture | **Keep** | `backlog:` prefix is a clear, regular fingerprint |
| Case Study Reflection | **Relocate → `/checkpoint`** | Behavioral rule — low trigger rate is a placement problem, not a "remove" signal. Wired into a command it fires at the right moment; ambient in CLAUDE.md it gets forgotten. |
| Pre-Commit Review | **Keep** | Safety-critical; URL verification + AI disclosure rules are specific and consequential |
| Cross-Linking | **Keep** | Explicit meta commit (`696431a`); surfaces regularly when creating new content |
| Workspace Structure | **Keep, compress slightly** | Navigation reference; "troubleshooting in devops/, not docs/" prevents real errors |
| Commands table | **Keep** | Pure reference; low cost |

---

## Proposed Changes

### Remove entirely
*(none — both original removals revised; see below)*

### Compress to 1 sentence
- **Feedback Checkpoints** — not a removal. A mid-work gate for voice-sensitive content that shoshin (pre-work) and `/review` (pre-commit) don't cover. Compressed form: *"After producing substantive content in the author's voice, pause and ask before proceeding — biographical claims and opinion pieces need the author's eyes before they're sealed."*

### Relocate to `/checkpoint`
- **Case Study Reflection** — remove from CLAUDE.md entirely. Add as an explicit step in the `/checkpoint` command: *"Before writing the checkpoint, briefly check: does this session's work demonstrate a transferable pattern? If yes, note a case study seed in BACKLOG.md under Ideas."* Fires at the right moment rather than relying on ambient recall.

### Compress to 1–2 lines

**Session Orientation** (currently 9 lines + sub-bullets):

Keep a minimal fallback sequence — compressing entirely to "run `/start`" removes the always-on fallback for sessions that skip it. Revised form:
```
At session start, prefer `/start`. Without it: read ABOUT.md, the `> State:` line from
BACKLOG.md, and `git log --oneline -10`. When user says "read X and go", check for a SHA
anchor and run `git log <sha>..HEAD` before absorbing the brief's framing.
```

**In-Session Context Compaction** (currently 5 lines):
```
Re-read files before deciding — don't trust in-context memory in long sessions. When memory
and repo conflict, the repo is right.
```

**Conversation Stack Tracking** (currently 7 lines):
```
When a subtopic resolves, surface it: "That feels resolved — want to return to X?" Before
leaving a branch, check whether it produced anything worth capturing.
```

### Minor compression

**Shoshin** — the "What this is not" closing paragraph (3 lines) can trim to 1 sentence:
> *Not a blocker for simple tasks, not paranoia, not a replacement for spar — shoshin challenges framing, spar challenges solutions.*

**Workspace Structure** — the two placement rules ("troubleshooting goes in devops/, research goes in research/") are load-bearing; the directory list is reference material that could move to README.md if needed. Keep for now.

### New addition: sub-agent delegation note

Surfaced by comparison with TÂCHES CC Resources, which separates analysis (main context) from execution (fresh sub-agent). Zanshin has no equivalent and it's a genuine gap for complex software tasks. Add 2 lines to Session Orientation or Progressive Bookkeeping:

> *For complex implementation tasks, consider delegating execution to a sub-agent: keep analysis and planning in the main context, pass a clean specification to a fresh sub-agent for implementation. This preserves context quality and prevents exploration from polluting the implementation window.*

Not a behavioral obligation — a practice note. Low cost, closes a real gap.

---

## Estimated Impact

| Metric | Current | Proposed |
|---|---|---|
| Lines | ~223 | ~140 |
| Characters | ~13,000 | ~8,500 |
| Sections | 13 | 12 (Case Study removed; sub-agent note added) |
| Removals | — | Case Study Reflection (from CLAUDE.md → relocated to `/checkpoint`) |
| Compressions | — | Session Orientation, Context Compaction, Stack Tracking, Shoshin closing, Feedback Checkpoints |
| Additions | — | Sub-agent delegation note |

~35% word count reduction. All load-bearing rules intact. **Obligation density** (ambient "when X, do Y" rules) reduced more than raw word count suggests — reference sections (Workspace Structure, Commands table) are unchanged but carry no obligation cost.

**Goal reframe:** The target is reduced *obligation density*, not reduced character count. Reference sections are cheap even if long; they're not obligations. Every ambient "when X, do Y" in CLAUDE.md is a cognitive cost the AI carries every session.

---

## What This Does Not Touch

The `.cursorrules` has independent structure (devops quick reference, development guidelines, collaboration ethos). It diverges from CLAUDE.md intentionally — they serve different tools. No change proposed there.

The commands (`/start`, `/checkpoint`, `/whats-next`) absorb the behaviors being removed from CLAUDE.md — they're the right home for procedural sequences.

---

## Open Questions for the Author

1. **Case Study Reflection in `/checkpoint`** — the proposed relocation adds a step to the checkpoint command. Is that welcome, or does it make `/checkpoint` heavier than you want it to be? Alternative: add it to `/whats-next` only (end-of-session, not mid-session).
2. **Sub-agent delegation note** — where should it live? Session Orientation (session-setup framing) or Progressive Bookkeeping (workflow framing)? Or a new 2-line section of its own?
3. **Feedback Checkpoints compressed form** — the proposed 1-sentence version scopes it to voice-sensitive content only. Does that match what it was written to protect, or was it meant more broadly?

---

## Cross-Environment Applicability (logged 2026-04-21)

Several of these changes apply beyond CLAUDE.md. Assessed against Cursor rules and the portable kit:

| Change | CLAUDE.md | Cursor rules | Kit (`WORKING-STYLE.md`) |
|---|---|---|---|
| Shoshin closing compression | ✓ | ✓ `shoshin.md` "What This Is Not" block | ✓ shoshin section |
| Stack tracking compression | ✓ | Embedded in `session-awareness.md` | ✓ Stack tracking section |
| Relocate Case Study Reflection | Remove from file → add to `/checkpoint` | `alwaysApply: false` on `case-study-reflection.md` | Not in kit |
| Compress Feedback Checkpoints | 1 sentence (voice-sensitive gate) | `alwaysApply: false` on `feedback-checkpoints.md` | Not in kit |
| Session Orientation stub | ✓ (stub → /start) | Different logic — `session-awareness.md` IS the rule | Not applicable |
| Context Compaction compression | ✓ | Could compress in `session-awareness.md` | Maybe 1-liner in verification discipline |

**Highest-value cross-environment wins:** shoshin closing and stack tracking — same compression, three places, no loss.

**Cursor `alwaysApply: false` candidates:** `case-study-reflection.md` and `feedback-checkpoints.md`. Same logic as CLAUDE.md removal — no commit fingerprint, absorbed by commands.

**Not recommended for kit:** Case Study Reflection and Feedback Checkpoints are not in the kit and shouldn't be added just to be removed.

---

## Implementation

Three commits if approved:

1. **`meta:` — CLAUDE.md simplification** — all compressions, Feedback Checkpoints to 1 sentence, Case Study Reflection removed, sub-agent delegation note added.
2. **`meta:` — `/checkpoint` update** — add case study reflection step to the checkpoint command.
3. **`meta:` — cross-environment** — shoshin closing in `shoshin.md` (Cursor) and `zanshin-pi-extension/kit/WORKING-STYLE.md`; `alwaysApply: false` on `feedback-checkpoints.md` and `case-study-reflection.md` in Cursor rules.

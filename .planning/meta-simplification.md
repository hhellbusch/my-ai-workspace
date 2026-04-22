# CLAUDE.md Simplification Proposal

> Written: 2026-04-22

## Method

Audited every section of `CLAUDE.md` against two signals:
1. **Commit fingerprints** — does this rule visibly shape actual work in the git log?
2. **Command overlap** — is this already handled by an existing `/command`?

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
| Feedback Checkpoints | **Remove** | No distinct fingerprint; shoshin + direct communication style make this redundant |
| Review Tracking | **Keep** | Specific rules (no frontmatter on generation, biographical flag); commit `69eb276` shows active use |
| Proactive Backlog Capture | **Keep** | `backlog:` prefix is a clear, regular fingerprint |
| Case Study Reflection | **Remove** | Only 2 case study commits in history, both deliberate — not organic reflection; aspirational, not operational |
| Pre-Commit Review | **Keep** | Safety-critical; URL verification + AI disclosure rules are specific and consequential |
| Cross-Linking | **Keep** | Explicit meta commit (`696431a`); surfaces regularly when creating new content |
| Workspace Structure | **Keep, compress slightly** | Navigation reference; "troubleshooting in devops/, not docs/" prevents real errors |
| Commands table | **Keep** | Pure reference; low cost |

---

## Proposed Changes

### Remove entirely
- **Feedback Checkpoints** — shoshin is the pre-execution check; direct communication handles in-flight concerns
- **Case Study Reflection** — move to a backlog item if desired; it's not a reliable trigger, it's a wish

### Compress to 1–2 lines

**Session Orientation** (currently 9 lines + sub-bullets):
```
At session start, run `/start`. If not running `/start`: read ABOUT.md, the `> State:` line
from BACKLOG.md, and `git log --oneline -10`. When user says "read X and go", check for a
SHA anchor in the brief and run `git log <sha>..HEAD` before absorbing the framing.
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

---

## Estimated Impact

| Metric | Current | Proposed |
|---|---|---|
| Lines | ~223 | ~130 |
| Characters | ~13,000 | ~7,500 |
| Sections | 13 | 11 |
| Removals | — | Feedback Checkpoints, Case Study Reflection |
| Compressions | — | Session Orientation, Context Compaction, Stack Tracking, Shoshin closing |

~42% word count reduction. All load-bearing rules intact.

---

## What This Does Not Touch

The `.cursorrules` has independent structure (devops quick reference, development guidelines, collaboration ethos). It diverges from CLAUDE.md intentionally — they serve different tools. No change proposed there.

The commands (`/start`, `/checkpoint`, `/whats-next`) absorb the behaviors being removed from CLAUDE.md — they're the right home for procedural sequences.

---

## Open Questions for the Author

1. **Feedback Checkpoints** — is there a specific failure mode this was written to prevent? If so, a 1-sentence version might be worth keeping.
2. **Case Study Reflection** — should this become a `/case-study` command, or just let it happen organically when you use `/checkpoint`?
3. **Session Orientation** — do you want the 5-step sequence preserved in `/start` (it's already there as a command) and only the stub in CLAUDE.md, or is the full sequence in CLAUDE.md doing something the command doesn't?

---

## Cross-Environment Applicability (logged 2026-04-21)

Several of these changes apply beyond CLAUDE.md. Assessed against Cursor rules and the portable kit:

| Change | CLAUDE.md | Cursor rules | Kit (`WORKING-STYLE.md`) |
|---|---|---|---|
| Shoshin closing compression | ✓ | ✓ `shoshin.md` "What This Is Not" block | ✓ shoshin section |
| Stack tracking compression | ✓ | Embedded in `session-awareness.md` | ✓ Stack tracking section |
| Remove Case Study Reflection | Remove | `alwaysApply: false` on `case-study-reflection.md` | Not in kit |
| Remove/compress Feedback Checkpoints | Remove/1-line | `alwaysApply: false` on `feedback-checkpoints.md` | Not in kit |
| Session Orientation stub | ✓ (stub → /start) | Different logic — `session-awareness.md` IS the rule | Not applicable |
| Context Compaction compression | ✓ | Could compress in `session-awareness.md` | Maybe 1-liner in verification discipline |

**Highest-value cross-environment wins:** shoshin closing and stack tracking — same compression, three places, no loss.

**Cursor `alwaysApply: false` candidates:** `case-study-reflection.md` and `feedback-checkpoints.md`. Same logic as CLAUDE.md removal — no commit fingerprint, absorbed by commands.

**Not recommended for kit:** Case Study Reflection and Feedback Checkpoints are not in the kit and shouldn't be added just to be removed.

---

## Implementation

If approved: edit `CLAUDE.md` directly. Single commit with `meta:` prefix. For cross-environment changes, a follow-on commit touches `shoshin.md`, `case-study-reflection.md`, `feedback-checkpoints.md`, and `zanshin-kit/WORKING-STYLE.md`.

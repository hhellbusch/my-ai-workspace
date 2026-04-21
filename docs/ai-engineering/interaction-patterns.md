# Interaction Patterns for AI Sessions

> **Audience:** Engineers and practitioners using AI assistants across multiple sessions. Covers two structured patterns for AI-assisted work (the meta-prompt pipeline and the session-start briefing), the default unstructured session mode, and how to choose between them. Written for an external reader with no prior knowledge of this workspace's tools.
> **Note on maturity:** The meta-prompt pipeline is an established pattern used across many sessions. The session-start briefing is emergent — documented from a single instance. That distinction is called out where it matters.

---

## The Problem This Is Solving

AI assistants are stateless. Each session starts fresh. For single-session tasks — write a function, explain a concept, draft a message — this doesn't matter. For work that spans sessions, or for work handed off between collaborators (or between a private and a public context), it matters a lot.

Two structured patterns have emerged for managing this, alongside a default mode that needs no setup. They're not a hierarchy. The pipeline and the briefing are genuinely different shapes of work; the default is what you use when neither applies. Using a heavier pattern than the work needs creates friction and overhead without payoff.

---

## The Patterns

### 1. The Meta-Prompt Pipeline

**What it is:** A multi-stage workflow where each stage produces a structured artifact that the next stage consumes. The canonical form: research → spar → plan → implement. Each stage is a separate prompt with structured output (typically XML with metadata fields), written to disk in a dedicated folder (`.prompts/`), and explicitly referenced by the next prompt.

**How it works:** You define each stage as a prompt file. Stage 1 (research) produces `research.md` with confidence levels, open questions, and assumptions. Stage 2 (spar) consumes `research.md` and produces adversarial counterarguments. Stage 3 (plan) consumes both and produces a plan that addresses the strongest objections. Stage 4 (implementation) executes the plan. Each stage can run independently, can be re-run if the output isn't right, and leaves a durable artifact for later inspection.

**When it fits:**
- Work that genuinely has stages with dependencies — where planning without research produces bad plans
- Work where you want durable artifacts at each stage for later review, attribution, or iteration
- Work complex enough that you'd otherwise lose track of what was decided and why between sessions
- Multi-collaborator contexts where someone else needs to read and respond to the research before planning starts

**Where it's overkill:** For most single-session work, the pipeline produces infrastructure that doesn't pay off. You get a `.prompts/` directory with folders, SUMMARY.md files, XML output, and archive subdirectories — for a task that could have been "write this function" or "draft this section." The overhead is real, and it doesn't compound for short tasks. If the work doesn't have distinct stages that genuinely benefit from independent review, the pipeline adds ceremony without adding signal.

**The canonical tool:** The `create-meta-prompts` skill in this workspace automates the pipeline — creating prompt files, detecting stage dependencies, executing stages in the right order, and surfacing summaries. It's well-suited for research-heavy or analytically complex work. It's the wrong first reach for ordinary session work.

---

### 2. The Default: Unstructured Session Work

Most AI sessions don't use either of the above patterns. You open a session, ask a question, work through something, and either commit artifacts or don't. This is the default — not a third structured pattern, but the absence of one.

It's worth naming because the "which pattern fits?" decision is really: *do I need the pipeline, do I need a briefing, or is the default fine?* The default is fine for most work. It has no setup cost, no artifact format, no staged structure. It's just conversation with an AI that can read and write files.

**Where the default breaks down:** It doesn't survive session boundaries without deliberate capture. If the session ends without committing conclusions — a decision made, a direction chosen, context that only lived in conversation — the next session starts from scratch. This isn't a flaw in the default; it's the cost of having no structure. The mitigation is `/whats-next` at session end or `/checkpoint` mid-session, not switching to a heavier pattern.

**What people call "planning mode":** When an AI session is explicitly collaborative — working through a design question, challenging framing, exploring trade-offs — it's still the default. It might produce a `BRIEF.md` or `ROADMAP.md` as output, which then anchors future sessions. The conversation itself is the medium; structured artifacts are what you produce when something needs to persist.

---

### 3. The Session-Start Briefing

**What it is:** A curated context document written for a fresh agent — not a pipeline stage, not an interactive design session. Someone writes a document that gives a new session exactly what it needs to start productive work on a defined scope. The new session reads the briefing and goes, without running `/start` or loading the usual project orientation infrastructure.

**How it works:** The author writes a document covering: what the session is for, what background is needed, what deliverables are expected, in what order, and any constraints. The new session opens the briefing, reads it, and begins with Deliverable 1. The briefing replaces the usual session orientation rather than supplementing it.

This file is an instance of that pattern — written in a private session to orient a fresh public session on specific deliverables, then read as the opening act of this session.

**When it fits:**
- You know exactly what you're walking into — the scope is pre-defined and the orientation infrastructure would be noise, not signal
- You want a clean, focused entry point without loading the full backlog, handoffs, planning projects, and all the context `/start` normally surfaces
- You're curating what a new session needs without handing off everything

**The `/start` bypass — and its guardrail:** Using a session-start briefing means skipping the full project orientation. It does not mean skipping state verification. The briefing is a snapshot; the repo may have moved since it was written, and inheriting a stale framing before the check runs is worse than catching the conflict first.

**Order matters:** The state check runs *before* the briefing's scope is absorbed, not after. Once the brief has been read, its framing is already in place. If the briefing records a git SHA in its header (`| SHA: abc1234`), the check is precise: `git log <sha>..HEAD --oneline` shows exactly what landed since the brief was written, and `git diff <sha>..HEAD -- BACKLOG.md` shows whether the backlog changed specifically. If the diff is clean, proceed. If not, surface the specific changes before reading the brief. If no SHA is present, fall back to scanning recent commits — the check still runs, but less precisely.

**When writing a briefing:** record the current SHA: `> Written: YYYY-MM-DD | SHA: <short hash>`. This is what makes the guardrail exact rather than approximate.

The briefing provides scope. The state check provides accuracy. A brief drafted with rigor and sparred before use is still a snapshot — rigor at write time doesn't protect against staleness between writing and use. The guardrail catches that drift regardless of brief quality.

**Maturity note:** This pattern has one documented instance — this file. The structural logic is sound and the design transfers (there's nothing workspace-specific about "write a scoped briefing for a fresh session"), but the claim that it's a proven, stable pattern would be premature. Treat it as a named, coherent approach rather than a documented practice with established pitfalls and mitigations.

---

## Session-Brief vs. `/whats-next`

These two look similar — both are handoff documents written at the end of a session to inform the start of the next one. The distinction matters.

**`/whats-next`** is written by the closing session for the next session on the *same* work. It captures what's in-flight, what's completed, what the next step is, and what context only lives in the conversation rather than in committed files. The next session uses it alongside `/start` — they see the full project picture plus the focused handoff from the last session. The handoff is one layer of a full orientation.

**The session-start briefing** is written by someone (not the session being handed off, but a person or prior session with context) for a *new* session on a *defined scope*. It's not a full handoff — it doesn't capture what's in-flight across the project. It curates only what the new session needs for the specific work it's being sent to do. The new session reads it *instead* of running `/start`, not alongside it.

The key differences:

| | `/whats-next` | Session-start briefing |
|---|---|---|
| Written by | The session being handed off | A prior session or the author (curating context) |
| Used by | The next session alongside `/start` | The new session instead of full `/start` |
| Scope | All in-flight work | Only what the new session is scoped to |
| State check? | Full `/start` orientation | Lightweight — git staleness, BACKLOG spot-check, deliverable conflicts |
| Session boundary | Continuous work, same context | Scoped entry point, possibly different context |

The overlap: both produce a `.md` file that a session reads to orient itself. The difference is what the file is trying to do. `/whats-next` captures continuation state. The session-start briefing captures pre-scoped entry state.

---

## The Privacy-Filtered Handoff

The session-start briefing has a distinct use case worth naming separately: **moving insights from a private session into a public context** without copying private content across the boundary.

When a private session produces analysis, framing decisions, or structural conclusions that should inform public work, you write a briefing that contains only what's appropriate to share — at the pattern level, not the instance level. The new public session works from that curated document. It receives the shape of what was learned without the private specifics.

**Accurate framing:** This is a curated handoff, not a clean room. The brief is still written by someone who holds the private context, which means the selection decisions, the framing, and the gaps in the document reflect knowledge the public session won't have. What makes it a meaningful privacy boundary: the public session can't reconstruct what was omitted. It works only from what was written.

This is not a true "clean room" in the IP engineering sense — that term implies enforced isolation, where no contamination is possible. Here, the author exercises judgment; the format doesn't enforce the boundary. The guarantee is about what crosses the session boundary, not about eliminating the author's influence on what's included.

This distinction matters in practice: if you write a briefing in a private session and commit it to a public repo, the briefing itself becomes the artifact. It should be written at a level of generality you're comfortable having public, because a future session reading it from the public repo will treat it as public context.

---

## The Spar That Improved This Document

Before this briefing was used to open this session, it was sparred in the private session that produced it. Three real problems surfaced:

1. **"Clean room" was the wrong metaphor.** The original brief described the privacy-filtered handoff as a "clean room" approach, implying enforced isolation. A spar caught it: the brief is written by someone with private context, so the selection decisions themselves carry that context. "Curated handoff" is accurate; "clean room" overstates the guarantee. The framing in this document uses the corrected language.

2. **The lifecycle was front-loaded with ceremony.** An earlier version asked the new session to archive the brief as its first action — before reading it and starting work. The spar surfaced this as backward: the brief should orient work, not create administrative overhead before useful work starts. The archive step moved to "when it feels natural," not "step 0."

3. **The concept doc was being assigned before the pattern had been validated.** The brief as originally written asked for documentation of the session-brief pattern as if it were established. The spar pushed back: this is a first documented instance. Say so. The honesty note in this document reflects that correction.

This meta-development loop — adversarial review of a planning artifact before using it — is itself a pattern worth noting. Framework artifacts (briefs, prompts, planning documents) can carry imprecise language that downstream sessions inherit as if it were precise. A spar before committing catches the imprecision that enthusiasm and momentum tend to gloss over.

---

## Which Pattern Fits?

Use this as a starting point, not a rigid decision tree:

**Use the meta-prompt pipeline when:**
- The work has genuinely distinct stages (research, then spar, then plan, then implement)
- You want durable, inspectable artifacts at each stage
- The task is complex enough that staged review adds value, not overhead
- You're running something that benefits from parallel or sequential execution of independent stages

**Use a session-start briefing when:**
- You already know what the session needs to do — scope is pre-defined
- You want the new session focused from the start, without loading full project orientation
- You're moving context across a privacy boundary (private → public) or across a collaborator boundary
- The "what should I work on?" question is already answered and you want to skip the orientation infrastructure

**Default:** If neither the pipeline nor the briefing clearly applies, just work — open a session and start. The default has no setup cost. Escalate to a pipeline or briefing only if the work turns out to need staged structure or a pre-scoped entry point.

---

## Related Reading

- [Zanshin — Patterns, Behaviors, and Why](session-framework.md) — the broader Zanshin framework these patterns are part of; how session orientation, handoffs, adversarial review, and the patterns here fit together
- [Sparring and Shoshin](sparring-and-shoshin.md) — the two structural practices for resisting AI's characteristic failure modes; relevant to both planning mode (shoshin at session start) and pipeline design (sparring as a stage)
- [The Meta-Development Loop](the-meta-development-loop.md) — the broader pattern of building tools that improve AI workflows; the session-brief and pipeline are both instances
- [When a Spar Argument Outgrows Its Essay](../case-studies/spar-to-essay-pipeline.md) — how adversarial review generates new work rather than just improving existing work; relevant to the spar-before-committing example above
- [Language Precision Matters — How /spar Sharpened a Framework Artifact](../case-studies/spar-finds-the-assumption.md) *(forthcoming)* — the case study from sparring this document's precursor, with the specific imprecisions caught and the reasoning behind each correction

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

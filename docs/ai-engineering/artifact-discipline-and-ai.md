---
review:
  status: direction-reviewed
  notes: "New essay — Ambler-derived artifact discipline for AI-assisted work. Author review pending."
---

# Artifact Discipline and AI — What Agile Modeling Teaches About Working With Assistants

> **Audience:** Engineers and leads using AI for plans, docs, designs, and platform work — especially when output *looks* complete but nobody reads it or acts on it.
> **Purpose:** Introduce Scott Ambler's artifact discipline (JBGE, TAGRI, travel light, document late) as a practical counterweight to AI's tendency to over-produce — with prompts and workflow hooks peers can use without this entire repository.

---

AI assistants make it cheap to produce artifacts: epics, architecture documents, runbooks, comparison sections, handoffs that restate the git log. The output is often fluent, well-structured, and internally consistent. It is also frequently **more than good enough** — in the wrong direction. Too much, for no one, too early.

This essay borrows from Scott Ambler's [Agile Modeling](https://agilemodeling.com/) and [Agile Data](https://agiledata.org/) work — JBGE, TAGRI, model-with-a-purpose, travel light — and maps it to AI-assisted engineering. The ideas are decades old. The failure mode is new only because generation is nearly free.

---

## The third failure mode (after agreement and inherited framing)

If you've read [Sparring and Shoshin](sparring-and-shoshin.md), you already have two structural responses:

1. **Sparring** — challenge outputs after drafting (does this hold up?)
2. **Shoshin** — challenge starting frames before work (is the problem stated correctly?)

Ambler adds a third angle: **artifact economics** — even when the frame is fine and the claims survive spar, *should this document exist at all, in this form, for this audience, at this time?*

A platform epic that lists every acceptance criterion a enterprise template could hold is not wrong inside its frame. It may still be TAGRI — they ain't gonna read it — and not JBGE — not just barely good enough, *too much* good enough.

---

## JBGE — Just Barely Good Enough

**Definition:** An artifact is sufficient for the task and no more. Once it's good enough, further work is waste unless context demands it.

Ambler's [JBGE essays](https://agilemodeling.com/essays/barelygoodenough.htm) stress that "good enough" is **context-dependent**:

| Invest **more** | Invest **less** |
|---|---|
| High complexity or risk | Skilled audience |
| Pragmatic regulatory need | Easy to change later |
| | Accessible stakeholders, high collaboration |
| | Subject likely to change soon |

**AI pattern:** Uniform "high quality" — every request becomes a comprehensive doc. The model has no marginal cost for another section.

**Practical check before accepting or expanding AI output:**

> Is this artifact **for** someone and **for** a decision — or is it completeness theater?

If you can't name the reader and the action, send it back or cut it before it enters the repo.

---

## TAGRI — They Ain't Gonna Read It

Ambler's [travel light](https://agilemodeling.com/essays/agilearchitecture.htm) advice includes TAGRI: documentation the audience won't read is a process smell.

**AI pattern:** Handoffs that duplicate git history, READMEs that index files nobody opens, epics written for ceremony rather than execution.

**Two questions before keeping an AI-generated doc:**

1. **Who reads this?** (Role, not "the team.")
2. **What do they do differently after reading it?**

If the answer to (2) is "nothing — it's context," prefer a shorter checkpoint, a commit message, or a conversation. Artifacts that only exist to be pasted into the next session are expensive to maintain and easy for the model to get wrong.

---

## Model with a purpose

From [Agile Modeling principles](https://agilemodeling.com/principles.htm): don't create a model or document without knowing audience and purpose.

**AI pattern:** "Write a full design doc" produces a full design doc. The prompt encoded output shape, not outcome.

**Better prompts:**

> Before drafting: who is the audience and what decision does this enable? If unclear, ask me — don't draft.

> Sketch three options in five bullets each. Stop. I'll pick one before you expand.

Pair with shoshin: audience and purpose are often the pivotal assumption.

---

## Travel light and document late

**Travel light:** Every kept artifact must be maintained when requirements change. Prefer fewer, lighter artifacts. Discard framing that no longer serves (comparison sections nobody uses, "Option B legacy" headers).

**Document late:** Light envisioning early; implement; document what **proved true**. Ambler's AMDD lifecycle is not anti-documentation — it's **JIT documentation**.

Rough bracket for AI sessions:

```
Envision (minutes) → Shoshin (frame) → Build (make it work) → Craft (make it right) → Document JBGE (what survived)
```

Spar fits before committing to a direction or publishing external-facing prose. Review fits before git commit for convention compliance.

---

## How this fits with spar and shoshin

```
[context] → shoshin (right problem? right audience?) → envision JBGE → build
                ↓
           draft artifact → TAGRI/JBGE check → spar (claims hold?) → cut or ship
```

- **Shoshin** catches wrong framing and missing audience/purpose.
- **JBGE/TAGRI** catch over-production and docs nobody uses.
- **Spar** catches weak claims inside an otherwise acceptable artifact.

All three can pass and you still ship the wrong thing — human judgment remains the exit. Ambler is explicit about that ceiling; so is shoshin.

---

## Prompts peers can use tomorrow

No tooling required:

**Before a large doc:**

> Name the reader and the decision this enables. If you can't, ask me one sharp question instead of drafting.

**On a draft that feels heavy:**

> TAGRI check: who reads this and what do they do with it? JBGE check: what sections are more than good enough for our context? Propose cuts.

**Before an epic or architecture write-up:**

> Envision only: constraints, two options, open questions — max 15 bullets. Stop for my pick.

**On enterprise template fill:**

> Which sections exist because the template has them, not because we need them? Mark those for deletion.

---

## Encoding in a team framework

If you want this to persist across sessions (not just prompts), the durable shape is the same as other practices:

| Layer | What to encode |
|---|---|
| **Ambient** | Short rules: JBGE default, TAGRI before expanding docs, document late |
| **Invoked** | Skills or commands: `/shoshin` (audience/purpose), `/craft` (JBGE lens on drafts), pre-commit review with TAGRI check |
| **Reference** | One kit doc linking to Ambler's essays for depth |

In this workspace, the portable reference is [`submodules/zanshin-pi-extension/kit/AGILE-ARTIFACT-DISCIPLINE.md`](../../submodules/zanshin-pi-extension/kit/AGILE-ARTIFACT-DISCIPLINE.md). Ambient rules live in [`AGENTS.md`](../../AGENTS.md) (Artifact Discipline section). Peer introduction to spar/shoshin: [Sparring and Shoshin](sparring-and-shoshin.md).

---

## Further reading

| Topic | Source |
|---|---|
| JBGE core practice | [agilemodeling.com — barely good enough](https://agilemodeling.com/essays/barelygoodenough.htm) |
| When is it JBGE? (context factors) | [agilemodeling.com — JBGE when](https://agilemodeling.com/essays/barelygoodenoughwhen.htm) |
| TAGRI and travel light | [agilemodeling.com — agile architecture](https://agilemodeling.com/essays/agilearchitecture.htm) |
| AM principles | [agilemodeling.com — principles](https://agilemodeling.com/principles.htm) |
| Complementary practices (spar/shoshin) | [Sparring and Shoshin](sparring-and-shoshin.md) |
| AI agrees / inherits framing | [The Frictionless Entity](../case-studies/frictionless-entity.md) |

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

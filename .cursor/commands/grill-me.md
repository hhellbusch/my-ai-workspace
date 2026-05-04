---
description: Relentless design interrogation — walk every branch of a plan, resolve dependencies, and reach shared understanding before building
argument-hint: "[file path | plan | design | idea | leave blank for conversation context]"
allowed-tools:
  - Read
  - Shell
  - Glob
  - Grep
  - SemanticSearch
---

<!-- body: ../.commands/grill-me.md -->
# Grill Me — Design Interrogation

<objective>
Interview relentlessly about every aspect of a plan or design until shared understanding is reached and dependencies are resolved. Walk down each branch of the decision tree one by one. For each question, provide a recommended answer — the AI's best current guess — so the conversation surfaces disagreements rather than blank slates.

The goal is not to gather requirements. The goal is to catch what hasn't been decided yet, surface hidden dependencies, and force decisions that would otherwise be deferred to implementation time (where they become bugs).

This is interrogation, not intake. The answer "I don't know" or "whatever you think" is not acceptable — it either gets pushed back ("this decision will shape X — take a position") or gets answered by the AI with a recommendation the user either accepts or corrects.
</objective>

<difference-from-ask-me-questions>
`/ask-me-questions` gathers basic context through structured multiple-choice options before executing a task.

`/grill-me` is used *before* designing or scoping something complex. It:
- Explores the codebase or repo context to answer what it can without asking
- Proposes recommended answers (not just options) for every question
- Continues until every branch is resolved — it doesn't stop after 2-4 questions
- Surfaces dependencies between decisions, not just isolated gaps
- Ends with a consolidated decisions summary, not task execution

Use `/ask-me-questions` when you need context before writing or building.
Use `/grill-me` when you need to fully scope a design or plan before handing it to yourself or an agent.
</difference-from-ask-me-questions>

<process>

### Step 0: Load context

Parse `$ARGUMENTS`:
- **File path** → Read the file to understand the plan or design
- **Topic keyword** → Search the repo for relevant files (plans, backlog, docs)
- **No arguments / conversation context** → Work from the current conversation

Before asking anything, explore what's already known:
- Check `.planning/` for related briefs, roadmaps, or threads
- Check `BACKLOG.md` for related items
- Check relevant `docs/` or `research/` sections
- Check any referenced code or configuration

Answer questions from repo context when possible. Only ask about genuine unknowns.

---

### Step 1: Identify the design surface

State in 2-3 sentences: "Here is what I think we're designing and what decisions remain open." Be explicit about what the interrogation will cover — scope, interface, behavior, dependencies, audience, failure modes.

If the scope is too large to interrogate in one session, say so and propose a narrower starting point.

---

### Step 2: Walk the decision tree

Ask one question at a time. For each question:

```
**Q[N]: [Question]**

_Recommended answer:_ [AI's best current answer — based on what it found in context, what the design implies, or what is simplest. Not a hedge. Take a position.]

_Why this matters:_ [What breaks, branches wrong, or gets decided by default if this isn't answered explicitly]

_Dependencies:_ [Other open questions this answer will constrain]
```

Order questions by dependency — resolve structural questions before detail questions. Don't ask about configuration details before asking what the system is supposed to do.

**Question categories to work through** (not necessarily in this order — follow dependencies):

1. **Purpose and audience** — Who is this for? What problem does it solve? What does success look like for the user of this?
2. **Scope boundary** — What is explicitly out of scope? What happens at the edges?
3. **Interface** — How does someone invoke or interact with this? What inputs does it accept? What does it return or produce?
4. **Behavior at the edges** — What happens with empty input, wrong type, missing field, disabled flag, overloaded state?
5. **Dependencies and ordering** — What does this depend on existing first? What must happen before this runs?
6. **Failure modes** — What happens when this fails? Is failure loud or silent? Does it fail safe?
7. **Ownership and maintenance** — Who updates this when requirements change? Is there a clear update path?
8. **Measurement** — How will you know if this is working? What does a broken version look like from the outside?

After each answer, either:
- Move to the next branch
- Ask a follow-up if the answer introduced a new unresolved dependency
- Mark the question as resolved and log it to the decisions list

---

### Step 3: Surface what wasn't asked

After working through the tree, pause and ask: "Is there anything you wanted to decide that we haven't covered?" Also state explicitly: "Here's what I chose not to ask because I considered it out of scope for this session — let me know if any of these should be in scope."

---

### Step 4: Produce a consolidated decisions summary

Output a structured summary of everything resolved:

```
## Decisions Made

| Decision | Answer | Source |
|---|---|---|
| [decision] | [answer] | User / Recommended (accepted) / Recommended (modified) |

## Open Items

[Anything that surfaced but wasn't resolved — deferred decisions, unknowns that need external input, questions that require a spike]

## What to Build Next

[2-3 sentences on what the interrogation says is ready to implement, and what order to do it in]
```

</process>

<success_criteria>
- Every decision that would have been made implicitly at implementation time is now explicit
- Recommended answers are concrete positions, not hedges or lists of options
- Dependencies between decisions are surfaced and resolved in order
- The decisions summary can be handed to an agent or used as a brief without additional clarification
- User leaves with a clear "what to build next" — not just a list of things that need deciding
</success_criteria>

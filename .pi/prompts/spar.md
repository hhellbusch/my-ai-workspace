---
description: Adversarial review of any content — essays, designs, theses, backlog items, or ideas
argument-hint: "[file path | topic | inline content from conversation]"
allowed-tools:
  - Read
  - Write
  - StrReplace
  - Shell
  - Glob
  - Grep
  - SemanticSearch
  - WebSearch
  - WebFetch
---

# Spar — Adversarial Review

<objective>
Steel-man counterarguments against a target — an essay, a design decision, a thesis, a backlog priority, or an idea shared in conversation. The goal is to surface genuine weaknesses, not to perform contrarianism. Distinguish between structural criticisms (the argument doesn't hold) and presentation criticisms (the argument holds but the writing undermines it).

This is the sparring partner, not the sycophant.
</objective>

<context>
- Repo conventions: @.cursor/rules/repo-structure.md
- Planning context: @.planning/
- Existing threads: !`ls .planning/zen-karate/threads.md 2>/dev/null`
- Related docs: !`ls docs/*.md 2>/dev/null`
</context>

<process>

### Step 0: Check for measurement mode

Parse `$ARGUMENTS` for the `--measure` flag.

**If `--measure` is present:** Run the counterfactual protocol before Steps 1–5:

1. Identify the target (file, topic, or conversation context — same logic as Step 1 below)
2. **Naive pass first:** Ask yourself: "Without any structured methodology, what are the main weaknesses of this target?" Produce 3–5 plain weakness observations. Do not use the argument structure, types, or self-audit from this command. Label this output clearly: `## Naive Pass`.
3. **Then run Steps 1–5 normally.** Label that output: `## Structured Pass`.
4. **Score both on the rubric** from `research/framework-efficacy/counterfactual-protocol.md` and append a comparison summary labeled `## Comparison`.
5. **Log the result:** Add a row to the comparison table in `research/framework-efficacy/counterfactual-protocol.md` and append a full entry to `research/framework-efficacy/intervention-log.md`.

**If `--measure` is not present:** Proceed directly to Step 1.

---

### Step 1: Identify the target

Parse `$ARGUMENTS` to determine what to spar against:

- **File path** → Read the file and all files it links to or references
- **Topic keyword** → Search the repo for relevant content (docs, threads, research, backlog items)
- **No arguments / conversation context** → Spar against whatever thesis or idea the user has been discussing

If ambiguous, ask: "What should I argue against? A specific file, a thesis you've been exploring, or something else?"

### Step 2: Gather full context

Before generating arguments, load everything the target depends on:

- Read the target file in full
- Follow internal links (e.g., if an essay references The Shift, read the relevant sections)
- Check `.planning/` for related threads, briefs, or roadmaps
- Check `research/` for source material the target draws from
- Check `library/` for reference entries

The adversarial review must understand what the target is trying to say before arguing against it.

### Step 3: Generate adversarial arguments

Produce 3-7 arguments. For each:

**Structure:**

```
## N. [Argument title]

**Type:** Structural | Presentation | Scope | Evidence | Consistency

**The argument:** [Steel-manned critique — the strongest version of this objection, not a strawman]

**Why it matters:** [What breaks or weakens if this criticism is valid — in concrete terms]

**Strength:** Strong | Moderate | Weak
[One sentence on whether this is a genuine weakness or contrarian pattern-matching]
```

**Argument types:**
- **Structural** — the core claim doesn't hold (logic, evidence, mechanism)
- **Presentation** — the claim holds but the framing undermines it (tone, irony, overreach)
- **Scope** — the argument is scoped too narrowly or too broadly
- **Evidence** — claims presented as findings that are actually assertions
- **Consistency** — the target contradicts itself or other content in the repo

**Guidelines for generating arguments:**
- Steel-man, not strawman. Present the strongest version of each objection.
- Attack the strongest claims, not the weakest. Easy targets aren't useful.
- Check for the essay's own thesis being violated by the essay itself (the most valuable finding).
- Look for assertions dressed as evidence — confident prose covering unverified claims.
- Consider what audience would find this unconvincing, and why.
- Do NOT pad with weak arguments to hit a count. 3 strong arguments beat 7 weak ones.

### Step 4: Self-audit

After generating arguments, rate your own work:

- Which arguments are genuine weaknesses vs. contrarian posturing?
- Did you attack the strongest claims or take easy shots?
- Are you pattern-matching into a "devil's advocate" role rather than doing real analysis?

State this honestly at the end:

```
## Self-Audit

**Strongest argument above:** [number] — [why this one actually matters]
**Weakest argument above:** [number] — [why this might be contrarian pattern-matching]
**What I might be missing:** [blind spots in the adversarial review itself]
```

### Step 5: Close the loop

End with: "Where am I right, and where am I pattern-matching my way into a contrarian position?"

### Step 6: Optionally capture for later

If the user wants to preserve the sparring for revision:

1. Ask: "Want me to save these as sparring notes for later revision?"
2. If yes, create or update `sparring-notes.md` in the relevant research directory (e.g., `research/zen-karate-philosophy/sparring-notes.md`)
3. Use the same structure as above, with blank response sections for the user to fill in
4. Commit with message prefix `sparring:`

</process>

<success_criteria>
- Every argument is steel-manned (strongest version of the objection)
- Arguments target the strongest claims, not the weakest
- Clear distinction between structural and presentation criticisms
- Self-audit honestly identifies which arguments are strongest and weakest
- The user feels genuinely challenged, not performatively challenged
- No sycophantic softening ("these are minor points" or "overall this is great, but...")
</success_criteria>

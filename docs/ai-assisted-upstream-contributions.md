# AI-Assisted Open Source Contributions — Drafting Upstream Improvements Responsibly

> **Audience:** Engineers who use AI coding assistants and contribute to (or want to contribute to) open source projects.
> **Purpose:** A framework for using AI to lower the barrier to upstream contribution while respecting maintainers, community norms, and quality standards. Includes a real walkthrough of contributing to an ArgoCD tooling project.

---

## The Opportunity

Open source contribution has always had a high activation energy. You find a tool with a gap, but fixing it means understanding someone else's codebase — their architecture, their conventions, their test patterns. For most engineers, the realistic response is: file an issue describing the problem, hope someone picks it up, and move on.

AI changes the economics. The same pattern that lets you [work outside your expertise](ai-for-unfamiliar-domains.md) on personal projects applies to upstream codebases. You can clone a repo, point your AI assistant at it, and within minutes have a reasonable understanding of how the code is organized, where the relevant logic lives, and what a change would involve. The cost of *exploring feasibility* drops dramatically.

This is genuinely valuable for open source. Maintainers are overloaded. An issue that says "I think X should work differently" is useful. An issue that says "I think X should work differently, here's how the code currently handles it, here's a feasibility analysis, and here's a draft approach" is *significantly* more useful. It gives the maintainer a head start and demonstrates that you've done the homework.

But this same capability creates risks. AI makes it trivially easy to generate pull requests at scale without understanding the code. It makes it easy to submit confident-looking changes that don't actually work. It makes it easy to waste maintainer time reviewing AI-generated noise.

The difference between helpful contribution and harmful spam is *how* you use the tooling.

---

## The Responsibility Framework

Three pillars govern responsible AI-assisted contribution: **Disclosure**, **Quality**, and **Engagement**.

### Disclosure — Be transparent about AI involvement

Maintainers and reviewers deserve to know how a contribution was produced. This doesn't mean adding a disclaimer to every line of code, but it does mean being upfront when AI played a significant role.

**When to disclose:**

- Issue descriptions where AI helped with analysis or feasibility exploration
- Pull requests where AI drafted the implementation
- Code review comments where AI helped you understand the codebase

**How to disclose (practical examples):**

In an issue:
> *I used an AI coding assistant (Cursor/Copilot/Claude) to explore the codebase and draft a feasibility analysis for this change. The analysis below reflects what I found, verified against the source.*

In a PR description:
> *Initial implementation drafted with AI assistance. I've reviewed every change, tested locally, and verified it follows the project's conventions.*

In a commit message:
> *Co-authored with AI assistance — verified and tested locally.*

**What to avoid:**

- Hiding AI involvement entirely (dishonest)
- Over-disclaiming to the point of undermining confidence in the work ("this might be completely wrong, AI wrote it")
- Using disclosure as a shield against review ("AI wrote it, so don't blame me if it's wrong")

The goal is straightforward: let reviewers calibrate their scrutiny appropriately.

### Quality — Understand before you submit

This is the non-negotiable rule: **you must be able to explain every line of code you submit.** The AI writes the first draft. You are responsible for the final submission.

**The quality checklist:**

1. **Read the project's CONTRIBUTING.md** — before touching any code. Understand their conventions, PR requirements, test expectations, and code style.
2. **Understand the architecture** — don't just accept the AI's summary. Trace the relevant code paths yourself. Can you explain why the code is structured this way?
3. **Review the AI's output critically** — apply the same [verification discipline](the-shift.md) you'd use for any AI output. Check for hallucinated APIs, incorrect assumptions about project internals, and plausible-but-wrong logic.
4. **Test following the project's patterns** — not your patterns. If they use pytest, write pytest tests. If they have a Makefile target for linting, run it. If they expect integration tests, provide them.
5. **Follow the project's code style** — the AI might generate idiomatic code for the language but not for the project. Match existing patterns.
6. **Check for regressions** — run the full test suite, not just your new tests.

**The litmus test:** If the maintainer asks "why did you do it this way?" and your only answer is "the AI suggested it," you're not ready to submit.

### Engagement — Contribute understanding, not just code

The most impactful AI-assisted contributions often aren't pull requests at all. They're well-researched issues, feasibility analyses, and design discussions.

**The engagement hierarchy:**

1. **File an issue first** — describe the problem, share your analysis of the current behavior, propose an approach. This gives the maintainer a chance to guide you *before* you write code.
2. **Read existing issues and discussions** — your idea might already be tracked. Search before filing.
3. **Respond to maintainer feedback** — if they suggest a different approach, follow it. They know their codebase better than your AI does.
4. **Don't submit surprise PRs for significant changes** — a 500-line PR from a stranger with no prior discussion is a maintenance burden, not a gift.
5. **Be patient** — open source maintainers have lives. A well-filed issue with a feasibility analysis will get attention when there's bandwidth.

---

## Walkthrough: argocd-diff-preview

This is a real example of the framework in practice. It resulted in a new feature being added to the upstream project — not through a PR, but through a well-researched issue and a collaborative exchange with the maintainer.

### The problem

[argocd-diff-preview](https://github.com/dag-andersen/argocd-diff-preview) is a tool that renders manifest changes on pull requests — it shows you what ArgoCD will actually deploy before you merge. It's useful for catching misconfigurations in GitOps workflows.

The tool works well for simple setups, but the workspace uses an app-of-apps-of-apps pattern: a global root application creates several intermediate applications, which in turn create the final component manifests. The tool only looked at static ArgoCD Application resources, so it couldn't traverse this multi-level hierarchy to produce a complete diff.

### Step 1: Clone and explore

The upstream repo was cloned into the workspace's `git-projects/` directory — a convention for keeping external repos alongside workspace content so the AI assistant has full context.

```bash
cd git-projects/
git clone https://github.com/dag-andersen/argocd-diff-preview.git
```

With the full codebase available, the AI could read the source, understand how the tool discovers and renders Application resources, and identify where the traversal logic would need to change. This produced a clear picture of the change surface within minutes — something that would have taken hours of manual reading.

### Step 2: Assess feasibility

Rather than jumping straight to implementation, the first step was understanding whether the change was *feasible* and what design implications it would have. The AI helped trace the code paths, identify the key abstractions, and think through edge cases (circular references, depth limits, performance with large hierarchies).

This feasibility analysis shaped the issue — instead of a vague feature request, it was possible to describe the specific mechanism that would need to change and a proposed approach.

### Step 3: File the issue

[Issue #381](https://github.com/dag-andersen/argocd-diff-preview/issues/381) was filed describing the use case, the current limitation, and the proposed solution. The key elements:

- **Clear problem statement** — "I have an app of apps of apps pattern and I need a complete diff for the resulting changes"
- **Analysis of current behavior** — identified that the tool only looks at static ArgoCD resources
- **Proposed approach** — "the tool would need to analyze the output manifests from each stage and realize that there are additional applications to traverse"

### Step 4: Share the draft

An AI-assisted draft implementation was created on a branch and shared as a link in the issue comments — not as a formal PR, but as evidence of feasibility and a starting point for discussion. The comment was explicit: "used Cursor to make a pass at implementing the idea. I still need to do additional testing before submitting a PR, but wanted to share."

This is the issue-first pattern in action: contributing understanding and evidence, not demanding that code be merged.

### Step 5: The outcome

The maintainer responded within a week. Having seen the feasibility analysis and draft approach, he implemented the feature himself — properly, with his deep knowledge of the codebase and its edge cases. A new `--traverse-app-of-apps` flag shipped in [v0.2.2](https://github.com/dag-andersen/argocd-diff-preview/releases/tag/v0.2.2), documented and tested.

The contribution was adopted for the original use case with OpenShift and the tool's isolated namespace functionality. The plan is to review the docs and provide further feedback.

### What made this work

- **Issue before PR** — the maintainer had context and agency before any code was proposed
- **Feasibility analysis, not just a request** — the issue demonstrated understanding of the codebase, not just a wish list
- **Draft shared transparently** — "AI helped, here's what I found, still needs testing" — not "please merge my PR"
- **The maintainer built the real implementation** — with his knowledge of the codebase, he produced a better solution than an outside contributor could have. The contribution was the *analysis and direction*, not the code.

This is arguably the highest-value pattern for AI-assisted upstream work: use AI to lower the cost of understanding, then contribute that understanding to the maintainer who can act on it most effectively.

---

## Second Example: Helm Chart Improvements

Not every contribution follows the same arc. Sometimes the work is more traditional — actual code changes that need to be submitted upstream.

In this case, a Helm chart in use within the workspace had room for improvement in its templates. The AI assisted with:

- **Understanding existing chart patterns** — reading the templates, values schema, and helper functions to understand conventions
- **Drafting improvements** — generating template changes that followed the existing style
- **Testing** — validating the rendered output against expected manifests

This contribution is still in progress — the changes need further review and testing before submitting upstream. That's fine. Not every contribution ships immediately, and rushing a submission to check a box is worse than waiting until the work is solid.

The AI accelerated the drafting phase, but the review, testing, and submission still require human judgment and patience.

---

## The Workflow

A repeatable process for AI-assisted upstream contributions:

### 1. Identify the opportunity

You encounter a limitation or bug in a tool you use. Before moving on, ask: "Is this fixable upstream? Would a fix benefit others?"

### 2. Clone and explore

```bash
cd git-projects/
git clone https://github.com/org/repo.git
cd repo/
```

Let the AI read the codebase. Ask it to summarize the architecture, identify the relevant code paths, and map the change surface. Verify its understanding against the actual code — AI summaries are useful starting points but not authoritative.

### 3. Assess feasibility

Before writing any code, understand:
- Is the change technically feasible?
- What are the design implications?
- Are there edge cases that complicate the approach?
- Does this conflict with the project's direction or existing work?

### 4. Engage the community

- Search existing issues for related discussions
- File an issue describing the problem, your analysis, and a proposed approach
- If the project has a discussion forum or Slack, check there too

### 5. Draft with AI, review yourself

If you proceed to implementation:
- Create a branch: `git checkout -b improvement-description`
- Let the AI draft the changes
- **Review every line** — can you explain what it does and why?
- Follow the project's code style and conventions
- Write tests following the project's test patterns
- Run the full test suite

### 6. Disclose and submit

- Include AI disclosure in the PR description
- Reference the issue you filed
- Be responsive to review feedback
- Be prepared for the maintainer to take a different approach — that's their prerogative and often produces a better result

---

## Anti-Patterns

### Spray-and-pray PRs

AI makes it easy to generate PRs across dozens of repos in a day. This is harmful. Each PR creates review burden for a maintainer. If you wouldn't have manually written and tested the change, don't submit it because an AI made it easy to generate.

### Submitting what you don't understand

If you can't explain why the code works, you can't respond to review feedback, you can't debug failures, and you can't assess whether the maintainer's concerns are valid. The AI is a drafting tool, not an author. You're the author.

### Ignoring project conventions

The AI doesn't know that this project uses tabs not spaces, or that they name test files `*_spec.rb` not `test_*.rb`, or that they require a signed-off-by line in every commit. Read the contributing guide. Match the existing patterns.

### Treating AI output as authoritative

The AI may generate code that uses deprecated APIs, violates the project's security model, or introduces subtle bugs that pass the test suite. Apply the same [verification discipline](the-shift.md) you would to any code you didn't write yourself.

### Large, unsolicited refactors

"I noticed your codebase could be cleaner so I refactored 40 files" is not a contribution — it's a burden. Even if every change is correct, reviewing a massive refactor from a stranger is exhausting. Keep contributions focused and discuss scope before submitting.

---

## Connections

This essay connects to several themes in the documentation suite:

- **[The Shift](the-shift.md)** — Verification discipline and critical thinking are the core skills that make AI-assisted contributions responsible rather than reckless. The sycophancy risk is especially relevant: the AI will tell you your change is great regardless of whether it actually is.
- **[AI-Assisted Development Workflows](ai-assisted-development-workflows.md)** — The `git-projects/` directory pattern and the meta-development system that supports this workflow.
- **[Using AI Outside Your Expertise](ai-for-unfamiliar-domains.md)** — Contributing to an upstream project is often working outside your expertise — the maintainer's codebase is unfamiliar territory. The same iterative exploration pattern applies.

---

*This essay was written with AI assistance. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for full context on AI-generated content in this workspace.*

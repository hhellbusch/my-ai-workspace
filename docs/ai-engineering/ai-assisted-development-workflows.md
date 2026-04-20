---
review:
  status: direction-reviewed
  read: 2026-04-18
  fact-checked: 2026-04-18
  at: 1f2f9d8
  notes: "Author pass after spar: scope/Purpose, epistemic fixes (§6–§7), product-doc caveat, iteration note, triage table disclaimer, Argo CD naming. 2026-04-18: Replaced orphan pointer with 'Six patterns at a glance' table — restore reviewed after author pass."
---

# AI-Assisted Development Workflows — A Practical Guide

> **Audience:** Anyone from leadership to hands-on engineers.
> **Purpose:** Transferable patterns for using AI coding assistants effectively — from daily editor workflows to multi-session discipline and meta-development habits. Tool-specific paths (Copilot, Cursor, Claude Code) appear where they help you get started; **from _Beyond context sharing: multi-session project management_ onward**, concrete examples include this repository’s commands and files as a **reference implementation** of those habits — patterns you can re-create with your own conventions, not a universal stack requirement.

---

## What Is This About?

Modern AI coding assistants are no longer just autocomplete tools.
When used deliberately, they change *how* you approach engineering work — from how you plan features to how you debug failures, review diffs, and carry context across sessions.

This guide documents patterns that have proven useful in real work. The examples are drawn from infrastructure and platform engineering — Ansible, Argo CD, Helm, Kubernetes, OpenShift — but the underlying patterns (context sharing, verification discipline, meta-development systems) apply to any engineering domain. Where the text points at specific filenames or slash commands, read it as “one way this can look in git,” not as mandatory tooling.

---

## The Core Mental Shift

Traditional development loop:
```
Write code → Test → Debug → Repeat
```

AI-assisted development loop:
```
Describe intent → Review AI output → Guide + Correct → Commit → Describe next intent
```

You are the architect and the reviewer. Think of the AI as a **very fast collaborator**: strong on idioms, cross-file synthesis, and draft structure — but **blind to your runtime reality** unless you put it in context, and prone to **confidently rationalizing** whichever direction your prompt implies (including a bad one). For **how hard to verify** each change, the “junior engineer” shorthand still helps: assume you are merging work from someone who does not yet know your invariants.

**The most important skill is learning to give AI the right context.**

This is more than a workflow change — it's a shift in which engineering skills carry the most weight. Problem decomposition, verification discipline, clear communication, and systematic reasoning become your primary value, not implementation speed. For a deeper look at this shift and the risks that come with it (including the sycophancy problem and over-reliance), see [The Shift — Engineering Skills in the Age of AI](the-shift.md).

### Six patterns, at a glance

These patterns recur throughout the sections below and the wider essay track. Named here so they can be referenced without re-explaining from scratch.

| Pattern | In brief | Covered in |
|---|---|---|
| **Stacked assistants** | One tool for editing, a second for review — separation of concerns catches different failure classes | §1 Daily Workflow, §3 PR review |
| **Unfamiliar ground** | Task an assistant with a platform you cannot run locally — valid *if* something real validates the result | [Using AI Outside Your Expertise](ai-for-unfamiliar-domains.md) |
| **Async cadence** | Assign a bounded task, step away, return to inspect diffs — wall-clock time is low; safety requires a clear success criterion and scope *before* stepping away | §1 Daily Workflow, §5 Meta-Development |
| **Issue-first delegation** | A tracker link, log excerpt, or crisp failure description plus repo context is enough for a useful first pass — human still reproduces, tests, and merges | §1 Prompting principles, §3–§4 |
| **Review-loop closure** | Feed review comments (human, automation, or a second model) back into the same assistant loop — treat review as pipeline input, not a separate rewrite session | §3 PR review, §2 multi-session |
| **Compounding through habit** | Gains come from *defaulting* to the assistant for unfamiliar work, review churn, and mechanical fixups — not from any single clever prompt; verification habits are the floor | §5 Meta-Development, §6 What to expect |

---

## 1. Daily Workflow: AI in the Editor

Tools covered: GitHub Copilot (VS Code), Claude Code, Cursor. The patterns apply to all of them.

### What it looks like in practice

Instead of writing a Helm template or Ansible task from scratch, you describe what you need:

> _"Add a sync-wave annotation to this Kubernetes Job template so it runs after the ExternalSecret but before the main app workloads."_

The AI generates a candidate. You review it, tweak it, and move on.

### Prompting principles for infrastructure work

| Principle | Why it matters |
|---|---|
| Give the AI access to the relevant code | AI has no ambient context — use workspace indexing, `@file` references, or a CLI pointed at your repo so the agent can traverse and analyze the actual source, not just a pasted snippet |
| State constraints explicitly | "This must be idempotent", "Do not add error handling I haven't asked for" |
| Ask for one thing at a time | Large multi-part requests produce mediocre results |
| Name the pattern, not just the task | "Convert this Helm pre-install hook to an Argo CD sync-wave" beats a vague description |
| Verify before committing | AI can produce plausible-but-wrong Jinja2, wrong indent levels, stale API syntax, and [entirely fabricated APIs or capabilities](../case-studies/fabricated-references.md) that never existed |

Infra work is often irreducibly multi-constraint (for example, a GitHub Actions job with `yq`, failure aggregation, and chart-specific flags). The “one thing at a time” rule still applies **across iterations**: scaffold the workflow, then tighten failure behavior, then broaden coverage — instead of demanding the whole matrix in a single prompt.

### What works especially well

- **YAML scaffolding** — Helm templates, values files, Ansible tasks, Argo CD Applications
- **Explaining code you didn't write** — paste it and ask
- **First-draft documentation** — README files, runbook steps, PR descriptions (but [watch for content that speaks in your voice](../case-studies/who-is-speaking.md) — biographical claims need explicit review)
- **Mechanical refactors** — converting serial loops to parallel, adding idempotency guards
- **CI/CD boilerplate** — GitHub Actions jobs, shell scripts with proper exit handling

---

## 2. Context Sharing Across Sessions

One of the core practical challenges with AI assistants: **each conversation starts with zero memory.**

### The problem

You spend time building shared understanding with the AI about your codebase — what your directory structure means, what conventions you follow, what the key variable names are. Then you close the tab. Gone.

### Solution A: Repository instruction files

Each AI tool has a way to inject standing context into every conversation automatically:

| Tool | File | Behavior |
|---|---|---|
| **GitHub Copilot (VS Code)** | `.github/copilot-instructions.md` | Loaded for every chat session in that workspace |
| **Cursor** | `.cursorrules` | Loaded automatically from workspace root |
| **Claude Code** | `AGENTS.md` | Loaded at session start |

Names, default paths, and what loads automatically **change by product and version** — confirm behavior in your vendor’s documentation before relying on a path.

**What to put in these files:**
- Architecture overview (what each directory does, what the layers are)
- Hard invariants ("secrets never in Git", "always test in non-prod first")
- Key variable names and what they mean
- How to locally test or render (e.g., exact CLI commands)
- Common pitfalls that have bitten the team before

Once in place, you get correct context-aware help from the first message of every session — no re-explaining needed.

### Solution B: Living plan documents

For in-progress multi-session work (a large feature branch, a migration), maintain a structured Markdown file in the repo that tracks state:

```markdown
## Goal
## Status (done / pending)
## Key Variables Reference
## Open Questions / Risks
```

At the start of a new session: point the AI at this file. It picks up where you left off.

### Solution C: A personal knowledge base repo

Keep a separate repo (like this one) as a curated collection of solved patterns, examples, and reference implementations. The AI can search and reference it. You accumulate institutional knowledge that transfers between projects.

### Beyond context sharing: multi-session project management

*This section grew from direct experience managing a multi-session project in this repository. The patterns below were each built in response to a specific failure — the linked case studies trace what happened and what was built.*

Solutions A through C solve the *context loading* problem — getting a new session up to speed on what exists. But multi-session projects create a harder problem: **accumulated context shapes the AI's judgment, not just its knowledge.**

When a project runs across many sessions, the AI isn't just reading context — it's inheriting framing. A backlog written in session 1 tells session 5 what matters. A handoff from session 3 tells session 4 where to start. A roadmap from the project's first week tells month-two sessions what the plan is. Each of these artifacts carries implicit authority that may not be deserved.

This is [The Shift](the-shift.md)'s sycophancy problem (section 6) expressed as a project management concern. The AI doesn't just agree with your code — it agrees with your priorities, your scope, your framing, because all of those are in the context window and all of them look authoritative. When multiple sessions modify the same files, the problem compounds — an agent may [operate on stale assumptions](../case-studies/stale-context-in-long-sessions.md) from its own session while the repository has moved on.

**Patterns that help:**

**Persistent tracking with periodic fresh evaluation.** A [`BACKLOG.md`](../../BACKLOG.md) managed through a structured command ([`/backlog`](../../.cursor/commands/backlog.md)) keeps work visible across sessions. But periodic re-prioritization should use [zero-base evaluation](../case-studies/debugging-ai-judgment.md) — strip existing section labels and score items on merits before comparing against the current ordering. Without this, each re-prioritization reinforces the last one.

**Session orientation that checks for drift.** A [`/start`](../../.cursor/commands/start.md) command that reads the backlog, checks recent git activity, and suggests focus options gives a new session structure. Adding a [fresh-eyes check](../../.cursor/rules/shoshin.md) — comparing project brief goals against current backlog items — catches scope drift that accumulates across sessions without anyone noticing.

**Handoffs that name their assumptions.** A session handoff document (e.g., from a [`/whats-next`](../../.cursor/commands/whats-next.md) command) is useful for continuity but dangerous for anchoring. The mitigation is to include an assumptions section: what framing decisions did this session make? What was taken as given that a fresh session should question? This gives the next session permission to disagree with the handoff rather than inheriting it uncritically.

**Scope changes updated as a set.** When a project's scope shifts — the user's understanding evolves, priorities change, a new direction emerges — update all related documents in the same session: brief, roadmap, style guide, personal notes, threads. AI sessions read documents independently. If the brief says "broad scope" but the style guide still says "narrow terminology," the AI gets conflicting signals. Updating as a set eliminates the inconsistency. (See [How AI Handles Evolving Creative Scope](../case-studies/evolving-creative-scope.md) for the full pattern.)

**Planning evolution logs.** Git history captures *what* changed in a file. It doesn't capture *why* the scope shifted, which documents were updated as a set, or what the user's reasoning was. A [CHANGELOG.md](../../.planning/zen-karate/CHANGELOG.md) in the planning directory — entries like "broadened from X to Y because the user's learning expanded" — gives future sessions the evolution story, not just the current state.

These patterns aren't theoretical. They were built iteratively through the [meta-development loop](the-meta-development-loop.md) — each one created in response to a specific friction point encountered during real multi-session work.

---

## 3. GitOps Development Patterns

### PR validation with AI-authored CI

Instead of discovering a chart renders incorrectly after merging, write a GitHub Actions workflow that lints every chart on every PR. A useful prompt pattern:

> _"Write a GitHub Actions job that reads chart paths from an index YAML file using `yq`, then runs `helm lint` on each one. Fail the overall step if any chart fails, but lint all charts before exiting so all errors are visible at once."_

Iterate from there — add `--set-string` flags to satisfy `required()` guards, handle charts with no defaults, add summary output. Each iteration is a small, targeted ask.

### Branches and PRs via prompting

Instead of manually running git commands, describe the intent:

> _"Create a branch called `feature/documentation` off main, stage only the files in `docs/` and the updated `README.md`, and write a PR description summarizing what was added."_

The AI runs the git commands. This reduces the chance of accidentally staging unrelated files or mis-describing the change.

### Sync-wave dependency design

When ordering Argo CD sync-waves for a new component, describe the dependency chain and ask the AI to assign wave numbers:

> _"I need: Namespace first, then a Secret from an external secrets manager, then RBAC ServiceAccount/Role/RoleBinding, then a Job that consumes the secret, then main app workloads. Assign sync-wave numbers and explain the ordering."_

The AI produces a table you can review before implementing. The back-and-forth to refine it is faster than working through the dependency graph by hand.

### PR review via GitHub MCP

AI coding assistants with GitHub MCP access (such as GitHub Copilot with the GitHub MCP server, or Cursor/Claude Code with `gh` CLI access) can pull a PR's diff, understand the change in context, and provide meaningful review feedback. This goes well beyond syntax checking:

> _"Review PR #42. Focus on whether the Helm values changes are backward-compatible with clusters still running the previous chart version."_

The AI reads the full diff, cross-references the values schema, and flags breaking changes — the kind of review that requires understanding both the before and after state. Other useful review prompts:

> _"Are there any resources in this PR that are missing sync-wave annotations?"_

> _"Does this PR introduce any new required values that don't have defaults? If so, which existing values files would break?"_

This is especially valuable for large PRs where the diff is too big to review manually in one pass. The AI can triage which files have substantive changes vs. mechanical ones, summarize what each file change does, and flag the parts that need human attention.

The same principle applies to understanding *other people's* PRs — when you're reviewing work from a teammate and need to quickly understand the intent and impact of a change across multiple files.

### Stale branch triage

Most repositories accumulate branches over time — experiments, abandoned features, branches that got merged via a different path, hotfixes that were cherry-picked elsewhere. Nobody cleans them up because evaluating each one takes effort: what was this branch for? Was it merged? Is there anything worth keeping?

An AI with GitHub MCP access can systematically audit branches:

> _"List all branches in this repo with their last commit date and author. For any branch with no commits in the last 90 days, compare its diff against main and categorize it: already fully merged, has unmerged changes worth reviewing, or safe to delete."_

The AI can produce a triage report:

| Branch | Last commit | Author | Status | Recommendation |
|---|---|---|---|---|
| `feature/old-migration` | 2024-11-03 | jsmith | All changes present in main | Safe to delete |
| `experiment/new-sync-policy` | 2025-01-15 | jdoe | 3 files with unique changes | Review before deleting |
| `hotfix/csr-renewal` | 2025-03-20 | jsmith | Cherry-picked to main, branch has extra debug logging | Safe to delete |

*Illustrative shape of a triage report — verify branch state locally (merge bases, cherry-picks, release branches) before deleting anything.*

This turns a tedious manual audit into a 5-minute conversation. For repositories with dozens of stale branches, the time savings are significant — and more importantly, it actually gets done instead of being perpetually deferred.

The pattern generalizes: any repository housekeeping task that requires *understanding context to make a judgment call* (not just mechanical cleanup) is a strong fit for AI-assisted workflows.

---

## 4. Ansible Automation Patterns

### Parallelizing serial plays

When an Ansible play runs sequentially against infrastructure targets (e.g., bare-metal BMC operations), AI can help identify which tasks are safe to parallelize and how to restructure them using in-memory dynamic inventory groups.

Describe the current serial approach, the goal, and the constraint:

> _"This play loops over a list of BMC hosts and boots each one serially. I want to convert this to run in parallel using Ansible's `free` strategy and dynamic `add_host` groups. The tasks must be idempotent and a setup block should only run once regardless of how many hosts are in the group."_

The AI identifies the `run_once: true` requirement, the correct `groups:` and `hostvars:` structure for `add_host`, and flags tasks that can't be safely parallelized.

### AI-assisted log analysis

When an automation job fails, fetch the raw log output and ask the AI to analyze it:

> _"Here is the stdout from a failed Ansible run. Identify the first task that failed, the error message, and based on earlier tasks in the output, what variable value or condition likely caused it."_

This turns 10 minutes of log scanning into a 30-second triage. The AI can cross-reference task names, variable assignments earlier in the run, and `assert` conditions to explain the failure chain.

---

## 5. The Meta-Development System (Skills, Commands, Agents)

This is the most advanced pattern — essentially *codifying* how the AI should behave for specific recurring workflows.

### What are Skills, Commands, and Agents?

| Concept | What it is | Analogy |
|---|---|---|
| **Skill** | A detailed instruction file that gives the AI a specialized workflow | An SOP the AI follows |
| **Command** | A short trigger (slash command) that invokes a Skill | A macro keybind |
| **Agent** | An AI persona with focused expertise (e.g., "security auditor") | A specialist on the team |

### Why this matters

Without Skills, every session repeats the same setup:
> _"Remember, the cluster key must match the directory name. The sync-wave convention is..."_

With a Skill, the AI loads domain-specific workflow instructions automatically when you invoke it. Consistent behavior, no re-explanation.

### Skills in this workspace

| Skill | Purpose |
|---|---|
| `debug-like-expert` | Structured debugging: gather evidence, form hypotheses, test one at a time |
| `create-plans` | Break a feature into a hierarchical plan (brief → roadmap → phase steps) |
| `create-agent-skills` | Meta: helps you write new Skills for new domains |

### Building a Skill for log analysis

A Skill file is just a Markdown document with instructions. For automation log analysis:

1. **Fetch step** — Retrieve the raw log from the pipeline system using its API
2. **Parse step** — Scan for failure indicators, extract task name and error message
3. **Contextualize step** — Look at the task's inputs earlier in the run to find root cause
4. **Report step** — Produce a concise summary: what failed, why, suggested fix

Once written, a single `/analyze-pipeline-log <job-id>` invocation runs the full workflow. For a real worked example of building a Skill from scratch — including the design decisions, failure handling, and iteration — see [Building a Research and Verification Skill](../case-studies/building-a-research-skill.md).

---

## 6. What to Expect (and What to Watch For)

### What AI does well

- **First drafts, fast** — often strong for structure, boilerplate, and docs; for correctness-critical config and anything security-adjacent, assume **distance-to-done is unknown** until you have verified it in *your* environment. Calibrate review depth to risk, not to a comfortable percentage.
- Recognizing and applying established patterns (Helm, Ansible, Argo CD idioms)
- Explaining code written by someone else
- Generating structured documentation
- Mechanical refactors with clear rules

### Where human skills matter most

These aren't just guardrails — they're the skills that matter *more* in an AI-assisted workflow:

- **Correctness for your environment** — AI doesn't know your network topology, secret paths, or naming conventions. You bring the context that makes generic solutions work in your specific world.
- **Security decisions** — AI will validate insecure patterns if you present them as intentional. Security review requires independent judgment, not AI agreement.
- **Architecture tradeoffs** — AI will suggest solutions and justify whichever direction you lean. You decide if the tradeoffs actually fit your constraints, maintenance burden, and team capabilities.
- **Testing and verification** — AI can write tests but cannot judge whether they test the *right things*. Designing tests for edge cases and failure modes is a human skill. See [The Shift](the-shift.md) for more on QA thinking.

### Practical safeguards

- Review every diff before committing — treat AI output like a PR from a new team member. But keep the review [proportionate to the change](../case-studies/heavy-safety-nets.md) — a 10-step review for a one-line fix will get skipped entirely.
- Don't put real credentials, internal hostnames, or sensitive config in prompts
- When an AI answer seems confident but wrong, it probably is — [verify against official docs](../case-studies/fabricated-references.md), not just the AI's confidence
- Use non-production environments for any playbook or automation the AI helped write

---

## Getting Started

1. **Open a repo you know well in VS Code**
2. **Ask about code you're looking at:** _"Explain what this template does and what inputs it requires"_
3. **Ask for a specific small change:** _"Add a `required()` guard on this value with a clear error message"_
4. **Review the diff, decide if it's right, iterate**
5. **Once you've seen it work a few times, try it on something larger**

Start with low-stakes work (docs, linting, scaffolding) before using it on production infrastructure changes.

---

## 7. Where AI Assists but Doesn't Replace Engineering Judgment

The patterns in this guide cover tasks where AI can meaningfully accelerate your work. But some of the most consequential engineering work involves decisions where AI can inform but cannot substitute for human judgment — particularly in complex architecture selection.

A concrete example: [Enterprise Generative AI: Architecting and Self-Hosting Large Language Models on Red Hat OpenShift](https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/) walks through the full decision space for deploying LLMs on enterprise infrastructure. The decisions involved are exactly the kind AI will *help you implement* but cannot *make for you*. The bullets below are **dimensions to model**, not answers — especially economics, where list prices, utilization, and contract tier move conclusions quickly.

- **RHEL AI vs. OpenShift AI** — single-node prototyping vs. distributed Kubernetes-native orchestration, depending on your scale requirements and operational maturity
- **vLLM vs. TGIS runtimes** — PagedAttention throughput vs. tensor parallelism, OpenAI API compatibility vs. gRPC interfaces
- **S3 storage vs. ModelCar** — maintaining separate object storage infrastructure vs. packaging model weights as OCI images that fit your existing DevSecOps pipeline
- **On-premise vs. hyperscaler (ROSA/ARO)** — CapEx hardware ownership vs. OpEx elasticity, air-gapped compliance requirements vs. managed SRE
- **API vs. self-host economics** — articles and talks often repeat a headline **token breakeven** (for example an “~11B tokens/month” rule of thumb). Treat any scalar as **one spreadsheet snapshot**, easy to **cargo-cult** into slide decks. The [Braincuber analysis](https://www.braincuber.com/blog/self-hosted-llms-vs-api-based-llms-cost-performance-analysis) behind some of those numbers **still argues API consumption wins for most cases** (~87% in their framing); a separately cited “18x” style comparison may pit on-prem hardware against a **budget** API tier, not the tier you actually buy. Build **your own** cost model against your contracts and utilization; see [Finding 2 — economics and vendor marketing](../../research/openshift-ai-llm-deployment/assessment.md#finding-2-economics-built-on-vendor-marketing) for a worked deconstruction.

Each of these is a high-stakes tradeoff with real financial and operational consequences. AI will confidently recommend whichever option you lean toward in your prompt — which is precisely why the sycophancy awareness described in [The Shift](the-shift.md) matters most for architecture decisions.

The Day 2 concerns in that article — rate limiting, auth governance, observability, lifecycle management — are also examples of quality assurance thinking applied at the platform level. "How do I know this inference endpoint is correctly serving traffic, not being abused, and will still be supported in 12 months?" is the same verification discipline whether you're checking GIF transparency or monitoring token throughput.

---

## Related Resources in This Workspace

| Resource | Where |
|---|---|
| The Shift — engineering skills in the age of AI | `docs/ai-engineering/the-shift.md` |
| Using AI outside your expertise — case study | `docs/ai-engineering/ai-for-unfamiliar-domains.md` |
| AI-assisted upstream contributions — responsible open source workflow | `docs/ai-engineering/ai-assisted-upstream-contributions.md` |
| Enterprise LLM deployment on OpenShift AI | [jaredburck.me](https://jaredburck.me/blog/openshift-ai-llm-enterprise-deployment/) |
| Ansible playbook examples | `devops/ansible/examples/` |
| Argo CD / GitOps patterns | `devops/argo/examples/` |
| OpenShift troubleshooting guides | `devops/ocp/troubleshooting/` |
| AAP 2.5 token 404 root cause write-up | `devops/ansible/troubleshooting/aap-controller-token-404/` |
| External project clones for upstream contribution | `git-projects/` |
| Cursor commands | `.cursor/commands/` |
| Cursor skills | `.cursor/skills/` |
| The Meta-Development Loop — building tools that build your workflow | [docs/ai-engineering/the-meta-development-loop.md](the-meta-development-loop.md) |
| From Conversation to Essay in One Session — case study | [docs/case-studies/conversation-to-essay.md](../case-studies/conversation-to-essay.md) |
| Adversarial Review as a Meta-Development Pattern — case study | [docs/case-studies/adversarial-review-meta-development.md](../case-studies/adversarial-review-meta-development.md) |
| Debugging Your AI Assistant's Judgment — case study | [docs/case-studies/debugging-ai-judgment.md](../case-studies/debugging-ai-judgment.md) |
| How AI Handles Evolving Creative Scope — case study | [docs/case-studies/evolving-creative-scope.md](../case-studies/evolving-creative-scope.md) |
| Building Knowledge Management with AI — case study | [docs/case-studies/building-knowledge-management-with-ai.md](../case-studies/building-knowledge-management-with-ai.md) |
| When AI Fabricates the Evidence — case study | [docs/case-studies/fabricated-references.md](../case-studies/fabricated-references.md) |
| Who Is Speaking? When AI Writes in Your Voice — case study | [docs/case-studies/who-is-speaking.md](../case-studies/who-is-speaking.md) |
| When AI Ignores Changes Made by Other Sessions — case study | [docs/case-studies/stale-context-in-long-sessions.md](../case-studies/stale-context-in-long-sessions.md) |
| When the Safety Net Is Too Heavy to Use — case study | [docs/case-studies/heavy-safety-nets.md](../case-studies/heavy-safety-nets.md) |
| When the Source Says the Opposite of the Claim — case study | [docs/case-studies/context-stripped-citations.md](../case-studies/context-stripped-citations.md) |

---

*This guide was created with AI assistance (GitHub Copilot) and has been reviewed by the author. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

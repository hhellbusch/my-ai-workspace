# AI-Assisted Development Workflows — A Practical Guide

> **Audience:** Anyone from leadership to hands-on engineers.
> **Purpose:** Practical, tool-agnostic patterns for using AI coding assistants effectively in infrastructure and platform engineering work.

---

## What Is This About?

Modern AI coding assistants are no longer just autocomplete tools.
When used deliberately, they change *how* you approach engineering work — from how you plan features to how you debug failures, review diffs, and carry context across sessions.

This guide documents patterns that have proven useful in real infrastructure work across:
- Ansible automation and playbook development
- GitOps fleet management (ArgoCD + Helm + GitHub Actions)
- Kubernetes / OpenShift configuration
- CI/CD pipeline authoring

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

You are the architect and the reviewer. The AI is a fast, knowledgeable collaborator that never gets tired — but also never knows your specific codebase unless you show it.

**The most important skill is learning to give AI the right context.**

This is more than a workflow change — it's a shift in which engineering skills carry the most weight. Problem decomposition, verification discipline, clear communication, and systematic reasoning become your primary value, not implementation speed. For a deeper look at this shift and the risks that come with it (including the sycophancy problem and over-reliance), see [The Shift — Engineering Skills in the Age of AI](the-shift.md).

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
| Provide the file before asking about it | AI has no ambient context — reference `#file` or paste the relevant section |
| State constraints explicitly | "This must be idempotent", "Do not add error handling I haven't asked for" |
| Ask for one thing at a time | Large multi-part requests produce mediocre results |
| Name the pattern, not just the task | "Convert this Helm pre-install hook to an ArgoCD sync-wave" beats a vague description |
| Verify before committing | AI can produce plausible-but-wrong Jinja2, wrong indent levels, stale API syntax |

### What works especially well

- **YAML scaffolding** — Helm templates, values files, Ansible tasks, ArgoCD Applications
- **Explaining code you didn't write** — paste it and ask
- **First-draft documentation** — README files, runbook steps, PR descriptions
- **Mechanical refactors** — converting serial loops to parallel, adding idempotency guards
- **CI/CD boilerplate** — GitHub Actions jobs, shell scripts with proper exit handling

---

## 2. Context Sharing Across Sessions

This is the #1 practical challenge with AI assistants: **each conversation starts with zero memory.**

### The problem

You spend time building shared understanding with the AI about your codebase — what your directory structure means, what conventions you follow, what the key variable names are. Then you close the tab. Gone.

### Solution A: Repository instruction files

Each AI tool has a way to inject standing context into every conversation automatically:

| Tool | File | Behavior |
|---|---|---|
| **GitHub Copilot (VS Code)** | `.github/copilot-instructions.md` | Loaded for every chat session in that workspace |
| **Cursor** | `.cursorrules` | Loaded automatically from workspace root |
| **Claude Code** | `AGENTS.md` | Loaded at session start |

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

When ordering ArgoCD sync-waves for a new component, describe the dependency chain and ask the AI to assign wave numbers:

> _"I need: Namespace first, then a Secret from an external secrets manager, then RBAC ServiceAccount/Role/RoleBinding, then a Job that consumes the secret, then main app workloads. Assign sync-wave numbers and explain the ordering."_

The AI produces a table you can review before implementing. The back-and-forth to refine it is faster than working through the dependency graph by hand.

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

Once written, a single `/analyze-pipeline-log <job-id>` invocation runs the full workflow.

---

## 6. What to Expect (and What to Watch For)

### What AI does well

- First drafts, fast (typically 80%+ of the way there)
- Recognizing and applying established patterns (Helm, Ansible, ArgoCD idioms)
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

- Review every diff before committing — treat AI output like a PR from a new team member
- Don't put real credentials, internal hostnames, or sensitive config in prompts
- When an AI answer seems confident but wrong, it probably is — verify against official docs
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

## Related Resources in This Workspace

| Resource | Where |
|---|---|
| The Shift — engineering skills in the age of AI | `docs/the-shift.md` |
| Using AI outside your expertise — case study | `docs/ai-for-unfamiliar-domains.md` |
| Ansible playbook examples | `ansible-examples/` |
| ArgoCD / GitOps patterns | `argo-examples/` |
| OpenShift troubleshooting guides | `ocp-troubleshooting/` |
| AAP 2.5 token 404 root cause write-up | `docs/AAP-controller-token-404-summary.md` |
| Cursor commands | `.cursor/commands/` |
| Cursor skills | `.cursor/skills/` |

---

*This guide was written with AI assistance (GitHub Copilot). See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for full context on AI-generated content in this workspace.*

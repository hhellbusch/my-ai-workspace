---
review:
  status: unreviewed
  notes: "AI-generated essay from prior session. Argument and framing need author read. Practical commands (du, find, df) are standard; privacy framing is editorial and should be verified as representative of author's actual view."
---

# The Case for Local: Disk Management as a Privacy-First AI Task

> **Audience:** Engineers, sysadmins, and technical managers curious about where local AI tools make more sense than cloud ones.
> **Purpose:** A concrete case study of using an AI assistant to diagnose and plan disk space cleanup — and an argument for why this particular task belongs on a local model rather than a cloud one.

---

## The Problem It Solves

Disks fill up slowly, then suddenly. The symptoms are familiar: package installs start failing, builds run out of space, the OS starts warning about low disk. Diagnosing *where* the space went is a different problem than fixing it — it requires iterative shell analysis, judgment about what's safe to delete, and knowledge of what various directories actually contain.

The instinctive fix is to paste your filesystem layout into a cloud AI chat and ask for help. This works — but it comes with a tradeoff most people don't stop to consider.

---

## Why This Task Is Private by Nature

When you run `du -sh ~/*` to find what's taking up space, the output is a directory listing of your working life. It reveals:

- What software you have installed and what you've experimented with
- What projects you're working on
- What you started and abandoned (half-finished experiments, old virtualenvs, deprecated tooling)
- How your workflow is organized and what tools you rely on

Sending that to a cloud API means all of it — employer project names, abandoned side projects, research directions, organizational structure — leaves your machine. For a one-off session that might feel acceptable. For a recurring task run on a schedule, it isn't.

A local model has full access to your shell and produces the same analysis. Nothing leaves the machine.

---

## What the Analysis Actually Looks Like

The session that produced this document was conducted with a cloud assistant — which is itself illustrative. A cloud model can run this analysis. So can a local one. The argument for local isn't capability; it's that this particular task shouldn't have to leave the machine. Everything the analysis surfaces — directory names, project paths, what software is installed and abandoned — is a fingerprint of how someone works. A local model provides the same result with none of that exposure.

The session started with a single command:

```bash
df -h /
```

Output: **98% full, 23G remaining** on the main partition.

From there the analysis followed a consistent loop — run a command, interpret the output, decide where to drill down next.

### Step 1: Find the top-level offenders

```bash
du -sh ~/* ~/.* 2>/dev/null | sort -rh | head -20
```

This surfaces the largest directories across both visible and hidden locations. Hidden directories (dotfiles) are where most of the surprise consumption lives — caches, tool data directories, and virtualenvs that aren't visible in a normal file browser.

Representative output from a real session (paths genericized):

```
~/.cache/huggingface       123G
~/project-data             186G
~/.local/share/llm-store    81G
~/.local/share/application  59G
~/.venv (project root)       8G
~/.cache/pip                20G
~/.cache/uv                8.2G
```

**Takeaway:** The biggest items are almost never in obvious places. In this case, seven directories hidden behind dots accounted for the majority of disk usage.

### Step 2: Categorize by decision type

Not all large directories are equal. The analysis sorted them into three categories:

**Caches — delete freely.** Package download caches (`~/.cache/pip`, `~/.cache/uv`, `~/.cache/go-build`, shader caches) exist only to speed up future operations. They regenerate automatically. Deleting them has no consequences other than a slightly slower first run of whatever tool uses them. In this session that was ~28G recovered with a handful of one-line commands.

**Reproducible environments — delete if not in active use.** Virtual environments (Python `venv`, `virtualenv`, `.venv`) and compiled dependency trees are large but fully reproducible from a requirements file. A project `.venv` containing PyTorch, a GPU inference library, and supporting packages can easily reach 8–40G. If you're not actively running that project, the environment is recoverable on demand and can be deleted now.

**Unique data — requires a decision.** Application databases, self-hosted service data, and any directory containing state that isn't backed up elsewhere cannot simply be deleted. In this session one directory held ~186G of data from a self-hosted application that had accumulated over time. The right move — delete, relocate to another drive, or symlink out — depends on whether the service is still in use and what the data is worth. This is a human judgment call, not something to automate.

### Step 3: Drill into the largest items

Once categories are established, the analysis drills into each:

```bash
du -sh ~/.cache/huggingface/hub/* | sort -rh
```

```
42G    models--vendor-a--large-model
32G    models--vendor-b--model-variant-1
32G    models--vendor-b--model-variant-2
19G    models--vendor-c--coder-model
```

This surfaces a pattern: four large models downloaded at different points, some overlapping with models stored by other tools. The HuggingFace cache, the local LLM runner store, and an abandoned experiment virtualenv were all holding copies of (or dependencies on) models in the same family.

---

## The Irony Worth Naming

In this session, the single largest category of disk consumption was **AI experimentation** — model weights downloaded for image generation, large language model runners with multiple model families, abandoned inference server setups with their full dependency trees. The combined total was over 400G.

The session itself was conducted with a cloud assistant — which sharpens the point rather than softening it. A cloud model diagnosed the space consumed by local AI experiments. The work was straightforward: run commands, interpret output, present options. Nothing about the analysis required a frontier model. A small quantized model running locally handles `du` output, categorizes directories, and presents ranked options just as well — and none of the filesystem data has to leave the machine to do it.

The principle: the right model for a task is the smallest one that can do it reliably. Disk analysis is well within what a 7B parameter model handles. The only reason to use a cloud model for it is convenience. Convenience has a cost that's easy to overlook when the task feels routine.

---

## The Iterative Pattern

What makes disk analysis a good fit for an agentic local LLM isn't the complexity of any individual step — it's the number of steps and the back-and-forth between running commands and interpreting results.

The loop looks like this:

```
Run df/du command
       ↓
Interpret output — what category is this?
       ↓
Drill down into the largest items
       ↓
Present options with size and risk for each
       ↓
Human decides — delete, relocate, or keep
       ↓
(repeat for the next item)
```

This is a natural fit for an agent with read-only shell access. "Read-only" is the key constraint — the agent can run `du`, `df`, `find`, and `ls` freely, surface findings, and make recommendations, but the actual deletions happen only after explicit human approval. The agent never runs `rm`.

That constraint matters because the cost of a wrong recommendation is low (you don't act on it) while the cost of a wrong deletion is potentially high (data is gone). Keeping the human in the loop on the destructive step costs almost nothing in this workflow.

---

## What a Recurring Agent Would Look Like

Running this analysis manually once solves the immediate problem. The more useful version runs on a schedule and surfaces changes before they become critical. The following setup hasn't been built yet — it's a natural next step from what the manual session demonstrated.

A practical setup:

- **Trigger:** A systemd timer or cron job, weekly or monthly
- **Model:** A small quantized model running locally — 7B to 14B parameters is sufficient; a model already in use for other tasks incurs no additional overhead
- **Tool access:** Read-only shell — `du`, `df`, `find`, nothing else
- **Output:** A ranked list of directories that have grown since the last run, flagged against configurable thresholds (e.g., "flag anything that grew more than 5G")
- **Delivery:** Written to a file, printed to terminal on next login, or sent to a local notification

The entire pipeline runs on your hardware. Nothing about your filesystem is transmitted anywhere. The model that interprets the output is the same one you might already be running for other tasks.

This is a meaningfully different posture than a cloud-connected monitoring tool, which by definition requires your data to leave your machine to be analyzed.

---

## When Local Beats Cloud

This case study illustrates three conditions where a local LLM is the better choice:

| Condition | Why it matters |
|---|---|
| **The data is private by nature** | Filesystem layouts, directory names, and application paths reveal organizational context you shouldn't routinely send to external APIs |
| **The task recurs on a schedule** | A recurring process that phones home to a cloud API on a schedule creates ongoing exposure, not a one-time tradeoff |
| **The output is verifiable before acting** | Every recommendation in this workflow can be independently checked — you can see the directory size, decide whether the data matters, and choose not to act. You don't need to trust the AI's judgment; you just need it to surface the right information |

The inverse is also true. Local is the wrong choice when the task requires broad general knowledge the model wasn't trained on, when low-latency response at scale matters, or when the hardware cost of running a model locally exceeds the privacy or cost benefit of doing so. Disk management hits none of those conditions.

---

## Related Reading

- [Running a Local LLM: Setup, Tradeoffs, and Real Electricity Cost](local-llm-setup.md) — how to get a local model running, which tools to use, and when the hardware investment makes sense
- [Using AI to Work Outside Your Expertise](ai-for-unfamiliar-domains.md) — a case study of the same iterative describe-observe-correct loop applied to image processing
- [The Meta-Development Loop](the-meta-development-loop.md) — on noticing where AI fits into a workflow and building lightweight tooling around it

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. The session it describes was a real working session — findings and numbers are drawn from it, with paths and identifying details removed. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Batch 02 Findings: Workbench configuration and triggers

**Sources analyzed:** ref-05, ref-06, ref-09, ref-16
**Date:** 2026-10-13
**Claims under test:** C5–C8
**Article:** none — claims checked against Plural's own docs

Official docs (Tier 1 for what Plural documents). These pages describe configuration and intended behavior. They do not measure whether a job's conclusion is correct.

---

## ref-05: Workbenches index

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/workbenches/index.md
**Claims:** C5, C6 (partial), C7. C8 is absent.

**Source actually says:**

- A workbench is a named, project-scoped environment. The overview sentence bundles "a system prompt, a set of capabilities, connected tools, and automation triggers."
- The workbench object also "defines the agent's identity (name, system prompt), the project it belongs to, the agent runtime to use, which capabilities are enabled, which tools are attached, and who has access."
- A job is "a single run of the agent against a prompt." Status values are `pending`, `running`, `complete`, `failed`. It has "a streaming activity log." At runtime the agent emits "a live stream of activities" and, when finished, "a structured conclusion that can include summaries, dashboards, follow-up todos, topology pointers, and opened pull requests."
- Tools are managed globally, then attached to a workbench.
- Skills are "instruction files" loaded "from a Git repository or defined inline in the workbench" and "included in the agent's context alongside the system prompt."
- Jobs start from the Launch tab (UI), Console REST or GraphQL `createWorkbenchJob`, webhook triggers (observability alerts and issue tracker events), cron, or by @mentioning the workbench bot in a Slack channel. Webhook, cron, and chatbot bindings are configured on the workbench.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

- **C5** matches the concept definition: name, project, system prompt, capabilities, tools, agent runtime, access. The overview also puts automation triggers in the bundle; C5 leaves those out. The conclusion list is optional ("can include"), and the doc says "topology pointers" and "follow-up todos," not a topology object or a todo list as a guaranteed shape. A job is a run against a prompt; C5 does not mention the prompt.
- **C6** is only partly here. Context-alongside-the-system-prompt is explicit. This page also says skills can be defined inline. It does not say they are read before the job, does not mention a Plural skill library, and does not describe git ref, folder, filenames, or fetch-at-job-start. "Not a separate runtime" is not stated.
- **C7** matches this page: UI, REST or GraphQL, webhook (alerts and issue trackers), cron, Slack @mention. Later pages add more start paths (ref-16).

**Impact:** Same shape as a named agent config plus a run record: prompt in, status and a live log, then a structured result that may include a PR. Skills, on this page, are extra instruction files in the same context as the system prompt — the same role as a `SKILL.md` loaded into a session — with an inline option this index mentions and the wizard page does not. Slack @mention, REST, and GraphQL are first-class job starts here; a local cron or a repo webhook is not the whole trigger list.

---

## ref-06: Setting up a workbench (wizard, skills)

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/workbenches/configuration.md
**Claims:** C5 (wizard fields), C6 (primary). C7 only via Launch, cron, and webhook links. C8 absent except example names and starter prompts.

**Source actually says:**

- Prerequisites: tools under **Workbenches → Integrations** (Datadog, Prometheus, GitHub, Slack, and so on) can be added later. Coding agent requires an `AgentRuntime` on the management cluster.
- Five-step wizard: (1) name, description, Plural-native capabilities; (2) skills; (3) coding agent; (4) access policy; (5) attach tools. The name must be unique within the Plural instance. It shows up in job logs, webhook confirmations, and chatbot messages.
- Capabilities need no external credentials; Plural authenticates internally and access still respects existing RBAC. Infrastructure: Services, Stacks, Kubernetes, Pod logs, Vulnerabilities. Observability: Metrics, Log aggregation, which use backends from Observability Integration. Pod logs are a direct Kubernetes stream and work without an observability backend.
- Skills: "instruction documents the agent reads before executing a job," for runbooks, tribal knowledge, or tool-usage guidance "too detailed or too specific to put in the system prompt."
- Plural skills: a library "maintained by Plural" that "cover[s] standard SRE workflows." Select any number from the **Plural skills** tab. The page does not name the skills.
- Git skills: repository already registered in Plural, git ref (branch or tag), folder, and skill file names one per line relative to that folder. "Skill files are fetched from Git at job start."
- Coding agent is optional. Leave the runtime unset when the workbench does not touch source code.
- Access: read (see workbench and job history) and write (create jobs, edit configuration, manage automation). Empty lists fall through to the parent project's policy.
- Tools: only integrations already created can be attached. The page recommends a tight list.
- First job: prompt on the **Launch** tab. The agent streams activities and produces a structured conclusion. Links from there: save the prompt, cron, webhook. Edit reopens the wizard; changes apply on the next job. Delete removes the workbench, job history, schedules, webhooks, and saved prompts.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

- **C6** is the strongest match in the batch. Instruction documents, read before the job, vendor library, and git pointer (registered repo, ref, folder, filenames, fetch at job start) are all stated. "Alongside the system prompt" is ref-05's wording; this page says the material is too specific to put *in* the system prompt, which is the same split. "Not a separate runtime" is a fair reading of step 2 versus step 3, and the docs never say it. Inline skills from ref-05 do not appear in this wizard.
- **C5** is incomplete if this page is the configuration source. The wizard documents capabilities, optional agent runtime, access, and tools. It never shows a system prompt field, even though ref-05 and ref-09 treat a system prompt as part of the workbench. Agent runtime is a coding-agent slot you can leave unset, not something every workbench must set. Name uniqueness is instance-wide; ref-05's "project-scoped" still holds as the parent project, with access falling through to that project's policy.
- **C7** on this page is Launch, plus pointers to cron and webhook. No API and no Slack @mention.

**Impact:** A git skill here is not "point the agent at a skills directory and load every `SKILL.md`." You register the repo in Plural, then pin ref, folder, and an explicit filename list; those files are pulled when the job starts. There is no documented AgentSkills frontmatter or progressive disclosure. The Plural library is a second, vendor-maintained set whose contents these four sources never list. The coding agent is the separate runtime (`AgentRuntime` on the management cluster). Skills are the instruction layer in front of that, or in front of an operational workbench with no runtime set. Plural-native capabilities (services, stacks, Kubernetes, pod logs, vulnerabilities, metrics, log search) are console data exposed as tools under existing RBAC — that is the part a `SKILL.md` plus a generic shell does not include unless you already built those tools.

---

## ref-09: Common use cases

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/workbenches/use-cases.md
**Claims:** C8 (primary). C6 only as "behavior is shaped by skills." C5 only as an optional short system prompt. C7 as webhook, cron, and manual jobs inside these examples.

**Source actually says:**

The description calls these "Worked examples." The body says each pattern is "a complete workbench setup." Behavior is shaped by Plural library skills or Git runbooks. "You do not need to write a system prompt from scratch"; add a brief one "if needed." None of the four setups names which skill files to attach.

| Pattern | What the page says happens | What setup actually requires |
| --- | --- | --- |
| Alert root cause analysis | Webhook on a Datadog, Grafana, or other supported alert creates a job. The agent queries the service, Kubernetes resources, logs, and metrics. The result contains a diagnosis, the signals behind it, and next steps. Optional `@daily` cron summarizes the last 24 hours. | Capabilities: Services, Kubernetes, Pod logs, Metrics, Log aggregation. Tool: Prometheus or Datadog. Trigger: **••• → Webhook trigger**, regex or substring (example `"severity":"critical"`). |
| Slack incident channel creation | High-severity webhook. The agent creates a Slack channel, invites responders, and posts service status, recent errors, and inferred topology. The page says the channel already has "the first five minutes of investigation." | Capabilities: Services, Kubernetes, Pod logs. No Metrics or Log aggregation. Tool: Slack bot with `channels:manage`, `channels:join`, `chat:write`. Public-channel create and invite; Slack admin approval may be required. Trigger: observability webhook scoped to high-severity or production. |
| Cost information and reporting | `cloud-query` loads Steampipe Postgres FDWs for AWS, GCP, and Azure. Per Cloud connection the agent gets `cloud_schema`, `cloud_tables`, and `cloud_query`. A built-in calculator does arithmetic. The page calls this a design choice so numbers are computed rather than recalled. Weekly cron (or ad-hoc questions) aggregates by service or team tag, looks for anomalies versus prior periods, and can post to Slack. | Capabilities: none. Tool: Cloud connection with read-only billing IAM (`ce:GetCostAndUsage` and `ce:GetCostForecast` on AWS; Billing Account Viewer on GCP; Billing Reader on Azure). Optional Datadog or Prometheus. Optional Slack. Cron example: `0 9 * * 1` (Monday 09:00 UTC). Manual Launch prompts are also in scope. |
| Ticket-driven infrastructure self-service | Jira or Linear ticket with a label or project match. The agent "fulfill[s] — or at least draft[s]" the change, opens a PR on the GitOps repo, and comments with the link. | Capabilities: Services, Stacks, Kubernetes. Coding agent in **Write** mode, GitOps repo on the allowed list. Tools: Jira or Linear; optional GitHub, GitLab, or Bitbucket. Trigger: issue webhook, substring or regex (example `"infra-request"`). Babysitting is recommended so a person reviews each proposed commit while the workbench is new. |

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

- The four scenarios C8 names are on this page. "Slack incident response" is broader than the heading, which is channel creation plus an initial situation report, without the observability capabilities the RCA example uses.
- The description labels them worked examples. The body writes several outcomes as what the agent does (diagnosis, five minutes of investigation, anomaly identification, "eliminate hallucination"). Those are the pattern's intended behavior, not a measured or guaranteed result. Self-service is the only one that hedges in the procedure itself ("or at least draft") and points at babysitting before unattended writes.
- Skills are required in the introduction and missing from every setup list. A reader can satisfy the published checklist without attaching a skill.
- Webhook menu label here is **Webhook trigger**. ref-16 says **Webhooks**.
- Slack in this page is a tool the agent calls. It is not the Slack @mention job start from ref-05.

**Impact:** These are recipes: which capabilities, which external tool, which trigger. They are not evidence that the agent will produce a correct RCA, a useful incident channel, an accurate cost anomaly, or a safe infra change. Cost is the one that is mechanically different from "put a billing runbook in `SKILL.md` and cron it": the documented path is Steampipe foreign tables plus SQL tools plus a calculator, with billing IAM on a Plural Cloud connection. Self-service needs the coding agent in Write mode against an allowlisted GitOps repo, plus an issue-tracker webhook — a skill file does not open that PR. Someone who already runs Claude Code, Codex, or Cursor can duplicate the *prompt and schedule*; the documented Plural setup also binds Plural-native capability flags, a console access policy, and (for self-service) that coding runtime.

---

## ref-16: Automating workbench jobs

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/workbenches/automation.md
**Claims:** C7 (cron and webhook depth). C8 only as examples (nightly health check, weekly cost summary, `Plural fix this`). C5 and C6 are absent.

**Source actually says:**

- Automatic runs: cron, webhook triggers, and post-merge follow-ups. Cron and webhooks are managed from the workbench overflow menu. Follow-up prompts are configured in source control or CI.
- Cron: **••• → Cron schedules**. Fields are prompt (same rich input as a manual job), crontab in UTC (standard expressions and shortcuts such as `@daily` and `@weekly`; the UI previews the next five runs in local time), and **Run as** (defaults to the workbench bot user).
- Webhook sources: observability (Datadog, Grafana, PagerDuty, and others, registered under Observability Webhooks) and issue trackers (Jira, Linear, GitHub Issues, and others). Creating a trigger can create the source; Plural generates a URL and secret.
- Trigger fields: name, webhook source, match type (substring or regex on the raw payload body), match value, case insensitive, prompt (template variables from payload metadata), **Run as** (default bot user), priority (higher priority wins when several triggers match).
- On receipt, Plural evaluates every trigger on every workbench registered for that source. Each match creates a job, links it to the alert or issue, and shows it under Jobs plus Alerts or Issues. "The agent has access to the full alert or issue context."
- A documented pattern is match value `Plural`, substring, case-insensitive, so text such as "Plural deploy this" or "Plural fix this" starts a job. Supported surfaces named here: GitHub PR comments, GitLab MR notes, Jira, Linear, Bitbucket, Azure DevOps, and others. For Jira, the match runs against the issue description, not individual comments; the text needs to be in the description or title. For this pattern, "the full issue or comment body is forwarded to the agent as its prompt."
- Post-merge: a GitHub Actions workflow can send a follow-up prompt after the PR merges and GitOps reconciliation completes, so the same workbench can check live state. The workflow itself is on another page.
- Flows: on a flow detail page, **Start workbench job** picks a workbench and a prompt. The job is scoped to that flow's services and pipelines.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

- Cron and webhook match C7, with mechanics C7 does not state: UTC crontab, run-as user defaulting to a bot, substring or regex on the raw body, priority across triggers, and fan-out across every workbench listening to that source.
- This page does not document UI Launch, REST, GraphQL, or Slack @mention. Those are ref-05. Slack @mention and the `Plural` issue/PR mention are different mechanisms; this page only has the latter.
- C7 omits three starts this page adds: post-merge GitHub Actions follow-up, **Start workbench job** on a Plural Flow, and the `Plural` mention convention (with the Jira description/title limit).
- The trigger form has its own prompt field, including template variables. The `Plural` mention section says the issue or comment body is forwarded as the agent's prompt. The page does not say how that interacts with the trigger's prompt field.

**Impact:** Plural cron is a workbench schedule in the console: a fixed prompt, UTC cron, running as a chosen user or the workbench bot. It is not a host crontab that invokes Claude Code or Cursor. Webhooks are also console objects: you register the provider once, then match the raw payload and start a job already tied to that alert or issue. A generic webhook that posts into a coding agent can do the same job only if you build the match, the identity (`Run as`), and the link back to the alert yourself. The `Plural fix this` pattern is a naming convention on comments and tickets, not a Slack @mention and not a Claude Code hook. Flow-scoped start and post-merge follow-up have no counterpart in "I already have cron and webhooks" unless those systems already know Plural flows and GitOps reconcile.

---

## Batch Summary

- **Verified:** 0
- **Verified with caveats:** 4 (ref-05, ref-06, ref-09, ref-16)
- **Problematic:** 0 (misleading 0, unsupported 0)
- **Unverifiable:** 0
- **Claim rollup:** C5 caveats, C6 caveats, C7 caveats, C8 caveats. No claim is unsupported. No claim is clean of a caveat.

**Key pattern:** The docs do describe a workbench as a named project config (prompt, capabilities, tools, optional coding runtime, access, triggers) and a job as one prompted run with status, a live activity log, and a conclusion that *may* include summaries, dashboards, todos, topology pointers, and PRs. Skills are instruction documents in that context — a Plural-maintained library plus an explicit git file list fetched at job start — and the coding agent is a different, optional runtime. Every documented "use case" is a worked setup recipe. The outcome sentences (diagnosis, five minutes of investigation, anomaly found, hallucination eliminated) are not warranted by these pages.

**What these pages add beyond `SKILL.md` plus your own cron or webhooks:**

- Console capabilities over Plural's own service, stack, Kubernetes, pod-log, vulnerability, metrics, and log data, under existing RBAC, with no extra credentials for those native tools.
- A job record (status, stream, structured conclusion) and an access policy (read vs write, else the parent project).
- Git skills as a pinned file list on a repo already registered in Plural, refreshed at job start, plus an unnamed vendor skill library.
- Triggers that are workbench bindings: cron as a bot user, payload substring/regex webhooks linked to the alert or issue, Slack @mention of the workbench bot, `Plural …` on issues and PR comments (Jira: description or title), flow-scoped start, and a post-merge GitHub Actions follow-up.
- Cost and self-service depend on product machinery (Steampipe SQL tools and calculator; coding agent Write mode and babysitting), not on the skill text alone.

**Doc gaps inside this batch:** ref-05's inline skills do not appear in the wizard. The wizard never shows the system prompt field the other pages assume. ref-09 says **Webhook trigger**; ref-16 says **Webhooks**. The skill library's actual files are not listed. Slack @mention is only on the index, not on the automation page.

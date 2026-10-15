# Batch 04 Findings: Coding agent, AgentRuntime, hosting, sentinels

**Sources analyzed:** ref-08, ref-10, ref-14, ref-15
**Date:** 2026-10-13
**Claims:** C13 (coding agent), C14 (AgentRuntime types), C15 (Plural Cloud vs self-host), C16 (sentinels vs always-on troubleshooting)

These four pages are official Plural documentation (fetched 2026-10-13 from `pluralsh/documentation`). They are vendor docs, not independent confirmation that the behavior ships as written.

---

## ref-08: Coding agent

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/workbenches/coding-agent.md

**Claims:** C13 — Coding agent is optional. It runs in a sandboxed Kubernetes pod via AgentRuntime. Analyze mode reads code and reports findings; Write mode can commit and open PRs. Babysitting watches PR comments and CI and pushes more commits until merge or timeout. Examples: crashing service → GitOps PR, Terraform drift → IaC PR, CVE → dependency bump PR.

**Source actually says:**

Coding capabilities are optional. Workbenches that only query metrics, triage alerts, or summarize Kubernetes state "do not need a coding agent configured."

The coding agent "runs inside a sandboxed Kubernetes pod managed by an `AgentRuntime` resource on your management cluster." An AgentRuntime must be deployed before coding can be enabled. The page points setup at provider credentials for "Claude, OpenCode, or Gemini," pod resource requests and limits, and network policies for the agent namespace. A runtime shows up in the workbench wizard once it is `default: true` or at least one runtime exists.

Workbench creation, Step 3, has two modes:

| Mode | Doc text |
|---|---|
| Analyze | "Read source code, reason about it, and include code-level findings in job conclusions. Cannot commit changes or open PRs." |
| Write | "Everything in Analyze, plus: commit changes and open pull requests against the configured repositories." |

The page recommends starting in Analyze and switching to Write after seeing real job output.

Repositories are an allow-list of Git clone URLs. If the runtime already has an allow-list, the UI asks you to pick from that list. "The agent only accesses the repositories you list here."

Babysitting is Write-mode only, and only when **Enable babysitting** is on. The agent opens a PR, then "continues to monitor it — watching for PR review comments and CI failures and pushing additional commits to address them. The session ends automatically when the PR is merged or when the session times out." With babysitting off, "the agent opens a pull request and exits, leaving your normal review process to handle the rest." The page says humans "stay in the review loop." It does not give the timeout duration.

Write-mode PRs show up on the job Result panel under Pull requests, with links to the SCM provider.

The three examples are under "Combining coding with operational capabilities," described as pairings:

- Kubernetes + Pod logs + Write mode — "investigate a crashing service, identify the offending configuration, and open a PR against the GitOps repo to fix it"
- Stacks + Write mode — "detect a drift in Terraform state and open a PR to reconcile the IaC definition"
- Vulnerabilities + Write mode — "scan for CVEs in Plural-managed services and open PRs to bump affected dependency versions in the relevant repos"

The page calls this "a full remediation loop: observe, diagnose, fix, and create a reviewable artifact — all within a single workbench job." The overview also says the agent can go from "I found a problem" to "here is a PR that fixes it" in a single job run "without manual intervention."

No maturity label (preview, beta, GA) appears on this page. Codex and Cursor are not named. Babysitting is not described as merging the PR itself; the stop condition is merge (by someone) or timeout.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

The optional flag, the AgentRuntime pod, Analyze vs Write, babysitting's watch/commit/stop behavior, and the three remediation examples are all in this page in essentially the claim's words.

Caveats that change how the claim should be used:

- Babysitting is a switch, not part of Write mode. Write without it opens a PR and exits.
- The three examples are capability pairings (Kubernetes + Pod logs, Stacks, Vulnerabilities), not things the coding agent does alone. The CVE case is "Plural-managed services," not an arbitrary repository CVE.
- "Sandboxed" is this page's word. The page does not define the sandbox. It defers to AgentRuntime plus network policies (see ref-10). That is a different "sandboxing" than ref-14's enterprise guide for cutting egress to Plural.
- "Without manual intervention" sits next to "humans stay in the review loop." The unattended part is producing and iterating on the PR. Merge is an end condition, not something the page says the agent performs.
- No timeout value is specified.
- Provider list on this page is Claude, OpenCode, or Gemini. No Codex runtime.

**Impact:**

This is a workbench job runner around Claude, OpenCode, or Gemini, hosted as a pod on the management cluster. It is not a separate model, and these pages never host Cursor or Codex.

Compared with running Claude Code, Codex, or Cursor yourself:

- You do not sit in a local CLI or IDE session. A workbench job supplies the operational trigger (crash, Terraform drift, CVE scan) and the coding runtime does the repo work.
- Repo scope is an allow-list on the workbench (or on the runtime), not whatever the laptop credential can reach.
- Analyze / Write are Plural modes on top of the underlying agent. Analyze is read-and-report into the job conclusion. Write may commit and open a PR.
- Babysitting is Plural's outer loop: PR comments and CI failures become more commits until merge or timeout. That is closer to an unattended cloud coding session than to an interactive Cursor chat. It still leaves review with humans.
- The GitOps / IaC / dependency PR is the artifact. Plural's own signals (pod logs, stacks, vulnerability scan) are what a local Claude Code or Cursor session does not have unless you wire them in yourself.

---

## ref-10: Configure an AgentRuntime

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/plural-ai/ai-agent/configure-agent.md

**Claims:** C14 — AgentRuntime types actually supported (quote the doc: CLAUDE, OPENCODE, GEMINI, and any mention of CODEX). aiProxy and whether API keys are required. codebase-memory-mcp and spec.memory. Any model-name oddities (e.g. a Codex runtime example using a Claude model string).

**Source actually says:**

Prerequisites: a repository connected in Plural Console ("agents can only select from configured repos"), and an SCM connection configured outside the agent UI.

`AgentRuntime` "define[s] the provider, credentials, and runtime options." The worked example:

```yaml
apiVersion: deployments.plural.sh/v1alpha1
kind: AgentRuntime
metadata:
  name: claude-default
  namespace: plrl-agents
spec:
  targetNamespace: plrl-agents
  type: CLAUDE
  default: true
  aiProxy: true
  config:
    claude:
      apiKeySecretRef:
        name: ai-config
        key: anthropic
      model: claude-3-5-sonnet-latest
```

The page then states, as a sentence: "Supported runtime types are `CLAUDE`, `OPENCODE`, and `GEMINI`."

CODEX does not appear anywhere in this file. There is no Codex runtime example, and no runtime whose type disagrees with its model string. The only model string is `claude-3-5-sonnet-latest` on `type: CLAUDE`.

`aiProxy: true` appears only in that YAML. The prose never defines aiProxy. The same object still sets `config.claude.apiKeySecretRef` to secret `ai-config`, key `anthropic`. The page does not say API keys are required, and it does not say aiProxy removes the need for a key. Field-level meaning is deferred to the AgentRuntime / AgentRuntimeSpec API reference (not in this batch).

Codebase memory, quoted:

"Agent runtimes include the `codebase-memory-mcp` server for graph-backed code search. By default, its indexes are stored only in the agent pod cache and generated `.codebase-memory/` artifacts are excluded from commits."

"`spec.memory: true`" enables "team-shared memory persistence by default." Agents then index "with persistent artifact export enabled, allowing `.codebase-memory/graph.db.zst` and the related `.gitattributes` update to be committed so future runs can bootstrap from the shared graph." Leave it unset or `false` to keep the index "local to the runtime cache."

Other runtime knobs on this page:

- Pod template, container name `default`, for CPU/memory requests and limits (example: request 1 CPU / 2Gi, limit 4 CPU / 8Gi).
- Optional browser sidecar resources at `spec.browser.container.resources`.
- NetworkPolicy in `spec.targetNamespace`. The example allows DNS (kube-system) and TCP 3128 to an `egress-proxy` in an `egress` namespace, and says to replace the selectors with the destinations agents must reach (SCM, AI endpoints, package registries).
- Optional `spec.dind: true` for Docker-in-Docker when the agent must build images or run containers.

Console path "Plural AI → Agent runs" is separate from the workbench wizard in ref-08. A run takes a prompt, a repository (recent list or custom URL), mode `WRITE` or `ANALYZE`, and a provider "matching the runtime type you configured." The run streams a timeline. "In `WRITE` mode, the agent applies changes and opens a pull request." "In `ANALYSIS` mode, the agent produces a markdown summary visible in the Console."

The CRD `apiVersion` is `deployments.plural.sh/v1alpha1`. The page has no preview, beta, or GA label.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

The supported-type sentence is exact: CLAUDE, OPENCODE, and GEMINI. CODEX is absent, so a claim that AgentRuntime supports a CODEX type is unsupported by this page. The feared model-name oddity (a Codex runtime pointing at a Claude model string) is also absent. The published example is internally consistent: CLAUDE + `claude-3-5-sonnet-latest`.

`codebase-memory-mcp` and `spec.memory` match the claim's topics and are specified as above, including the default commit exclusion and the shared `graph.db.zst` path when memory is on.

aiProxy is the gap. The flag is set to true in the only full example, beside an Anthropic API key secret. This page does not say what the proxy does, or whether a customer API key is still required when the proxy is on. That part is unverifiable from this file alone. ref-08's companion instruction is "with your AI provider credentials," which points toward bringing credentials, and still does not define aiProxy.

Secondary doc slips on this page, relevant when quoting modes:

- Step 2 says mode `ANALYZE`. Step 4 says `ANALYSIS` mode.
- Only the CLAUDE config block is exemplified. OPENCODE and GEMINI are named and not given `config` snippets here.
- This Console agent-run flow does not mention babysitting (that switch is ref-08's workbench coding step).

**Impact:**

Plural's documented coding hosts are Claude, OpenCode, and Gemini, each selected by `spec.type` and started by Plural (workbench job or Console agent run). Codex is not a documented runtime. Cursor is not mentioned. Running Codex or Cursor yourself is a different product path; these pages do not wrap either one.

Where Plural is the scheduler/host:

- It chooses the pod namespace (`plrl-agents` in the example), injects `codebase-memory-mcp`, applies the memory/commit policy, and can add DinD or a browser sidecar.
- It asks you for provider credentials in the CRD. The sample still carries an Anthropic key with `aiProxy: true`, so this page does not show a keyless "Plural pays the model" setup.
- Isolation is whatever you put in the pod template and NetworkPolicy. The sample egress is DNS plus an egress proxy, not a sealed default. `spec.dind: true` is an explicit hole for image builds.
- You talk to it through Console (prompt, repo, WRITE/ANALYZE) or through a workbench. The agent timeline and the PR or markdown summary come back in Console.
- `spec.memory: true` can commit `.codebase-memory/graph.db.zst` into the repo so the next run reuses the graph. A local Claude Code or Cursor session does not do that unless you add the same MCP and commit policy yourself.

---

## ref-14: Management cluster — Plural Cloud vs self-host

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/getting-started/how-to-use/mgmt-cluster.md

**Claims:** C15 — Plural Cloud (shared vs dedicated) vs self-host via `plural up` on AWS/Azure/GCP. Shared cap (10 clusters). Reasons to self-host. Sandboxing / removing egress to Plural requires an enterprise license key. Plural Cloud is publicly hosted.

**Source actually says:**

Two tiers: one management cluster (CD, Terraform management, dashboarding) and workload clusters for dev and prod.

Two ways to get a management cluster:

- **Plural Cloud** — "a fully managed instance of the Plural Console." "We offer bother shared infrastructure hosting with usage limits and lower cost, or dedicated hosting which is more secure and enterprise-ready."
- **Self-hosted** — "deploy and manage yourself on your own cloud environment," with "`plural up`."

Plural Cloud "will host the Plural Console, alongside its git cache, underlying postgres database, and the kubernetes-agent-server api." Start at https://app.plural.sh.

Shared vs dedicated, in the page's words:

- "`shared` instance can be created on a free trial but has a hard cap on 10 clusters to use to avoid overloading other tenants."
- "`dedicated` cloud instances get a dedicated k8s cluster and database, and are built to scale effectively infinitely." Dedicated "requires" "an enterprise plan" and "contact sales."

Cloud onboarding still has you run a cluster in your account. After the console is up, "You'll need to still create a small management cluster in your cloud to host the Plural operator and any cloud-specific secrets," so the cloud account stays "fully secured" and you avoid "exchanging root-level cloud permissions." The command is `plural up --cloud`. The page says this skips ingress and SSL setup. `plural up` also "bootstraps an entire GitOps repo."

Self-host section: "`plural up` is a single command to spawn our management cluster from zero in any of the big three clouds (AWS, Azure, GCP)."

Reasons to prefer that over Plural Cloud:

- **Security** — "you want to ensure Plural hosts absolutely no cloud-related permissions. You can even follow our sandboxing guide to remove all egress to Plural (this requires an enterprise license key)."
- **Networking** — "you want to host the Plural Console on a private network entirely. Plural Cloud currently is always publicly hosted."
- **Integration** — resources Plural needs, "for instance Git Repositories," may sit on private networks; "it's logistically easier to self-host and place it in an integrated network."
- **Scaling** — "complete control as to how Plural Scales." The page adds that dedicated cloud hosting "does this perfectly well too, but some orgs want their own hands on the wheel."

No maturity label on this page.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

Every factual piece of C15 is in this page:

- Shared cap is a "hard cap on 10 clusters," tied to a free trial and to protecting other tenants.
- Dedicated is a separate Kubernetes cluster and database, enterprise plan, sales contact. "Scale effectively infinitely" is the doc's claim, not a measured limit.
- Self-host is `plural up` on AWS, Azure, or GCP.
- Removing "all egress to Plural" is the sandboxing guide, and "this requires an enterprise license key."
- "Plural Cloud currently is always publicly hosted."

Caveats:

- `plural up` is both the self-host command and, as `plural up --cloud`, the Cloud onboarding step. Cloud is not "no cluster in your account." Cloud still wants a small in-cloud cluster for the operator and cloud secrets.
- Two different enterprise gates: dedicated Cloud hosting needs an enterprise plan; the egress-to-Plural sandboxing guide needs an enterprise license key. The page does not say the shared tier can cut that egress.
- "Sandboxing" here means the management plane stops calling out to Plural. It does not describe the coding-agent pod sandbox in ref-08 / ref-10.
- What Cloud actually hosts is named: Console, git cache, Postgres, kubernetes-agent-server API. The page does not say Cloud hosts the coding-agent pods. AgentRuntime in ref-08/ref-10 is "on your management cluster."
- Doc typo, immaterial to the claim: "bother shared."

**Impact:**

The coding agent does not run on your laptop. It runs in a pod on the management cluster, so where that cluster lives is the hosting decision.

- Shared Plural Cloud: vendor-hosted Console and control-plane data services, publicly reachable, 10-cluster cap, plus your own small `plural up --cloud` cluster. Lower operational burden, and the agent path still depends on a management cluster you attach.
- Dedicated Cloud: same public-host constraint ("always publicly hosted" is said of Plural Cloud, not only the shared tier), with a dedicated cluster and database under an enterprise plan.
- Self-host `plural up`: the management plane, including where you would schedule AgentRuntime pods, is in your AWS, Azure, or GCP account. Private Console, private Git, and no Plural-held cloud permissions are the documented reasons. Cutting the management plane's egress to Plural itself is an extra enterprise-licensed sandboxing step.

Running Claude Code, Codex, or Cursor yourself needs none of this fleet-management split. Plural's coding path sits on top of it. Self-hosting moves the scheduler into your cloud; it does not, on this page, replace the model provider. Agent egress to SCM and AI APIs is the NetworkPolicy topic in ref-10, separate from the enterprise "no egress to Plural" guide.

---

## ref-15: Sentinels

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/plural-ai/sentinels.md

**Claims:** C16 — What sentinels actually do (triggers, what they investigate, what they produce, limits). Relate to the "always-on troubleshooting engine" claim. Note maturity language if any (preview, beta, GA) or its absence.

**Source actually says:**

Title: "At-Scale Infrastructure Testing with Sentinels." Description: "Automate testing over any set of Kubernetes Clusters with the Sentinel Resource."

The problem statement is live integration testing across many clusters, because local unit tests do not catch infra differences. Sentinels "bundle a sequence of checks" that can:

- "Run terratest-based integration tests across any subset of your clusters and aggregate the results"
- "Tail logs across any set of clusters using search filters, and analyze it with AI and git-source rules files"
- "Deep-query a kubernetes resource on a cluster and analyze its health with AI and git-sourced rules files"

"Once a sentinel is defined, it can be run anytime on-demand via API." Triggers listed:

- "in our UI"
- "in github actions or other CI systems"
- "in Plural pipelines"

Use cases the page says they are "particularly well suited for":

1. "Validating kubernetes upgrades do not introduce regressions"
2. "Cross-cutting kubernetes operator changes (eg istio upgrades)"
3. "Validating network reconfigurations are safe."

Motivation for the AI: confirming infra health means "aggregating multiple textual datasources and interpreting them using some degree of discretion." "You simply cannot do that deterministically, so a governed AI-based approach is needed." Deterministic coverage is "a full terratest run" for paths like pods starting, volumes mounting, and networking.

The sample CRD (`deployments.plural.sh/v1alpha1`, `kind: Sentinel`) points at a git repo (`repositoryRef` infra/infra, `git.ref: main`, `folder: rules`) and two checks:

- `type: LOG`, rule file `logrule.md`, query `error`, duration `5m`, namespaces `cert-manager`, `external-dns`, `kube-system`
- `type: INTEGRATION_TEST`, format `JUNIT`, cluster tags `tier: dev`, job in namespace `plrl-deploy-operator` with service account `deployment-operator`. The comment says no job image is set because "we ship with a working integration test out of the box."

When that sentinel runs, "in parallel":

1. Query those namespaces' logs for 5 minutes for errors, then "analyze any results found according to a rule file specified in git." "You as the engineer can tune how the AI operates with that rule file."
2. "Launch our default terratest job across all `tier: dev` clusters, doing a basic sequence of health checks."

Run from Console at `AI -> Sentinels -> {sentinel-name}`. Screenshots are referenced; the page does not describe them in text. Full spec is linked to the Management API docs.

The third overview capability (deep-query a Kubernetes resource) has no `type:` in the sample and is not in the "what this particular sentinel will do" list.

The page does not say sentinels watch for failures, run on a timer, open pull requests, or apply fixes. It does not use the phrase "always-on troubleshooting engine." It does not say preview, beta, or GA.

**Verdict:** MISLEADING

**Details:**

MISLEADING applies to using this page as support for an "always-on troubleshooting engine." The page's own description is on-demand infrastructure testing. Count this source as misleading for that claim, and use the behavior below as the positive account of sentinels.

What is actually specified:

| | Documented behavior |
|---|---|
| Trigger | On-demand via API. UI, GitHub Actions or other CI, Plural pipelines. No interval, no "when a service fails," no Terraform-failure subscription. |
| Investigates | Predeclared checks: log lines matching a query over a duration and namespace list; terratest across clusters selected by tags; a described deep-query of a Kubernetes resource's health. |
| AI role | Interpret logs or resource health using a git-sourced rules file the engineer tunes. "Governed" is the page's word for that. |
| Deterministic role | Shipped terratest job (JUNIT) for basic health: pods, volumes, networking. |
| Produces | Aggregated integration-test results, plus AI analysis of whatever the log (or resource) check found, viewed in Console. No PR, commit, or remediation artifact is mentioned. |
| Limits in the sample | One git rules folder; log query `error` for `5m` in three system namespaces; integration tests only on `tier: dev`; checks run in parallel; default test image only if you omit `jobSpec` image. |
| Maturity | No preview, beta, or GA wording. CRD version on the page is `v1alpha1`, same apiVersion family as AgentRuntime. The page does not discuss API stability. |

The deep-query check is an overview bullet without a sample `type` or a worked run. Treat it as documented intent on this page, with the concrete contract limited to LOG and INTEGRATION_TEST.

Relation to the always-on troubleshooting claim: a troubleshooting engine that takes failed Kubernetes services and failed Terraform runs, investigates, and gets you to a fix is a different shape. Sentinels start when CI, a pipeline, or a person calls them, run a fixed check list aimed at upgrades, operator rollouts, and network changes, and return analysis plus test results. They do not, on this page, close the loop with a commit or a PR. That loop is the workbench coding agent in ref-08, and even there it is a job, not an always-on process.

**Impact:**

Sentinels are not a coding agent and not a stand-in for Claude Code, Codex, or Cursor. They are a cluster test harness with an optional LLM reading step controlled by a markdown rules file in git.

- You would not use a sentinel where you would open Cursor or Claude Code to edit a repo. The page never gives the sentinel a repository write path. ref-08's Write mode is the path that commits and opens PRs, and it is attached to workbenches, not to this Sentinel CRD.
- The AI inside a sentinel judges text (logs, and the described resource query) against your rules. It does not show up here as Claude, OpenCode, Gemini, or Codex, and it is not tied to AgentRuntime on this page.
- "Always-on" would mean the system starts itself from live failures. This page's sentinel waits for an API call. Scheduling that call from GitHub Actions or a Plural pipeline can make it regular, and the regularity is still the caller's, with a check list you wrote in advance.
- Anyone comparing this to running an agent themselves: the terratest half is ordinary integration testing Plural ships a default for; the AI half is a governed summarizer over logs you already filtered. Neither half is an interactive coding session.

---

## Batch Summary

- **Verified:** 0
- **Verified with caveats:** 3 (ref-08 / C13, ref-10 / C14, ref-14 / C15)
- **Misleading:** 1 (ref-15 / C16, for the always-on troubleshooting engine identification)
- **Unsupported:** 0 as a source verdict. CODEX as an AgentRuntime type is unsupported inside ref-10 (the page lists only CLAUDE, OPENCODE, GEMINI).
- **Unverifiable:** 0 as a source verdict. What `aiProxy: true` does, and whether it still requires the API key shown beside it, is unverifiable from ref-10.

**Key pattern:** Plural's documented coding path hosts Claude, OpenCode, or Gemini in a management-cluster pod and wraps them with workbench modes, repo allow-lists, and optional PR babysitting. It does not document Codex or Cursor as runtimes. Hosting is either public Plural Cloud (shared cap of 10 clusters, or dedicated enterprise) or `plural up` on AWS/Azure/GCP, and cutting egress to Plural is a separate enterprise-licensed step. Sentinels are on-demand, rules-file infrastructure tests, not that coding loop and not an always-on fixer.

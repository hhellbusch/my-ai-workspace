# Batch 03 Findings: Connections — tools, live context, MCP, and policy

**Sources analyzed:** ref-07, ref-11, ref-12, ref-13
**Date:** 2026-10-13
**Claims under test:** C9–C12

These four pages are vendor documentation. Verdicts score whether C9–C12 match what those pages say. They do not score whether the product behaves that way in a cluster.

---

## ref-07: Workbench tools

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/workbenches/tools.md

**Claims:** C9 (primary). The same page restates the C12 guardrail (deny, auto-approve, cannot widen access) and does not name the Rego package.

**Source actually says:**

Tools are reusable integrations a workbench agent calls during a job. They are configured globally, then attached to individual workbenches, so one Datadog connection or MCP server can be shared without re-entering credentials. A workbench can call only the tools explicitly attached to it (creation step 5, or Edit).

Plural-native capabilities are “built directly into the workbench runtime and require no external credentials or tool setup.” They are enabled per workbench with capability toggles. The table is:

| Capability | Scope the page states |
|---|---|
| Services | Plural-managed service deployments (health, rollout history, configuration, associated cluster) |
| Stacks | IaC runs, Terraform state summaries, run logs, failure details for Plural-managed stacks |
| Kubernetes | “Full Kubernetes API access across your managed clusters” — list and describe any resource |
| Pod logs | Raw container stdout/stderr streamed from Kubernetes pods |
| Vulnerabilities | Trivy findings auto-associated with Plural-managed services |
| Metrics | Query configured Prometheus-compatible backends via Plural’s observability integration |
| Log aggregation | Search and aggregate logs from configured backends (Loki, Elastic, and others) via that same integration |

“All native integrations respect your existing RBAC — enabling a capability here does not grant the agent access it would not otherwise have.” Later, built-in tools re-check authorization at execution time. Kubernetes tools federate the user running the job to the target cluster using their Console email and groups; the Kubernetes API server applies that identity’s native RBAC. “Attaching or enabling a built-in tool therefore does not give the agent broader access than the user already has.”

External tool types that require a setup form (credentials, endpoint URLs, tokens) include Prometheus, Datadog, Loki, Elastic (“Query and search indices in an Elasticsearch cluster”), Tempo, Jaeger, GitHub (read repos and list PRs; open PRs only in Write mode), GitLab, Bitbucket Cloud, Bitbucket Data Center, Slack, Microsoft Teams, Jira, Linear, HTTP (custom REST shape), and MCP (“Any Model Context Protocol server. Plural handles authentication and audit-logs every call”). Cloud tools are separate: a cloud connection (IAM role or credential set stored in Plural) plus Steampipe SQL tools (`cloud_tables`, `cloud_schema`, `cloud_query`) for AWS, GCP, and Azure. A calculator tool is always present.

Each tool has read bindings (who can see it and attach it) and write bindings (who can edit configuration and the access policy). Empty binding lists fall through to the parent project policy. Workbench policies, linked from this page, are Rego rules that can deny a call from actor, tool name, and arguments, or automatically approve a call that would otherwise wait for a person. “A policy cannot make an unavailable tool accessible or grant permissions the actor does not already have.”

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

C9’s capability names match the native table, in the same order. The RBAC sentence matches both the overview (“does not grant the agent access it would not otherwise have”) and the execution-time rule (no broader access than the user already has). Global configuration plus per-workbench attachment matches the overview and the “Attaching tools” section. Datadog, Prometheus, GitHub, Slack, HTTP, and MCP are real tool types on this page. The Elastic tool targets an Elasticsearch cluster; the page titles the tool “Elastic,” not “Elasticsearch.”

Scope the claim’s parenthetical list does not carry:

- Services, Stacks, and Vulnerabilities are Plural-managed. Vulnerabilities are Trivy findings on those services.
- Kubernetes is “your managed clusters,” not an arbitrary cluster. The capability blurb is list/describe. This same page’s policy example later assumes deletes can be blocked (for example in `kube-system`), so write-shaped Kubernetes tools exist elsewhere in the workbench model, but this table does not describe them.
- Pod logs are raw pod stdout/stderr. This page does not limit them to pods in a Flow.
- Metrics and log aggregation “require no external credentials or tool setup” as capability toggles, and they still query backends already configured in Plural’s observability integration. Prometheus-compatible metrics and Loki/Elastic-style aggregation are that path. Prometheus, Elastic, and Loki also exist as separate external tools with their own credential forms. “No extra credentials” is about the toggle, not about an unconfigured Prometheus or Elasticsearch.
- The external list in C9 is a subset. The page also documents Loki, Tempo, Jaeger, GitLab, both Bitbucket products, Teams, Jira, Linear, cloud/Steampipe, and the calculator.
- Workbench MCP on this page is authentication plus an audit log of every call. Confirmation, JWT, and “who can bind” are not specified here; those sentences live on the Flows MCP page (ref-12).
- The opening sentence calls tools “external integrations,” then the native section describes capabilities that are toggles rather than configured tools. C9’s native-versus-external split follows the section structure.

**Impact:** Relative to pointing Claude Code, Codex, or Cursor at the same MCP servers, this page adds an in-runtime tool set that is not an MCP server: Plural-managed service and stack state, Trivy findings on those services, pod logs, and metrics and log search through Plural’s observability integration, plus Kubernetes calls that the page says run as the Console user (email and groups) under the cluster’s own RBAC. Credentials for Datadog, Prometheus, GitHub, Slack, HTTP, and MCP are entered once in a global catalog and attached per workbench, with read/write bindings on who may attach or edit them. A workbench cannot call a tool that was not attached. Those controls are Plural product behavior. They are not properties of MCP itself. The page does not say this replaces MCP; MCP is one custom tool type, and Plural “handles authentication and audit-logs every call.”

---

## ref-11: Plural AI with Flows

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/flows/flow-ai.md

**Claims:** C10. One closing sentence says Flows can call MCP servers; it does not state C11’s governance list.

**Source actually says:**

Flows organize infrastructure data into one unit so AI can fetch related data “with high fidelity” and so the product has “a clear governance structure so you don't fetch what a developer shouldn't be able to see and have the AI regurgitate it to them.” The page says this is meant to stay “informative and enterprise grade even in highly regulated contexts.”

Flows are “pre-baked” with four abilities:

- Fetch Kubernetes configuration of all objects registered with the flow.
- Log-aggregation extraction of “only the logs emitted from kubernetes pods within the flow.”
- Vector-index incoming PRs associated with the flow, for semantic search toward line-of-code causes.
- A knowledge graph the AI uses to remember past incidents and how they were resolved, for a repeat issue.

Together that is “live kubernetes state, runtime information about the containers running in the Flow and historical code changes.” Flows can also call MCP servers “to implement various operational tasks and replace a lot of internal admin portals.”

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

C10’s four context items match the pre-baked list: objects registered with the flow, logs only from pods in the flow, vector-indexed PRs associated with the flow, and a knowledge graph of past incidents and prior resolutions. The governance sentence is a close paraphrase of “don't fetch what a developer shouldn't be able to see and have the AI regurgitate it to them.”

Limits on this page:

- This is Flows (Plural AI), not workbench capability toggles. Workbench pod logs and Kubernetes access in ref-07 are not described as flow-bounded.
- “Bounded context” is a summary phrase. The page says these four abilities come pre-baked. It also says Flows can call MCP servers for further operational data, and ref-12 says MCP can cover “any external data-fetching.” The four items are the built-in slice, not a closed set once MCP is attached.
- Log access here is log aggregation of pods in the flow, not the raw stdout/stderr stream described for workbench pod logs.
- PRs are “incoming” and “associated with the flow,” then vector-indexed. The page does not say every repository is indexed.
- Kubernetes objects are those “registered with the flow,” not every object on the cluster.
- Governance is stated as a property of organizing data into a flow. This page does not name RBAC, Rego, `plrl.wb.admission`, audit logs, or a confirmation step. “Enterprise grade even in highly regulated contexts” is positioning, not a control description.
- The page does not say enabling a flow grants cluster access the developer lacks. It frames the flow as the boundary on what gets fetched into the chat.

**Impact:** Attaching the same MCP servers to a coding agent does not, by these docs, assemble this context. Plural says the flow already holds registered Kubernetes objects, log aggregation limited to pods in that flow, a vector index of that flow’s incoming PRs, and a knowledge graph of past incident resolutions. The governance claim is that this unit stops the model from being handed data the developer should not see. MCP remains an add-on for operational tasks and admin-portal style actions, specified on ref-12, not the source of the four pre-baked context types.

---

## ref-12: Flow MCP servers

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/flows/mcp.md

**Claims:** C11. ref-11 only says Flows can call MCP; the governance list is this page. ref-07’s workbench MCP line (auth plus audit) is a different surface.

**Source actually says:**

“Plural Flows natively integrate with Model Context Protocol (MCP).” Once a server is registered, Flow chats call it via tool-calling. Examples: operational tasks in chat (add a user to a payment plan, show account details), a read-only Postgres MCP server, Jira or ServiceNow queries, and using Flows as a developer admin panel. The page points at Anthropic’s MCP server library and says the protocol could support any external data fetch.

“In addition to the base value of MCP though, Plural adds a few core governance features on top:”

- Audit logging of all MCP server calls.
- Confirmation workflows “in case you want to ensure user confirmation before the AI initiates an MCP tool-call.”
- “Authentication via JWT to end MCP servers,” so developers can implement auth and authz in server code.
- “Permissions as to who can access an MCP server within the Plural experience.”

The only manifest sets `confirm: false`, `authentication.plural: true`, and a write binding:

```yaml
apiVersion: deployments.plural.sh/v1alpha1
kind: MCPServer
spec:
  confirm: false
  url: https://plural-mcp.plural.sh
  authentication:
    plural: true
  bindings:
    write:
    - groupName: sre # only this group can bind this server to their Flows
```

A developer with sufficient permissions associates the server under Flow `MCP Connections`. If no tools are listed, the page says to suspect networking, or that the server is not broadcasting tools on its SSE endpoint.

**Verdict:** VERIFIED WITH CAVEATS

**Details:**

C11 matches the four bullets and the “on top” sentence. The page presents Plural as an MCP client with extra controls. It does not describe a substitute protocol.

Scope an evaluation has to keep:

- This object is `MCPServer` on Flows. Workbench MCP (ref-07) is a configured tool type. That page says Plural handles authentication and audit-logs every call. It does not document `confirm`, `authentication.plural`, or Flow bind bindings.
- Confirmation is optional (“in case you want”). The published example sets `confirm: false`, so the sample manifest does not require a human confirm before the tool call.
- JWT is the prose description. The manifest shows `authentication.plural: true`, not a customer-supplied JWT, issuer, audience, or claim list. The page says that arrangement makes it easier for the MCP server to implement auth and authz. It does not show the token.
- “Who can bind” matches the YAML comment on `bindings.write` (`groupName: sre` can bind the server to their Flows). The bullet text is broader: who can access the server inside Plural. The sample has no read binding.
- Association is a second step in the Flow UI after the server is registered. Registration alone is not described as putting tools into every flow.
- Tool discovery is tied to the server’s SSE endpoint.

**Impact:** The MCP servers themselves can be the same ones a coding agent would run. What this page adds, for Flows, is Plural-side governance around those calls: an audit log of every MCP call, an optional confirm-before-call flag (off in the sample), Plural JWT auth (`authentication.plural: true`) so the downstream server can authorize the caller, and a write binding for which group may attach the server to Flows. That is the page’s “on top of” list. It is not a replacement for MCP, and the sample shows a path where confirmation is disabled.

---

## ref-13: Workbench policies

**URL:** https://raw.githubusercontent.com/pluralsh/documentation/main/pages/plural-features/policy-management/workbench-policies.md

**Claims:** C12. ref-07 states the same deny / auto-approve / cannot-widen rules and does not name the package.

**Source actually says:**

“Workbench policies evaluate each matching tool call made by a workbench agent. They extend Plural RBAC and tool permissions with authorization rules that understand the current actor, the requested tool, and its arguments.”

“Workbench policies use the `plrl.wb.admission` Rego package.”

Input fields: `input.tool_name` (tool name), `input.tool` (arguments as an object; shape depends on the tool — a Kubernetes operation can include `namespace`, a logging tool an index and query), `input.actor` (current user: `id`, `name`, `email`, and `groups` when available).

Decisions:

- `deny[{"msg": "..."}]` blocks the call and returns the message.
- `approve[{"reason": "..."}]` automatically approves “a tool that supports approval” and records the reason.

Denial wins when several rules or attached policies decide. If no rule decides, the call continues through its normal authorization and approval path.

The info callout, repeated in the example’s intent: “A policy cannot make an unavailable tool accessible or grant permissions the actor does not already have. It adds guardrails to the existing workbench authorization model.”

The full example is `package plrl.wb.admission`. It denies `delete_k8s_resource` in namespace `kube-system` unless `input.actor.groups` contains `sre`, and approves `update_k8s_resource` outside `kube-system` when the actor is in `sre`.

Attachment is separate: Security → Policies, optionally limited to selected tool names, or a binding policy. The binding example uses a different package, `plrl.binding`, with `startswith(input.workbench.name, "demo-")`. A true result attaches the enforcement policy; a false result removes an attachment that binding previously managed. Terraform types are `WORKBENCH` for the guardrail and `BINDING` for the selector.

**Verdict:** VERIFIED

**Details:**

C12 matches this page. The workbench admission package is `plrl.wb.admission` (prose and the example `package` line). Evaluation input is actor, tool name, and arguments. Outcomes are deny, or automatic approval when the tool supports approval. The “cannot make an unavailable tool accessible or grant permissions the actor does not already have” sentence is verbatim.

Facts that sit beside the claim, without contradicting it:

- `approve` applies to “a tool that supports approval.” A policy does not invent an approval gate for a tool that has none. No matching decision leaves the normal authorization and approval path in place. Denial takes precedence.
- `plrl.binding` is a second package. It chooses which workbenches receive the policy. It is not the admission evaluator.
- Policies attach to workbenches. This page does not apply `plrl.wb.admission` to Flow MCP calls. Flow MCP governance remains the ref-12 list (audit, confirm, JWT, bindings).
- Argument fields are tool-specific. The example uses exact names `delete_k8s_resource` and `update_k8s_resource` plus `input.tool.namespace`. The page says to copy names and shapes from a real simulator evaluation.
- The policy narrows or short-circuits approval. It does not grant Kubernetes (or any other) permissions the actor lacks. That matches ref-07’s RBAC federation statement: cluster RBAC still applies to the user running the job.

**Impact:** A coding agent with the same MCP servers does not, on these pages, get this admission layer. Plural evaluates workbench tool calls in `plrl.wb.admission` with the Console actor (including groups), the tool name, and the argument object, and can deny or auto-approve. The documented guarantee is negative: the policy cannot turn on a tool that is not available and cannot give the actor permissions they do not already have. Auto-approve only short-circuits tools that already support approval. Flow MCP confirmation (ref-12) is a different switch, and the sample there sets it to false.

---

## Batch Summary

- **Verified:** 1 (ref-13 / C12)
- **Verified with caveats:** 3 (ref-07 / C9, ref-11 / C10, ref-12 / C11)
- **Misleading:** 0
- **Unsupported:** 0
- **Unverifiable:** 0
- **Problematic:** 0

**Claim counts:** C9 caveats, C10 caveats, C11 caveats, C12 verified.

**Key pattern:** The docs describe three different mechanisms, and C9–C12 keep them straight enough to verify.

1. Workbench natives (Services, Stacks, Kubernetes, pod logs, Trivy, metrics, log aggregation) are runtime toggles. They need no separate tool credential form. Metrics and logs still use already-configured observability backends. Kubernetes is managed clusters, and the page says the call runs as the Console user under cluster RBAC. Enabling a capability does not widen that access.
2. External tools, including MCP, are global configurations attached to a workbench. Flow MCP adds audit logging, optional confirmation, Plural JWT (`authentication.plural: true`), and a write binding for who may bind the server. The only manifest sets `confirm: false`. That is governance on MCP, not a replacement.
3. Flow context (registered objects, logs from pods in the flow, vector-indexed incoming PRs, incident knowledge graph) is pre-baked and separate from both tool catalogs. The governance sentence is about not fetching data the developer should not see. The page does not specify the enforcer. Workbench Rego (`plrl.wb.admission`) is the specified enforcer for workbench tool calls, and it cannot grant access the actor lacks.

None of these pages mention Claude Code, Codex, or Cursor. The documented delta versus attaching the same MCP servers to a generic coding agent is the native Plural data plane, flow-scoped retrieval, org-level tool attachment, Flow MCP audit/confirm/JWT/bindings, and workbench Rego that can deny or auto-approve without widening RBAC.

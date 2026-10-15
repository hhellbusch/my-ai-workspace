---
review:
  status: unreviewed
  notes: "Drafted 2026-10-13. Revised 2026-10-14 with the public OpenShift and upstream Kubernetes agent pieces that were re-checked that day. Author has not re-read it."
---

# Plural Beside the Red Hat Fleet

> **Audience:** Platform engineers who run OpenShift with Advanced Cluster Management and Argo CD, and who are looking at an infrastructure agent such as Plural.
> **Purpose:** State what Plural is, from its own docs and public history, and how that product lines up with ACM, Argo CD, Ansible Automation Platform, OpenShift's public agent pieces, and the Kubernetes projects those pieces sit on.

---

## What Plural is

[Plural](https://www.plural.sh/) is a Kubernetes control plane with an agent layer on top.
A management cluster oversees workload clusters.
The console covers continuous delivery, Terraform stacks, and a dashboard.
Workbenches are the agent product: a saved configuration of a system prompt, instruction files Plural calls skills, attached tools, and a trigger.

A job is one run of that configuration.
It can start from the UI, the API, a cron schedule, a webhook (an alert or a ticket), or a Slack mention.
The job runs in a pod on the management cluster.
When it finishes it can leave a summary, a dashboard, follow-up todos, or a pull request.

Native tools read objects Plural already manages: service health, stack runs, Kubernetes list and describe on managed clusters, pod logs, Trivy findings on Plural-managed services, and metrics or logs from backends Plural is wired to.
Kubernetes calls impersonate the console user, by email and groups, and the cluster's own RBAC applies.
External tools are configured once and attached per workbench: Datadog, Prometheus, Loki, Elasticsearch, GitHub, GitLab, Slack, Jira, Linear, HTTP, and any MCP server.
Cloud data is queried through stored cloud credentials.

Skills are markdown the agent reads at the start of a job.
Plural ships a library of operations skills.
A team can also point at files in a Git repository Plural already has registered.
That is the same role as an Agent Skill file: know-how in the prompt.
Reaching a system is still a tool or an MCP server.

The coding step is optional.
Documented runtimes are Claude, OpenCode, and Gemini.
Analyze mode reads repositories and reports.
Write mode can commit and open a pull request against an allow-list of repos.
Babysitting, off unless enabled, watches review comments and CI and pushes further commits until the pull request merges or the session times out.
The examples in the docs pair that with operational context: a crashing workload to a GitOps pull request, Terraform drift to an infrastructure pull request, a CVE on a Plural-managed service to a dependency bump.

Workbench policies are Rego.
They see the actor, the tool name, and the arguments.
A policy can deny a call or auto-approve one that would otherwise wait.
The docs state that a policy cannot grant access the actor does not already have.
Flow MCP adds an audit log, an optional confirmation step, a Plural JWT to the MCP server, and group bindings for who may attach a server.

Pro pricing on the public page is $450 a month for the first cluster and $250 a month for each additional cluster, capped at 10, on shared Plural Cloud.
A larger estate is an enterprise conversation: dedicated or on-premises hosting, price based on cluster count and support.
Model usage is bring-your-own and sits on top of that fee.

---

## Where it came from

Plural predates the current wave of coding agents.
VentureBeat reported a public launch on 15 March 2022, a $6 million seed, and a product that deployed other open-source applications (Airflow, Grafana, Airbyte, and others) onto the customer's own Kubernetes.
Sam Weaver described the same product on Hacker News that September.
The console license copyright is 2021.
GitHub activity on the organization goes back to 2019–2020.
Accounts of the founding year differ between 2020 and 2021.

A January 2025 post on Plural's blog says the marketplace became an operations problem and the product turned into a fleet manager.
By a March 2025 TechCrunch interview, the public description included an AI agent associated with each cluster, self-hosted, on a GitOps model.
Workbenches, the configurable DevOps-agent surface, were announced on 15 April 2026.

The license is split.
The CLI and the documentation repository are MIT.
The console license says compiled binaries produced by Plural Labs are MIT.
Source is AGPL-3.0, or a commercial license, or a licensed installation on app.plural.sh.
Admin tools and configuration under `plural/` are Apache-2.0.
The license text says Plural will not enforce the AGPL copyleft when a caller only uses those admin tools and does not modify the platform.

---

## ACM, OpenShift, and other Kubernetes

Red Hat Advanced Cluster Management, on an OpenShift hub, is the fleet record for clusters it manages.
For OpenShift it can create, upgrade, and destroy clusters, and it can import clusters that already exist.
That includes self-managed OpenShift and the managed services the support matrix lists, such as ROSA, Azure Red Hat OpenShift, and OpenShift Dedicated.
Which of those the hub itself upgrades depends on the ACM version.
The support matrix is the checklist. The datasheet separates full lifecycle for OpenShift from limited lifecycle for other Kubernetes.

ACM will also import Amazon EKS, Google GKE, Microsoft AKS, IBM Cloud Kubernetes Service, and other CNCF-conformant clusters.
On those, the published scope is inventory plus what imported clusters receive in general: policy, observability, and application lifecycle.
The cloud service keeps create, upgrade, and destroy.
An imported EKS cluster does not gain a `ClusterVersion`.
It gains a `ManagedCluster`, a klusterlet, and a target Argo CD and placements can select.

OpenShift on AWS, Azure, or GCP is a different object from EKS, AKS, or GKE in the same account.
Self-managed OpenShift on those clouds uses the OpenShift update path: a channel, `ClusterVersion`, and, when the hub owns the lifecycle, ClusterCurator or the equivalent.
ROSA, ARO, and OpenShift Dedicated keep a managed control plane.
ACM can still be the inventory and the policy plane.
The service's own upgrade path remains the one to confirm in the matrix before treating the hub as the upgrader.

Argo CD is the delivery controller for YAML in Git: platform charts, ApplicationSets, and the values that differ per cluster.
ACM policy is the mandate controller: OAuth, labels, pull secrets, and anything whose drift should show up as compliance rather than as an application sync.
Ansible Automation Platform sits at the edge, for work that is not a Kubernetes object: install hooks, a CMDB, DNS, bare metal, usually through ClusterCurator or PolicyAutomation.
One controller per kind of resource keeps that stack from fighting itself.
Plural fits when it follows that rule.

---

## Agents on the upgrade path

OpenShift's own agent skills live in [openshift/agentic-skills](https://github.com/openshift/agentic-skills).
The update advisor returns recommend, warn, block, or escalate.
The product-lifecycle skill checks platform and operator compatibility.
The troubleshoot skill diagnoses a live cluster with `oc` and metrics.
Those files are instructions and small tools for an agent that already talks to OpenShift.
They read the APIs the hub already uses.
They do not apply a cluster version by themselves.

Plural's coding agent is the same shape pointed at Plural's inventory.
A job can investigate and open a pull request.
The documented upgrade example on the launch post is a version field in Terraform and GitOps files for EKS, which is the class of change the cloud provider owns and ACM does not upgrade.
An OpenShift upgrade is a `ClusterVersion` change, an operator compatibility check, and often a managed-service API.
The OpenShift skills are written for that.
Plural's workbench is written for stacks and services Plural manages, plus whatever Git repository it is allowed to change.

Either one can advise and open the pull request.
The pull request belongs in the repository the existing controller already syncs, and the agent stops short of applying the change itself.

---

## Public agent pieces on OpenShift

OpenShift Lightspeed (`openshift/lightspeed-service`) is an assistant whose tools are the MCP servers listed in `olsconfig.yaml`.
The service README documents three ways to authenticate to those servers.
A header value that is a file path is a static token.
The value `kubernetes` injects the authenticated user's Kubernetes token, and only when the service's auth module is `k8s`.
The value `client` takes a token the caller sends on that request in the `MCP-HEADERS` header.

A [31 August 2026 developer article](https://developers.redhat.com/articles/2026/08/31/ai-powered-multicluster-management-querying-fleet-health-openshift-lightspeed) describes an ACM search MCP server, Technology Preview, installed from `stolostron/search-mcp-server`.
It answers questions about clusters the hub has imported.
The article's sample registers that server on Lightspeed with `type: kubernetes`, and the article text says that header uses the service account token.
The service README says the same placeholder injects the logged-in user's token.
This note does not reconcile the two.
The article also shows Lightspeed's tool-approval gate, and the sample sets `approvalType: never` for that read-only search.

`openshift/lightspeed-agentic-operator` is upstream code.
Its objects include an agent, a model provider, a proposal, and an approval.
The agent runs in [kubernetes-sigs/agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox).
Pull requests on the operator target OpenShift 5.0.
This reading found no GA product page for that operator.

`openshift/agentic-skills` is the instruction pack named above.
`openshift/openshift-mcp-server` is the cluster MCP server in the Lightspeed README's example.

Ansible Automation Platform 2.7 documents an automation intelligent assistant in [Deploy the automation intelligent assistant](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/extend-assembly_deploying_alia).
The assistant's MCP integration is a Technology Preview.
The page says Technology Preview features sit outside production support agreements and are not recommended for production.
Documented model hosts include OpenShift AI, RHEL AI, Red Hat AI Inference Server, OpenAI, and Azure OpenAI.
The page requires tool calling on the model.
It describes a chat in the platform UI, not an actor that changes a cluster version.

---

## The same shape on any Kubernetes

`kubernetes-sigs/agent-sandbox`, under SIG Apps, is the sandbox the OpenShift operator uses.
The [20 March 2026 Kubernetes blog](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox/) describes a `Sandbox` as one stateful pod with a stable identity, pause and resume, and isolation from a RuntimeClass such as gVisor or Kata.
Any cluster that can install the CRDs can run one.
The object runs a process.
Cluster upgrade is outside it.

`kubernetes-sigs/mcp-lifecycle-operator`, also SIG Apps, deploys an MCP server from an `MCPServer` object.
The GitHub README calls the API alpha (`v1alpha1`).
The project site calls it beta (`v1beta1`).
Treat the version as unsettled.

`containers/kubernetes-mcp-server` is a Go client of the Kubernetes API.
Core tools are on by default.
Helm, Tekton, and KubeVirt are optional toolsets.
`--read-only` is the published limit.
It follows whatever kubeconfig it is given, including more than one.

`GoogleCloudPlatform/kubectl-ai` turns a sentence into `kubectl` and `bash` on the machine that holds the kubeconfig.
It can be an MCP client or an MCP server.
The docs include a `--skip-permissions` flag.

[kagent](https://kagent.dev/) was accepted to the CNCF Sandbox on 22 May 2025.
An Agent is a Kubernetes object.
The repository names harnesses for its Go and Python ADKs, Codex, Claude, and a custom runtime.
Built-in MCP tools cover Kubernetes, Istio, Helm, Argo, Prometheus, Grafana, and Cilium.
The README says the project is in active development.

Plural's workbench docs describe a saved job: a prompt, skills, tools, and a trigger from the UI, the API, a clock, a webhook, or Slack, with an optional watch on the pull request until merge or timeout.
The projects in this section describe a sandbox, an MCP server, an API client, a CLI, and an agent object.

---

## A split that uses both

When clusters are enrolled in ACM and Argo CD, Plural is effective as an agent over a GitOps repository, not as a second manager of the same clusters.

| Concern | Owner | What an agent contributes |
|---|---|---|
| OpenShift version and operator compatibility | ACM for self-managed OpenShift; the managed service for ROSA, ARO, and Dedicated | Readiness and compatibility advice. A pull request or a curated change the hub or the service already knows how to apply |
| EKS, GKE, and AKS version and node pools | The cloud provider, declared in the existing cloud repository | A pull request in that repository |
| Platform and application YAML | Git, synced by Argo CD | Edits in the repository Argo CD already watches |
| Mandates and fleet compliance | ACM policy | A reading of compliance. ACM remains the policy engine |
| Work outside the Kubernetes API | Ansible Automation Platform | Unchanged. Hooks and job templates stay on the controller |
| Privilege for the call | The caller's existing identity: cluster RBAC, ACM's managed identity, or a short-lived checkout from a privileged-access system | A record of the call. The token is not a second long-lived admin credential |

Plural's Kubernetes impersonation matches the last row for clusters it manages: the API server sees the console user.
External tools are different.
Datadog, Slack, GitHub, and cloud connections are API keys or tokens stored on the tool and shared by the workbenches that attach it.
Bindings control who may attach the tool.
Rego can refuse a particular call.
The stored credential remains a standing secret, often broader than one person, which is why the policy layer exists.

A practical pairing:

- ACM holds `ManagedCluster` records, placements, and OpenShift lifecycle.
- Argo CD syncs the Git repository those clusters converge to.
- A coding agent, Plural's workbench or another agent using OpenShift skills, opens pull requests into that repository.
- Plural does not also import the cluster as a lifecycle object, and it does not hold credentials that can apply to the live API.
- Stacks that declare a cluster version, a node image, or an EKS, GKE, or AKS version stay in the repository that already owns them.

That uses Plural for what its workbench is built to do: gather operational context and propose a reviewable change.
It leaves reconciliation to the controller that already has the cluster enrolled.

---

## What this note did not verify

No Plural console, Lightspeed service, agentic operator, kagent, or kubectl-ai was installed for this reading.
The semantic graph, `aiProxy`, and multi-hour job behavior are as the Plural docs and the launch post describe them.
ACM's Upgrade cell for ROSA, ARO, and OpenShift Dedicated should be read on the support matrix for the hub version in use.
The January 2025 Plural post mixes the fleet-manager history with unrelated analogies; the 2022 launch and the later fleet positioning are corroborated by VentureBeat, Hacker News, and TechCrunch.
Homepage outcome percentages are vendor figures without a published method, so they are left out of the description above.
Lightspeed's README and the ACM search article disagree on whether the `kubernetes` MCP header is the user token or the service account token.
The MCP lifecycle operator's API level disagrees between its README and its project site.
OpenShift AI as a model host, the `rhoai-mcp` prototype, and the contents of an OKD 5.0 nightly are recorded in the landscape note and were not re-fetched for this revision.
No skill pack for an EKS, GKE, or AKS upgrade showed up in the projects named here.

---

## Sources

- [Plural](https://www.plural.sh/)
- [Introducing Plural Workbenches](https://www.plural.sh/blog/introducing-plural-workbenches-build-your-own-agents-for-devops/) (15 April 2026)
- [Plural pricing](https://www.plural.sh/pricing)
- [Plural AI](https://docs.plural.sh/plural-features/plural-ai)
- [Workbenches](https://docs.plural.sh/plural-features/workbenches), [configuration](https://docs.plural.sh/plural-features/workbenches/configuration), [tools](https://docs.plural.sh/plural-features/workbenches/tools), [coding agent](https://docs.plural.sh/plural-features/workbenches/coding-agent)
- [Workbench policies](https://docs.plural.sh/plural-features/policy-management/workbench-policies)
- [Plural Console license](https://github.com/pluralsh/console/blob/master/LICENSE)
- [VentureBeat, Plural launches](https://venturebeat.com/business/plural-launches-to-simplify-open-source-deployment-and-avoid-costly-cloud-fees/) (15 March 2022)
- [TechCrunch, Plural's platform](https://techcrunch.com/2025/03/25/plurals-platform-allows-enterprises-to-manage-their-kubernetes-clusters-in-one-place/) (25 March 2025)
- [Red Hat Advanced Cluster Management datasheet](https://www.redhat.com/en/resources/advanced-cluster-management-kubernetes-datasheet)
- [RHACM 2.15 support matrix](https://access.redhat.com/articles/7133095)
- [openshift/agentic-skills](https://github.com/openshift/agentic-skills)
- [openshift/lightspeed-service](https://github.com/openshift/lightspeed-service) (MCP server configuration and authentication)
- [AI-powered multicluster management](https://developers.redhat.com/articles/2026/08/31/ai-powered-multicluster-management-querying-fleet-health-openshift-lightspeed) (31 August 2026)
- [Deploy the automation intelligent assistant](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/extend-assembly_deploying_alia) (Ansible Automation Platform 2.7)
- [Running Agents on Kubernetes with Agent Sandbox](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox/) (20 March 2026)
- [kubernetes-sigs/agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox)
- [kubernetes-sigs/mcp-lifecycle-operator](https://github.com/kubernetes-sigs/mcp-lifecycle-operator)
- [containers/kubernetes-mcp-server](https://github.com/containers/kubernetes-mcp-server)
- [GoogleCloudPlatform/kubectl-ai](https://github.com/GoogleCloudPlatform/kubectl-ai)
- [kagent](https://github.com/kagent-dev/kagent), [CNCF project page](https://www.cncf.io/projects/kagent/) (Sandbox, accepted 22 May 2025)

---

## Related reading

- [Fleet Control Spectrum](../../devops/fleet-control-spectrum.md) — where authority sits between Argo CD and ACM
- [Greenfield fleet architecture](../../devops/rhacm/notes/greenfield-fleet-architecture.md) — ACM, GitOps, and Ansible as one controller per concern
- [LangChain vs. Behavioral Skills](frameworks-vs-behavior.md) — instruction files and runtime connectors are different layers
- [Agentic tooling landscape](../../research/redhat-agentic-tooling/landscape.md) — the working list behind the OpenShift and upstream sections, including items this note did not re-fetch

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

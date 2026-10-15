# Agentic tooling coming out of Red Hat and nearby upstream

Read 2026-10-14 from public blogs, product docs, and GitHub. Maturity words below are the publisher's, not a support conclusion.

## The operations agent, in pieces

| Piece | Where | What it is | Scope |
|---|---|---|---|
| Lightspeed service | `openshift/lightspeed-service` | Assistant on OpenShift. MCP servers listed in `olsconfig.yaml` are the only tools the agent gets. Auth to a server is a static token file, the logged-in user's Kubernetes token, or a token the client sends per request | The cluster it is configured for, plus whatever MCP you add |
| Agentic operator | `openshift/lightspeed-agentic-operator` | CRDs `Agent`, `LLMProvider`, `Proposal`, `ProposalApproval`, `ApprovalPolicy`. `oc agentic` creates and approves proposals. Runs the agent in a [kubernetes-sigs/agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) | Upstream, pull requests aimed at OpenShift 5.0. Not a GA product page |
| Sandbox | `openshift/lightspeed-agentic-sandbox` | FastAPI adapters for Claude, Gemini, and OpenAI. Skills mount at `LIGHTSPEED_SKILLS_DIR` | The process inside the sandbox |
| Skills image | `openshift/agentic-skills` | OpenShift update advice, operator lifecycle, cluster troubleshoot. Shipped as an image on OKD 5.0 nightlies | OpenShift, not EKS |
| Cluster MCP | `openshift/openshift-mcp-server` | Go client of the Kubernetes API, plus OpenShift toolsets. Default in the OpenShift guide is read-only core tools | Any cluster you point it at for generic resources. OpenShift toolsets stay OpenShift |
| ACM search MCP | Developer article, 31 Aug 2026 | Natural language to ACM search. Technology preview | Whatever ACM has imported and the search collector indexed |
| AAP MCP | [Red Hat blog](https://www.redhat.com/en/blog/it-automation-agentic-ai-introducing-mcp-server-red-hat-ansible-automation-platform), AAP 2.6.4 | Technology preview. An MCP client can query automation and, in read-write mode, launch it. RBAC of the platform still applies. Docs name Claude, Cursor, ChatGPT, VS Code as clients | Ansible Automation Platform, not the cluster API |
| Automation intelligent assistant | AAP 2.7, [Deploy the automation intelligent assistant](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/extend-assembly_deploying_alia) | Technology Preview MCP integration. The page says Technology Preview is outside production support and not recommended for production. Tool calling is required. Model hosts named there include OpenShift AI, RHEL AI, Red Hat AI Inference Server, OpenAI, and Azure OpenAI | The AAP UI |

Lightspeed's README lists three MCP auth modes. A file path in the header is a static token. The value `kubernetes` injects the authenticated user's token, and only when the auth module is `k8s`. The value `client` takes a token from the request's `MCP-HEADERS` header. The 31 August 2026 ACM search article uses `type: kubernetes` and says that header is the service account token. Those two sentences were not reconciled.

## Model host, not the agent

RamaLama (`containers/ramalama`) runs a model in a container, rootless, with a REST API. InstructLab is a model you can point Lightspeed at. RHEL AI and OpenShift AI are the supported places to serve one. OpenShift AI 3.5 documents tool-calling parameters passing through llm-d to vLLM. None of these decide which cluster to change.

`red-hat-data-services/rhoai-mcp` is a prototype (created 20 May 2026) that exposes OpenShift AI dashboard actions: workbenches, KServe, pipelines, fine-tuning. It is an agent in front of the data-science platform, not in front of ACM.

## Adjacent, not the fleet agent

- Konflux DevLake MCP (`konflux-ci/konflux-devlake-mcp`) answers questions about Konflux's CI database: incidents, deployments, pull-request retests. OIDC optional.
- A September 2026 developer article shows a Satellite MCP server deployed into `openshift-lightspeed` so the assistant can ask about hosts, CVEs, and packages. That is a pattern (put an MCP server next to Lightspeed), not a product name in the OpenShift payload.
- The Argo CD and ACM controllers are unchanged. The agentic operator proposes. Argo still syncs.

## Kubernetes in general

Same split, without an OpenShift requirement. Read 2026-10-14.

| Piece | Where | What it is | Any cluster? |
|---|---|---|---|
| Sandbox | [kubernetes-sigs/agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox), SIG Apps. [Kubernetes blog, 20 Mar 2026](https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox/) | `Sandbox` CRD: one stateful pod, stable identity, pause and resume. Isolation is a `RuntimeClass` (gVisor or Kata), not something the CRD invents. Extensions add a template, a warm pool, and a claim. The Lightspeed agentic operator already runs on this | Any cluster that can install the CRDs. It runs an agent process. It does not know what a cluster upgrade is |
| MCP hosting | [kubernetes-sigs/mcp-lifecycle-operator](https://github.com/kubernetes-sigs/mcp-lifecycle-operator), SIG Apps | `MCPServer` CRD deploys an MCP server image, service, and lifecycle. GitHub README says alpha `v1alpha1`; the project site says beta `v1beta1`. Treat the API as still moving | Any cluster. Hosting, not policy |
| API client | [containers/kubernetes-mcp-server](https://github.com/containers/kubernetes-mcp-server) | Go client of the Kubernetes API. Core tools are on by default; Helm, Tekton, KubeVirt, kcp, Kiali, and NetObserv are optional toolsets. `--read-only` is the published safeguard. `openshift/openshift-mcp-server` is the repository the Lightspeed README uses in its cluster example | Any kubeconfig, including several at once |
| CLI agent | [GoogleCloudPlatform/kubectl-ai](https://github.com/GoogleCloudPlatform/kubectl-ai) | Natural language to `kubectl` and `bash`, on the machine that holds the kubeconfig. MCP client since v0.0.12, and it can itself be an MCP server. Custom tools documented for Argo CD, GitHub, gcloud, and Kustomize. Models named include Gemini, OpenAI, Azure OpenAI, Bedrock, Grok, Ollama | Any cluster that kubeconfig reaches. A laptop tool. `--skip-permissions` is a documented flag |
| Agent framework | [kagent](https://kagent.dev/), CNCF Sandbox since 22 May 2025 ([cncf.io/projects/kagent](https://www.cncf.io/projects/kagent/)) | Agents as CRDs. Built-in MCP tools for Kubernetes, Istio, Helm, Argo, Prometheus, Grafana, and Cilium. Runtimes named in the repo: Go or Python ADK, Codex, Claude, or a custom harness. Agent Substrate snapshots idle agents instead of a pod per agent | Any cluster you install it on. CNCF Sandbox is the maturity label. The homepage's "production grade" is theirs |

`agent-sandbox` is the runtime the OpenShift agentic operator selects. `kubernetes-mcp-server` is a Go client of the same API the OpenShift MCP server talks to. kagent is an Agent object you install on a cluster, and its README names Codex as one harness. ACM remains the fleet record for imported clusters.

## What is not in this pass

No public scheduler, in the Red Hat pieces or in these Kubernetes projects, that starts an agent from Alertmanager or a cron and babysits a pull request until merge. No skill pack for EKS, GKE, or AKS upgrades. The ACM search path is the only fleet-wide read of imported clusters, and it is a technology preview.

## Sources

- https://github.com/openshift/lightspeed-service
- https://github.com/openshift/lightspeed-agentic-operator
- https://github.com/openshift/lightspeed-agentic-sandbox
- https://github.com/openshift/agentic-skills
- https://github.com/openshift/openshift-mcp-server
- https://github.com/kubernetes-sigs/agent-sandbox
- https://kubernetes.io/blog/2026/03/20/running-agents-on-kubernetes-with-agent-sandbox/
- https://github.com/kubernetes-sigs/mcp-lifecycle-operator
- https://mcp-lifecycle-operator.sigs.k8s.io/
- https://github.com/containers/kubernetes-mcp-server
- https://github.com/GoogleCloudPlatform/kubectl-ai
- https://kagent.dev/
- https://www.cncf.io/projects/kagent/
- https://github.com/kagent-dev/kagent
- https://www.redhat.com/en/blog/it-automation-agentic-ai-introducing-mcp-server-red-hat-ansible-automation-platform
- https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.7/extend-assembly_deploying_alia
- https://github.com/containers/ramalama
- https://github.com/red-hat-data-services/rhoai-mcp
- https://github.com/konflux-ci/konflux-devlake-mcp
- https://developers.redhat.com/articles/2026/09/22/integrate-red-hat-satellite-mcp-openshift-lightspeed
- https://developers.redhat.com/articles/2026/08/31/ai-powered-multicluster-management-querying-fleet-health-openshift-lightspeed

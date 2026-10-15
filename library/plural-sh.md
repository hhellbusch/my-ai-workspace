# Plural.sh

**Type:** Product (infrastructure agents)
**Author:** Plural
**URL:** https://www.plural.sh/
**Research:** [`research/plural-sh/`](../research/plural-sh/)
**Public note:** [Plural Beside the Red Hat Fleet](../docs/ai-engineering/plural-and-the-red-hat-fleet.md)
**Tags:** plural, infrastructure-agents, workbenches, mcp, skills, kubernetes, platform-engineering
**Added:** 2026-10-13
**Wing:** ai-engineering

---

## Why This Matters (personal)

Personal read on what Plural actually does, and how a workbench lines up with ACM, Argo CD, and the public OpenShift and Kubernetes agent pieces.
Cite the public note.
The working assessment in `research/plural-sh/assessment.md` is the candid read, and it is not that note.
Distinct from `plur.ai` (agent memory).

## Notable ideas

- A workbench is a saved job: prompt, markdown skills, tools, and a trigger (UI, API, cron, webhook, Slack). It runs in a pod. Documented coding runtimes are Claude, OpenCode, and Gemini.
- Native Kubernetes calls impersonate the console user. External tools are stored credentials. Rego on the call can deny or auto-approve. It cannot grant access the actor lacks.
- On a fleet already in ACM and Argo CD, the public note's split is: those controllers keep the objects, and an agent opens the pull request.
- OpenShift Lightspeed, the agentic operator, and SIG Apps `agent-sandbox` are the public agent pieces beside that. kagent (CNCF Sandbox) is an Agent object on any cluster, and its README names Codex as a harness. Maturity labels are the publisher's.

## Sources

- [Plural Beside the Red Hat Fleet](../docs/ai-engineering/plural-and-the-red-hat-fleet.md)
- [`research/plural-sh/`](../research/plural-sh/)
- [`research/redhat-agentic-tooling/landscape.md`](../research/redhat-agentic-tooling/landscape.md)

---
title: "Why AI Agents Break Zero Trust at the Last Mile"
speaker: IBM Technology
channel: IBM Technology
date: 2026
url: https://www.youtube.com/watch?v=SbrEk_tXZaE
wing: ai-engineering
tags: [ai-engineering, security, zero-trust, identity, agent-harness, enterprise, mcp, abac, vault]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# IBM Technology — Why AI Agents Break Zero Trust at the Last Mile

## Source

- **Speaker:** IBM Technology
- **URL:** https://www.youtube.com/watch?v=SbrEk_tXZaE
- **Duration:** 13:02
- **Transcript:** [cached](../research/ingest-queue/sources/why-ai-agents-break-zero-trust-at-the-last-mile.md)

---

## About

The "agentic last mile identity problem" — the security gap between an AI agent's reasoning layer and the legacy enterprise backends it must connect to. The agent side is new and well-designed; the backend side is old, credential-based, and was never built with agentic delegation in mind. That mismatch breaks zero trust.

---

## The last mile framing

Last mile = ISP analogy: you can build fast trunk lines, but getting high speed to old house infrastructure is the hard problem. For agents: the reasoning + orchestration layer is the trunk; the legacy enterprise systems are the old house infrastructure.

```
User → Chat/App → Agent (A1) → MCP Server → [Legacy systems / data]
                                              ↑
                                         "the last mile"
```

The left side is being actively designed for agents. The right side was built for application-to-application communication — not agent delegation.

---

## What gets lost at the last mile

When an agent connects to a legacy backend via API key or shared credentials:

| What's lost | Why it matters |
|---|---|
| **User identity** | The backend only sees the API key; the originating user is unknown |
| **Intent** | "Change this password" was the user's intent; the backend just sees an API call |
| **Context** | What environment, what agent chain, what was the user trying to do — all stripped |
| **Delegation chain** | The backend doesn't know an agent acted on behalf of a human |

Result: **zero trust breaks**. The backend grants access based on the credential alone, with no knowledge of who initiated the chain or why.

---

## The risks that follow

- **Unconstrained tool chaining:** Without context/intent checks, an agent can call API A, chain to API B, chain to API C — nothing stops it because the backend doesn't know it's in an agent loop
- **Rogue agent insertion:** An attacker can inject a rogue agent that presents a valid credential to an MCP server and connects to backend processes — the backend can't distinguish legitimate agent from attacker

---

## The fix: restore identity at the last mile

Three things to validate at the backend boundary:
1. **Identity** — who is the originating user?
2. **Context** — what environment, what agent chain?
3. **Delegation** — is this an agent acting on behalf of a human?

**Implementation approaches:**

- **ABAC + PBAC** (attribute-based / policy-based access control) on legacy systems — policies that evaluate user attributes, environment attributes, and intent before granting access
- **Vault as intermediary** — instead of agents connecting directly to backends with static credentials, all connections route through a vault that: validates claims (identity, delegation, context), applies policy, issues short-lived credentials, and provides an audit trail. The vault bridges the agentic world and the legacy world.

---

## Connections to this workspace

- The "last mile" framing maps to the broader harness problem: the LLM/agent side can be well-designed while the integration layer remains a security gap
- ABAC/PBAC + vault pattern is directly relevant to enterprise deployments of agentic systems (see OpenShift + OpenShift AI reference architecture in BACKLOG.md)
- The identity-loss problem is a concrete instance of **interface bleed** going in the other direction — not just contamination into the agent's context, but loss of human-origin context flowing out to downstream systems
- Relates to: [Tejas Kumar — Harnesses in AI](tejas-kumar-harnesses-in-ai.md) (harness design); [Ido Salomon — AgentCraft](ido-salomon-agentcraft-orchestration.md) (orchestration and agent chains)

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

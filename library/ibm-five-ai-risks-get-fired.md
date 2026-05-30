---
title: "Five AI Risks That Can Get You Fired—And How to Avoid Them"
speaker: IBM Technology
channel: IBM Technology
date: 2026
url: https://www.youtube.com/watch?v=1m55T8xST9s
wing: ai-engineering
tags: [ai-engineering, security, governance, shadow-ai, hallucination, prompt-injection, agentic-ai, enterprise]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# IBM Technology — Five AI Risks That Can Get You Fired

## Source

- **Speaker:** IBM Technology
- **URL:** https://www.youtube.com/watch?v=1m55T8xST9s
- **Duration:** 10:45
- **Transcript:** [cached](../research/ingest-queue/sources/five-ai-risks-that-can-get-you-firedand-how-to-avoid-them.md)

---

## About

Enterprise AI governance risk taxonomy from IBM. Five categories that have already ended careers and cost organizations millions. Most useful framing: "hallucination laundering" (named) and "zombie AI agents" (named). Complements the zero trust / last mile video from the same channel.

---

## The five risks

**1. Shadow AI** — unapproved tools in the workflow
- 1 in 5 organizations had a data breach caused by shadow AI (IBM Cost of a Data Breach report)
- Banning tools doesn't work — employees find workarounds, and then IT loses visibility entirely
- Fix: AI governance framework + clear approved tool policy + explicit data classification

**2. Data leakage** — pasting sensitive data into unvetted tools
- Proprietary code, customer records — once pasted into a third-party tool, it may train the next model version
- The governance fix for #1 addresses this too

**3. Hallucination laundering** — submitting unverified AI output as your own work
> "What started out as disposable AI slop is now presented as fact with that employee's credibility to back it up."
- Lawyers submitting fabricated case citations. Executives making major decisions on AI-generated content they never verified.
- "If the AI writes it and it turns out to be wrong, whose name is on the document?"

**4. Prompt injection** — overriding the AI's instructions via crafted inputs
- *Direct:* typing malicious prompts into a chatbot ("ignore all previous instructions")
- *Indirect (more dangerous):* malicious instructions hidden in documents, emails, or web pages that the agent retrieves as part of its context — nobody types anything suspicious; the attack is in the data
- Relevant to any RAG pipeline or agentic system that reads external content

**5. Unauthorized agentic AI** — shadow AI that acts, not just answers
- Agents that read/write databases, call APIs, execute code, send messages — autonomously, connected to internal systems
- **The zombie agent problem:** someone spins up an agent for a POC, project ends, but the agent is still running, still authenticated, still holding API keys everyone forgot about

---

## Connections to this workspace

- Companion to: [IBM — Zero trust at the last mile](ibm-ai-agents-break-zero-trust-last-mile.md) (security at the agent-to-backend boundary)
- **Hallucination laundering** is the enterprise name for the "fluency ≠ evidence" failure mode documented throughout the workspace (sparring-and-shoshin, peer deck)
- **Indirect prompt injection** is a concrete security manifestation of interface bleed — hostile context entering the agent via retrieved documents
- **Zombie agent** is a named pattern for the "unauthorized agentic AI" risk — relevant to the enterprise AI platform architecture backlog item

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Andrej Karpathy — From Vibe Coding to Agentic Engineering

## Source

- **Channel:** Sequoia Capital
- **URL:** https://www.youtube.com/watch?v=96jN2OCOfLs
- **Event:** Sequoia Capital interview (2026)
- **Duration:** 29:44
- **Published:** 2026
- **Transcript:** [cached](../research/ai-engineering-talks-apr-2026/sources/andrej-karpathy-from-vibe-coding-to-agentic-engineering.md)

## About the Speaker

Andrej Karpathy is a co-founder of OpenAI, former head of AI at Tesla (built Autopilot), and independent researcher known for making complex AI concepts accessible. He coined the term "vibe coding" and runs the Karpathy AI YouTube channel. His software 1.0/2.0/3.0 framework is widely referenced.

## Key Themes

- **Software 3.0 as a new computing paradigm** — Software 1.0: explicit code. Software 2.0: neural network weights trained on data. Software 3.0: the context window is the programming interface; the LLM is the interpreter. This is not just faster coding — it's a different substrate. The question changes from "what code do I write?" to "what text do I give to my agent?"
- **Vibe coding vs. agentic engineering** — Vibe coding raises the floor: everyone can build something. Agentic engineering preserves the quality bar. In professional software you're still responsible for security, reliability, and correctness — but you can go faster. Agentic engineering is the discipline of coordinating fallible, stochastic-but-powerful agents without sacrificing the quality bar.
- **Jagged intelligence and verifiability** — LLMs peak in domains that are (a) verifiable via RL and (b) prioritized by labs. Code and math are high. Commonsense physical reasoning (drive vs. walk to the car wash) is not. Capability profiles are jagged — not a general ramp upward. This jaggedness means humans need to stay in the loop and treat models as powerful tools, not general-purpose reasoners.
- **The "animals vs. ghosts" framing** — LLMs are not animal intelligences. They are statistical simulation circuits shaped by pre-training distributions and RL reward functions — not by evolution, embodiment, intrinsic motivation, or curiosity. Understanding what they are (and aren't) leads to better use: yelling at them doesn't work, but understanding which RL circuits they're in does.
- **Understanding as the non-outsourceable bottleneck** — "You can outsource your thinking but you can't outsource your understanding." The human directing agents must know what to build, why it's worth doing, and whether the agent's output is correct. Understanding cannot be delegated. Knowledge bases and structured learning tools help humans maintain understanding as AI handles execution.
- **Agent-native infrastructure is mostly unbuilt** — Everything currently deployed was designed for humans: documentation, deployment pipelines, DNS configuration, service integrations. The shift to agentic engineering requires rebuilding infrastructure as "sensors and actuators" that agents can operate directly, described to agents first.
- **Taste and judgment remain human** — Current models produce bloated, copy-pasted, brittle abstractions. Simplification, elegance, and right-sizing are outside the RL circuits. Humans remain in charge of the design, the spec, and the top-level categories. Agents fill in the blanks.

## Notable Ideas

> "Vibe coding is about raising the floor for everyone in terms of what they can do in software. Agentic engineering is about preserving the quality bar of what existed before in professional software."

> "You can outsource your thinking but you can't outsource your understanding."

> "Everything is still fundamentally written for humans and has to be moved around... What is the thing I should copy paste to my agent?" — Karpathy's pet peeve about docs still being human-oriented.

**The MenuGen dichotomy:** Karpathy built a vibe-coded app (MenuGen) to photograph restaurant menus and show pictures of each dish. Then he saw the Software 3.0 version: hand the photo to Gemini with a prompt, and get back a rendered image with pictures overlaid directly on the menu. His entire app is spurious — it was working in the old paradigm. The new paradigm is rawer; the neural network does more and the app in the middle often shouldn't exist.

**Hiring for agentic engineering:** Most hiring processes are still old-paradigm (puzzles, small problems). Karpathy's hypothetical: give a candidate a large project (Twitter clone), then have agents try to break it under adversarial conditions. Watch how they use the tooling to build something robust, not how they solve isolated puzzles.

**December 2025 as the inflection point:** Karpathy identifies late 2025 as when agentic coherent workflows "really started to actually work" — not incremental improvement but a qualitative shift in reliability and coherence. This matches others in the field noting the same window.

## Connections to This Workspace

### Software 3.0 reframes what "documentation" means

If the context window is the programming interface, then CLAUDE.md, `.cursorrules`, skills, and session frameworks are not just documentation — they are the program. This workspace's investment in structured context (shoshin, Zanshin, backlog discipline, review tracking) is Software 3.0 programming. The quality of the context determines the quality of the output.

### The "animals vs. ghosts" framing and shoshin

Karpathy's recommendation to build an accurate mental model of what LLMs are — as a prerequisite for using them well — is the epistemic equivalent of shoshin. Both say: before acting, verify the framing. The ghost framing (shaped by data and reward, not intrinsic motivation) corrects the intuitions that lead to "yelling at the agent" or anthropomorphizing failure modes.

### Understanding as the bottleneck matches the workspace's human-owned verification posture

Karpathy's "you can't outsource understanding" is a precise articulation of what `.cursorrules` calls "speed without mistaking fluency for truth." Both point to the same constraint: the human's depth of understanding is the actual ceiling, and tools that obscure that (by making everything feel fast and fluent) don't raise the ceiling, they just hide it.

### Jaggedness explains where the skill requirement concentrates

The jagged capability profile means an agentic engineer's most valuable skill is knowing which circuits they're in — where the model flies, where it struggles, and where it will silently produce confident wrong output. This workspace's practice of re-reading files rather than trusting in-context memory is a behavioral response to exactly this jaggedness.

### Agent-native infrastructure gap

The observation that everything must be rebuilt for agents — docs, deployment, service integrations — is the long-horizon version of what this workspace is doing at the micro level (making context legible to agents via CLAUDE.md, skills, structured planning). The macro version of this work is mostly unstarted across the industry.

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

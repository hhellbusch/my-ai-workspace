---
title: "All Code Is Slop (Except Mine)"
speaker: Lauren Tan (poteto)
channel: AI Engineer
date: 2026-11-14
url: https://www.youtube.com/watch?v=O_zcc6Xl12g
wing: ai-engineering
tags: [ai-engineering, slop, trust, lint, verification, formal-methods, software-factory, grok-bot, pstack]
review:
  status: unreviewed
  notes: "AI-generated summary from auto-captions, checked against the video description. Captions garble Grok Bot. Counts are the talk's claims, not independently checked."
---

# Lauren Tan — All Code Is Slop (Except Mine)

## Source

- **Speaker:** Lauren Tan (poteto / Potato), Grok Bot at SpaceXSI
- **Channel:** AI Engineer
- **URL:** https://www.youtube.com/watch?v=O_zcc6Xl12g
- **Published:** 2026-11-14
- **Duration:** 17:16
- **Links from the description:** [x.com/poteto](https://x.com/poteto), [github.com/poteto](https://github.com/poteto), [pstack](https://github.com/cursor/plugins/tree/main/pstack)
- **Transcript:** [cached](../research/lauren-tan-all-code-is-slop/sources/all-code-is-slop-except-mine.md)

---

## About

17-minute argument that agent volume is a trust problem, not a factory problem. Anyone can now be a "coding machine." The job is to hold or raise quality while the volume goes up. She spent about six months getting there, and says it should take less time with the pattern in hand.

Spend time on an inverse pyramid. The base is the codebase itself (API design, architecture, refactoring) and deterministic checks (lint, types, compilers, tests). Those two layers constrain what agents can do. Above them: runtime and formal verification, which catches bugs and checks whether the agent understood the intent. Prose — rules, skills, `AGENTS.md` — is the thin top, for judgment. A correction should become a deterministic check before it becomes another line of instructions, because the codebase is one of the largest inputs and agents copy whatever already looks established.

On the Grok Bot team she reports about 11,000 pull requests merged to production in a month, a stable client about once a day, 227 people with at least one PR in October, and a revert rate steady near 0.5%. She reports about 3,000 of those PRs as her own. Startup, typing, opening a chat, and switching chats got faster than at launch, on an Electron app. Review, when it happens, looks at videos, screenshots, diagrams, and proofs more than at the diff.

Caption noise: the description says Grok Bot. The captions also say Graph Bot, Grabot, Growth Bot, and Gulp bot. Dune (their Electron client framework), pstack, TLA+, Lean, and Bombadil stay consistent.

---

## Key ideas

### Correct in code, not in another paragraph

Agents copy workarounds, deprecated paths, and tech debt because those patterns are already in the input. She treats the codebase as a garden: constraints are the concrete the new growth has to follow. Weeds spread.

> "Whenever you're correcting your agent, think about how you can make that a deterministic check instead of adding another line to your rules or your agents.md because it's far more reproducible when it's in code."

> "Anything that requires nuance to use well often leads to slop."

Dune is "kind of like Next.js for Electron." `useEffect` is banned in product code and allowed only inside Dune APIs, so that review item is gone. Renderer and main-process code live in top-level directories named for those threads; a dependency-graph check and lint rules forbid imports between them, after Cursor agents imported main-thread code into the renderer and caused jank.

### Comments are an escape hatch

On Cursor, agents papered over an imperative-VS-Code vs declarative-React clash with `setTimeout`, `requestAnimationFrame`, and `requestIdleCallback`, then wrote comments justifying the timers. The timers spread, and GC from creating and destroying them made the app worse. Grok Bot bans about 99% of comments. They go stale, people do not read them, and they are not enforceable — a place to explain why the hard fix was skipped, or to freeze a one-off correction into a permanent rule. Lint errors now tell the agent to fix the root cause. Do that enough times and "there's nothing left to review," and agents merge most of their own PRs.

### Verification is where the tokens go

Runtime verification means the agent runs the app and uses the same tools a person would, including the Chrome DevTools protocol. A feature map is a user-facing sitemap so "the thingy in the left sidebar" is a shared name. Custom CLIs inside those skills get reused, which cuts tokens and is itself testable.

Formal checks are a layer, not a silver bullet. TLA+ model-checks major flows such as notifications across devices. Lean checks a custom virtualization library for flicker and jitter. Bombadil, a property-based UI tester, has already caught bugs. A `state-chart` skill in pstack (potato stack) draws the user-visible state machine next to the videos and screenshots.

She cites a tweet (captions only give the name Cindy): six months earlier, subtle bugs were landing because verification was missing; later, about 70% of daily tokens went to verification. Tan says her own usage matches. None of the techniques are new. They used to be too expensive to write and maintain. Agents cut that cost, which she calls a golden age of testing. Formal models also show whether the agent understood the product.

### Do not automate a sloppy inner loop

> "If your inner coding loop produces slop, then automating that loop just produces more slop and you need to throw more and more and more tokens at the problem."

Order of work: when you correct an agent, stop the new occurrences with a lint rule and clean up the old ones; make the verification story strong; only then build the factory. Those foundations are the prerequisite. The outer loop she shows is Grok Bot opening a Cursor project on each release, fuzzing the build like a user, and auto-merging the fix PRs — which is only sane because product changes are good by default.

---

## What she would skip

- Starting with the software factory. Volume on a weak inner loop is expensive slop.
- Prose as the enforcement mechanism. Rules and comments feel like they teach the next agent. They do not hold.
- Treating formal verification as the whole answer. Useful, still one layer in the environment.

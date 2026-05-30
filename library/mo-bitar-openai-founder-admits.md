---
title: "OpenAI founder admits AI isn't working"
speaker: Mo Bitar (on Karpathy)
channel: Mo Bitar
date: 2026
url: https://www.youtube.com/watch?v=ZugX7a99dLk
wing: ai-engineering
tags: [ai-engineering, karpathy, vibe-coding, spec-writing, rl-limits, heart-attack-code, jagged-intelligence]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# Mo Bitar — OpenAI founder admits AI isn't working

## Source

- **Speaker:** Mo Bitar (commentary on Karpathy interview)
- **URL:** https://www.youtube.com/watch?v=ZugX7a99dLk
- **Duration:** 8:03
- **Transcript:** [cached](../research/ingest-queue/sources/openai-founder-admits-ai-isnt-working.md)

---

## About

Mo Bitar's reaction to a conference interview with Andrej Karpathy. The video is primarily a close reading of Karpathy's contradictions — and one genuinely useful signal he gave: spec-writing as the new skill to practice.

---

## The Karpathy contradiction

In the same interview, Karpathy said:
1. "I stopped checking the output — the models have gotten so good, I don't need to correct them as much"
2. "When I actually look at the code, I get a little bit of a heart attack. It's bloated, lots of copy-paste, awkward brittle abstractions. It works but it's gross."
3. "The agent made an assumption that didn't make any sense [in my MenuGen app]. If I hadn't caught it, it would've been catastrophic."

Mo's reading: the people who've stopped checking the code are "riding on the fact that CEOs don't know" how bad the code actually is.

---

## Karpathy's RL explanation (the jagged intelligence mechanism)

> "If the task you're trying to do is not well represented in either the base data or the RL data, there is no force on this planet that can make that LLM solve this problem for you."

This is the mechanism behind jagged intelligence: capabilities are bounded by what RL can train against. Tasks not in the training distribution hit a hard wall — prompting won't fix it. Karpathy is honest enough to say this plainly while still calling it "very sophisticated autocomplete."

---

## Spec-writing as the new practice skill

Karpathy's proposal for updated hiring:
> "Give me a really big project and see someone implement it. The thing you practice now is writing specs."

If you can't specify the edge cases, the agent will choke. Tokens, session length, cookie expiration, rate limiting — if you haven't thought about them, they won't be in the spec. The agent doesn't tell you what you forgot.

Mo: "What there is good skill in is not giving something to Claude until it's ready."

---

## Connections to this workspace

- The "heart attack code" observation is a practitioner confirmation of the "fluency ≠ quality" claim in the peer deck — fluent, working, but gross
- Karpathy's RL mechanism explains the jagged intelligence slide: capability = RL coverage, not general intelligence
- Spec-writing skill parallels Dex Horthy's "do not outsource the thinking" — the spec is where human judgment lives
- Connects to: [Mo Bitar — Token Mania](mo-bitar-token-mania.md), [Mo Bitar — Ex-Google CEO](mo-bitar-ex-google-ceo-ai-shtshow.md), [Mo Bitar — Done with AGI](mo-bitar-done-agi-rant.md); [Hak — systems thinking](hak-systems-thinking-only-skill-left.md) (the spec is the theory)

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

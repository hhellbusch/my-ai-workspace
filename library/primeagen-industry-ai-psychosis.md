---
title: "Industry Wide AI Psychosis"
speaker: ThePrimeagen (reading Mitchell Hashimoto's tweet)
channel: ThePrimeagenHighlights
date: 2026
url: https://www.youtube.com/watch?v=zdXsGF1hiZk
wing: ai-engineering
tags: [ai-engineering, ai-psychosis, mttr-mtbf, systems-thinking, wisdom, architecture-decay, hashimoto]
review:
  status: unreviewed
  notes: "AI-generated summary. Needs read and sources-checked before citing."
---

# ThePrimeagen — Industry Wide AI Psychosis

## Source

- **Speaker:** ThePrimeagen (commentary on Mitchell Hashimoto and George Hotz)
- **URL:** https://www.youtube.com/watch?v=zdXsGF1hiZk
- **Duration:** 12:57
- **Transcript:** [cached](../research/ingest-queue/sources/industry-wide-ai-psychosis.md)

---

## About

ThePrimeagen reacts to Mitchell Hashimoto's (HashiCorp) tweet about "AI psychosis" and George Hotz's commentary. The video is a stream-of-consciousness reaction, but surfaces three sharp ideas: the MTTR/MTBF infrastructure analogy, the architecture decay pattern, and "typing is cheap, wisdom is expensive."

---

## The AI psychosis definition (Mitchell Hashimoto)

> "I strongly believe there are entire companies right now under heavy AI psychosis and it's possible to have irrational conversations about it with them."

The psychosis manifests as: MTTR-only mentality ("it's fine to ship bugs because agents will fix them so quickly that humans can't"). Hashimoto drew the parallel to the infrastructure world's MTBF vs. MTTR debate during the cloud transition — and Terraform's creator made that call.

---

## The infrastructure analogy

> "We learned in infrastructure that MTTR is great, but you can't yeet resilient systems entirely."

The AI version:
> "Systems can appear healthy by local metrics while globally becoming incomprehensible. Bug reports can go down while latent risk explodes. Test coverage can rise while systematic understanding falls. Changes happen so fast that nobody notices the underlying architecture decay."

This is the local-metric / global-health problem. A codebase can score 100% test coverage, declining bug reports, and fast-shipped features — while the underlying architecture degrades in ways no metric captures.

---

## The mature codebase fallacy

People seeing AI work "so well" are often working in codebases with 10 years of accumulated context. The AI has massive amounts of correct patterns to learn from. That is not an indicator for new greenfield projects.

> "It used to only cost a little bit [when you made a bad decision], because you'd be like, 'Okay, I think this is the right way to go. Let's start going.' And then within 1 month, you're like, 'Dude, we produced like 30,000 lines of code and it's not good.' Now, it's like, 'Okay, what we produced is 500,000 lines of code and it's an absolute disaster.'"

AI accelerates output velocity. Bad decisions compound faster.

---

## "Typing is cheap. Wisdom is expensive."

> "Coding is roughly 20% of our time as software engineers. Typing is cheap. Wisdom is expensive."

The corollary to Hak's "systems thinking is the only skill left" — if AI takes over the cheap part (typing), the expensive part (judgment, design, architecture) becomes the whole job.

---

## The weird AI-identity relationship

Prime's observation: people have a personal relationship with AI. Criticizing the tool feels like criticizing them personally. This makes it nearly impossible to have grounded conversations about AI limitations in some teams.

---

## Connections to this workspace

- "AI psychosis" was mentioned by Mitchell Hashimoto, referenced by [Mo Bitar — Ex-Google CEO](mo-bitar-ex-google-ceo-ai-shtshow.md) — this video is the fuller discussion of the concept
- Architecture decay invisible to local metrics connects to the harness design principle: design for observation, not just output
- "Typing is cheap, wisdom is expensive" connects directly to [Hak — systems thinking](hak-systems-thinking-only-skill-left.md) and the conductor/orchestra framing
- The MTTR/MTBF analogy is a useful historical parallel for engineering conversations about AI over-adoption

---

*This document was created with AI assistance and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

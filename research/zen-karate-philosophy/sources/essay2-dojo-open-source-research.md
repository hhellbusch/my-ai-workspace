# Research: The Dojo, Open Source, and Ways of Working (Essay 2)

Targeted research for Essay 2 — agile dojo movement, open source etiquette formalization, code kata origins, and the senpai/kohai dynamic in contributor communities.

## 1. The Agile Dojo Movement

### Target's Dojo Program

- **Source:** [Enter the Dojo — Scrum Alliance](https://resources.scrumalliance.org/Article/enter-the-dojo) + [Target Tech Blog](http://target.github.io/devops/the-dojo)
- **Launched:** Spring 2015, Minneapolis North Campus
- **Scale:** Started with 3 teams; grew to 18 teams in training simultaneously (12 at main campus, 3 downtown, 3 Bangalore). 70+ teams graduated. Booked out 6 months.
- **Structure:** Six-week immersive residency. Teams bring their real backlog — not training exercises. Two sprints per week, demos on Mondays and Wednesdays. Coaches embed with teams full-time.
- **The name is intentional:** "We say it's a place where you can learn to practice a master craft, like Mr. Miyagi in the Karate Kid" (Brent Nelson, Operations Analyst). "Hyper sprint" structure builds "muscle memories" over 12 sprints in 6 weeks.
- **Four measures:** Value, speed, quality, and happiness — balanced against each other. "Is value going up as well as speed, or is quality going down as speed goes up?"
- **Practice + Challenge:** Permanent "Practice" teams serve as reservoirs of expertise. "Challenge" teams come through for their 6-week residency and can draw on Practice teams for roadblocks. "A holistic sharing environment."
- **Management included:** Product owners and managers train alongside engineers. "We want to make sure they're not becoming roadblocks by accident."
- **Cultural engine:** Originally a support structure for agile transformation; became "an engine powering change" and "accelerating the cultural transformation of the organization."
- **Context:** Part of Target's shift from project-based (800 concurrent projects) to product-based (80 products) management. Also driven by bringing outsourced work in-house.

**Essay connection:** Target explicitly borrowed the dojo metaphor and some of its structure (immersive practice, muscle memory, master/apprentice coaching). The four measures (especially "happiness") and the inclusion of management echo the Full Cup essay's argument about organizational investment. The "Practice teams as reservoirs" mirrors senpai/kohai dynamics. The real question: did they borrow the philosophy or just the vocabulary?

### Ford Motor Company

- **Source:** [Google Cloud Blog — DevOps Award 2022](https://cloud.google.com/blog/products/devops-sre/devops-awards-2022-winner-ford-motor-company) + [CIO.com](https://cio.com/article/242909/ford-draws-on-pivotal-to-reshape-developer-culture.html) + [Red Hat Blog](https://in.redhat.com/en/blog/revolutionizing-learning-how-fords-kubernetes-community-sparks-technological-innovation)
- **Timeline:** Cloud-native transformation began 2016. Won Google Cloud DevOps Award 2022.
- **Key detail:** Ford drew explicitly on Pivotal Labs to reshape developer culture. Internal Kubernetes user group with 200+ developers focused on community-driven learning.
- **Structure:** Voluntary community. Eliminates hierarchical barriers — junior developers share insights with senior leadership. Flexible hybrid sessions. All recorded as living knowledge base.
- **Tech stack:** OpenShift, Tekton, ArgoCD, Terraform — significant overlap with this workspace's DevOps examples.

**Essay connection:** Ford's community model is closer to organic dojo culture than Target's structured program. The "eliminates hierarchical barriers" principle maps directly to the dojo's equal-on-the-floor philosophy. Worth exploring whether the community was explicitly modeled on dojo principles or arrived there independently.

### Pivotal Labs (now Tanzu Labs)

- **Source:** [SlideShare — CF Dojo Black Belt](https://www.slideshare.net/slideshow/cf-dojo-blackbeltv05/36796325) + [Labs Practices Site](https://labspractices.com/)
- **Structure:** "Engineering Dojo" — 7-8 week immersive residency at Pivotal offices. Participants pair-program with Pivotal engineers on real codebases.
- **Pair programming as core:** Driver/navigator style. Not optional — it's the default working mode. Prevents knowledge silos, enforces collective code ownership.
- **XP/Lean foundation:** Extreme Programming, Lean, User-Centered Design. "Build the right thing the first time."
- **Influence:** Ford explicitly drew on Pivotal's model. Many enterprise "dojo" programs trace back to Pivotal's approach.

**Essay connection:** Pivotal is arguably the origin point of the corporate "engineering dojo" movement. Their pair programming emphasis is structurally similar to kumite (sparring) — two practitioners working together, each pushing the other. The question: Pivotal used the dojo metaphor instrumentally (immersive training = better engineers = better products). Did the philosophy transfer, or just the form?

## 2. Code Kata Origins — Dave Thomas

- **Source:** [CodeKata: How It Started](http://codekata.com/kata/codekata-how-it-started/) + [Wikipedia](https://en.wikipedia.org/wiki/Dave_Thomas_(programmer))
- **Origin story:** Thomas was at his son Zachary's karate lesson. Had 45 spare minutes. Spent them playing with bit-counting algorithms — not because he needed the performance, but because he wanted to explore. Realized afterward that this was a practice session.
- **Key insight:** "What made this a practice session? I had some time without interruptions. I had a simple thing I wanted to try, and I tried it many times. I looked for feedback each time so I could work to improve. There was no pressure: the code was effectively throwaway. It was fun."
- **The prescription:** Two things needed: (1) "Take the pressure off every now and then. Provide a temporal oasis where it's OK not to worry about some approaching deadline." (2) "Help folks learn how to play with code: how to make mistakes, how to improvise, how to reflect, and how to measure."
- **Philosophy:** "The point is not reaching a correct answer, but rather the learning that occurs during practice." Directly parallels the martial arts kata principle: the form trains the practitioner through execution.
- **Context:** Thomas co-authored *The Pragmatic Programmer*, coined "DRY," was an original signatory of the Agile Manifesto.

**Essay connection:** Thomas's origin story is perfect — he was literally sitting in a karate dojo when the idea crystallized. His "temporal oasis" maps directly to the Full Cup's argument about cutting off the tap to create learning space. His observation that "if the pressure was on... the practice would never have taken place" is the essay's thesis in miniature: the full cup prevents practice. The code kata concept borrowed the martial arts term *and* the philosophy, making it a genuine transfer rather than surface appropriation.

## 3. Architectural Kata — Ted Neward

- **Source:** [Ted Neward's Blog](http://blogs.newardassociates.com/blog/2010/architectural-katas.html) + [GitHub](https://github.com/tedneward/ArchKatas) + [architecturalkatas.com](http://architecturalkatas.com/)
- **The problem:** Architects only get to architect a handful of times in their career. Catch-22: need experience to be hired, need to be hired to get experience.
- **Structure:** Groups receive a vague problem statement, have 30 minutes to formulate an architectural vision, then present and defend it against questions. Deliberately constrained: you can't assume hiring/firing authority, any technology is acceptable if justified, must ask clarifying questions.
- **Foundation:** Based on Frederick Brooks's *The Design of Design*: "The only way to get great designers is to get them to design."
- **Community:** Open-source kata collection on GitHub. Welcomes contributions.

**Essay connection:** Extends the kata concept from individual code exercises to collaborative architectural thinking. The time constraint and defense requirement add a kumite (sparring) element. The "vague problem statement" forces the kind of clarifying-question discipline that's central to engineering practice. Less directly connected to dojo philosophy than Thomas's code kata, but demonstrates how the martial arts vocabulary propagated through layers of abstraction.

## 4. Open Source Etiquette Formalization

### Contributor Covenant

- **Source:** [contributor-covenant.org](https://www.contributor-covenant.org/) + [Wikipedia](https://en.wikipedia.org/wiki/Contributor_Covenant)
- **Created:** 2014 by Coraline Ada Ehmke
- **Motivation:** Response to reports of sexualized language, assaults at events, and lack of governance in open source communities. Specifically designed to reduce harassment of underrepresented developers.
- **Adoption:** Claimed adoption by 100,000+ projects. 9 of 10 largest open source projects (Linux, Creative Commons, Apple, Microsoft, WordPress, IBM). GitHub added streamlined adoption in 2016. Folded into Organization for Ethical Source in 2021.
- **Reception:** Sparked significant debate. Diverse contributors saw it as necessary; traditionalists interpreted it as a threat to free speech. Some contributors left projects over its inclusion.

**Essay connection:** The Contributor Covenant is the formalization of what had been informal community norms — the written-down version of "how we treat each other in this space." In dojo terms, it's the dojo kun (rules of the training hall) made explicit. The controversy mirrors a tension in the essay: when you codify culture, some people experience it as protection and others as constraint. The dojo's bow at the door serves a similar function — it signals "in this space, certain behaviors are expected" — but it's a ritual, not a policy document. The essay could explore whether the ritual form or the policy form is more effective at actually shaping behavior.

### Mentorship and Code Review as Senpai/Kohai

- **Source:** [GitHub Blog — Rethinking Open Source Mentorship in the AI Era](https://github.blog/open-source/maintainers/rethinking-open-source-mentorship-in-the-ai-era/)
- **Key finding:** Pull request volume up 23% year-over-year (45M PRs merged monthly in 2025), but maintainer hours haven't increased. Projects closing contributions or shutting down programs due to unmanageable inflow.
- **AI complication:** AI-generated contributions look plausible but don't indicate genuine codebase investment. Makes it harder for maintainers to identify promising contributors worth mentoring.
- **The mentorship multiplier:** Mentored contributors go on to mentor others. But this requires intentional investment — "3 Cs" framework for strategic mentorship at scale.
- **Code review as mentorship:** Reviews spread domain knowledge, enforce consistency, build quality culture, and create searchable knowledge bases. Reviewed code has 20-30% fewer defects.

**Essay connection:** The senpai/kohai dynamic is alive in open source even without the Japanese terminology. Maintainers mentor contributors through PR review; experienced contributors graduate to reviewing others' work. But the AI era is disrupting this: AI can generate the *form* of a good contribution without the developmental practice of making it. This directly parallels the essay's kata argument — the output (a clean PR) and the training (learning the codebase through struggle) are inseparable, and AI that generates the output without the struggle cuts the developmental loop. The maintainer-overload problem is the "full cup" applied to open source: maintainers don't have the bandwidth to mentor because the volume of inbound work fills their capacity.

## Summary: Evidence Gaps Remaining

- **Direct testimony from dojo participants:** The Target article has organizational perspective but limited individual voices. What did engineers who went through the dojo actually experience? Did the "muscle memory" metaphor hold?
- **Long-term outcomes:** Did Target's dojo graduates sustain the practices after returning to their teams? The article is from ~2017; what happened over the next 8 years?
- **Dojo programs that failed:** Survivorship bias — these are the success stories. Where did the dojo metaphor get applied and not work? What went wrong?
- **Japanese organizations' actual use of senpai/kohai:** The MDPI paper on informal structure in Japanese organizations could provide the real foundation, but it's behind a paywall.
- **Dave Thomas's explicit martial arts connection:** Beyond the origin story, did Thomas ever write more about the philosophical parallels between code kata and martial arts kata?

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

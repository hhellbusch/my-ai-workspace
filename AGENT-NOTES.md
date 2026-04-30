# Agent Notes — Lab README Generation

Decisions, ambiguities, and assumptions made while generating the two student lab READMEs.

---

## Decisions the Spec Did Not Cover

**Reference the participant guide vs. duplicate its steps.** Both labs have complete participant guides (LAB-GUIDE.md, LAB-OVERVIEW.md). Duplicating steps would create two places to maintain the same content. The READMEs orient and link instead, so they stay stable as the guides evolve.

**What "step-by-step" means in a README.** The spec said "how to get started (step-by-step)." A full walkthrough already exists in the participant guides. I interpreted this as the minimum steps to reach the starting state — clone, verify the reference app, open the guide — not a second copy of the lab itself.

**Whether to include a troubleshooting section.** Both participant guides already have troubleshooting sections. Omitted from the READMEs to avoid duplication.

**Whether to surface the ArgoCD version requirement.** The lab-argocd-sync instructor guide calls out "ArgoCD 2.6 or later" as a hard dependency for the multiple-sources feature. I included it in the student README because it is something a participant or their cluster admin needs to know before starting, not just an instructor concern.

**Whether to update labs/README.md.** That file currently links to INSTRUCTOR-GUIDE.md files, not student READMEs. Adding links to the new READMEs would be a reasonable cross-link, but the spec scoped this to creating the README files themselves. Left the labs/README.md untouched.

---

## What Was Ambiguous

**Which writing conventions apply.** STYLE.md is written for `docs/` essays — with blockquotes, horizontal rules, essay front matter, and AI disclosure footers. These files live in `devops/`, not `docs/`, so that structure does not fit. I followed the general CLAUDE.md brevity principle and the `.cursorrules` README pattern (prerequisites, steps, expected outcome) instead.

**Whether the argocd-sync lab requires the GitOps intro lab.** The instructor guide frames it as a follow-on. The participant guide says "helpful background but not required." I matched the participant guide's framing and made the setup step self-contained in the description.

**"Step-by-step"** — see the decision above. The phrase implies a walkthrough, but the participant guides already provide that. Treating it as "steps to start" resolved the tension without duplicating content.

---

## Audience and Tone Assumptions

**Audience is participants, not instructors.** Instructors have their own guide. The README is the first file a participant sees — it should orient quickly and hand off to the participant guide.

**Participants in lab-gitops arrive with no ArgoCD experience.** The instructor guide confirms this (the session opens with "what is GitOps?"). The README says so explicitly so participants know they are not expected to know ArgoCD.

**Tone is direct and factual.** STYLE.md defaults to practitioner voice — not prescriptive, not tutorial. For a student-facing lab README this means stating what's needed and what to do without hedging or hand-holding. "No ArgoCD experience required" rather than "don't worry if you've never used ArgoCD before."

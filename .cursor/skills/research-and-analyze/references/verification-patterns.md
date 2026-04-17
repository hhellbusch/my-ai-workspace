# Verification Patterns

Common claim types and how to check them against sources.

<numeric_claims>
## Numeric Claims (Cost, Performance, Percentages)

These are the highest-risk claims — specific numbers carry authority but are easy to misrepresent.

**Check for:**
- Is the number actually in the source? (not inferred or rounded)
- What conditions does the source attach? ("up to", "under specific workload", "assuming full utilization")
- Is the comparison fair? (apples-to-apples or apples-to-oranges)
- What time horizon? (5-year amortization vs. 1-year)
- What baseline? (on-demand vs. reserved vs. spot pricing)
- Are "up to" figures presented as typical?

**Red flags:**
- Source says "up to 18x" under specific conditions, article says "18x cost advantage"
- Source compares against frontier API, article implies comparison against equivalent infrastructure
- Breakeven calculated against on-demand pricing when enterprises use reserved instances
- Numbers from vendor marketing materials presented as independent analysis
</numeric_claims>

<maturity_claims>
## Maturity and Readiness Claims

Articles often present features as production-ready when sources describe them as preview or experimental.

**Check for:**
- Does the source mark features as GA, Tech Preview, Developer Preview, Alpha, or Beta?
- Is there a support statement? ("not covered by Red Hat support agreements")
- Are there known limitations listed that the article omits?
- Is the feature on a "roadmap" vs. "available now"?
- What version introduced it? Is that version widely deployed?

**Red flags:**
- Official docs say "Technology Preview" but article treats feature as production-ready
- GitHub repo shows alpha version numbers (v0.x) but article presents as mature
- Feature described in a Red Hat "Emerging Technologies" blog (experimental) vs. official product docs (supported)
</maturity_claims>

<architecture_claims>
## Architecture and Implementation Claims

These tend to be the most reliable category — architecture is factual and well-documented.

**Check for:**
- Does the described stack match official documentation?
- Are component names and versions correct?
- Is the dependency chain accurate? (A requires B which requires C)
- Are configuration examples syntactically valid?

**Typical confidence:** High — these are either right or wrong, and official docs are the authority.
</architecture_claims>

<strategic_claims>
## Strategic and Qualitative Claims

Hardest to verify because they express opinions, positioning, or predictions.

**Check for:**
- Is the framing consistent with the source's intent?
- Does the source support the specific argument being made, or just the general topic?
- Is vendor positioning presented as independent analysis?
- Are competitive comparisons fair?

**Red flags:**
- Red Hat blog posts cited as independent validation of Red Hat products
- Vendor whitepapers treated as objective analysis
- Industry trends described as certainties
</strategic_claims>

<source_quality>
## Source Quality Assessment

Not all sources carry equal weight.

**Tier 1 — Highest confidence:**
- Official product documentation (docs.redhat.com, docs.nvidia.com)
- Peer-reviewed papers (arXiv with citations, IEEE, ACM)
- Standards body publications (CNCF, Kubernetes SIGs)

**Tier 2 — Good confidence:**
- Official vendor blogs by named engineers/architects
- Established tech journalism (The New Stack, InfoQ, LWN)
- Community blogs with working examples and YAML

**Tier 3 — Moderate confidence:**
- Vendor marketing materials and whitepapers
- Medium posts and personal blogs (check author credentials)
- Conference talks and slide decks

**Tier 4 — Low confidence:**
- SEO-optimized comparison sites
- Unnamed or AI-generated content
- Paywalled content you can't read
- Sources that are no longer accessible
</source_quality>

<synthesis_patterns>
## Patterns to Watch For in Synthesis

When reviewing findings across all batches, look for these systemic patterns:

- **Cherry-picking**: Consistently selecting the most favorable number from each source
- **Context stripping**: Omitting conditions, caveats, or alternative scenarios
- **Maturity inflation**: Treating preview features as production-ready across the board
- **Circular citation**: Article A cites Article B which cites Article A (or a common vendor source)
- **Advocacy posture**: Every topic area presented in the most favorable light
- **AI-generated style**: Uniform sentence structure, no personal experience, generic transitions
</synthesis_patterns>

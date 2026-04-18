<overview>
Prompt patterns for adversarial review of research, plan, or other outputs. Spar prompts consume existing artifacts and produce structured counterarguments that downstream prompts must address.

The spar stage slots between research and plan in a chain:
```
research -> spar -> plan -> do
```
The plan receives both the research and the spar output, forcing it to address counterarguments rather than building only on affirming research.
</overview>

<prompt_template>
```xml
<spar_objective>
Challenge {topic}-{target_purpose} with adversarial review.

Target: @.prompts/{num}-{topic}-{target_purpose}/{topic}-{target_purpose}.md
Target summary: @.prompts/{num}-{topic}-{target_purpose}/SUMMARY.md

Purpose: Surface genuine weaknesses, unverified claims, scope problems, and internal contradictions before planning or implementation proceeds.
Output: {topic}-spar.md with structured counterarguments
</spar_objective>

<spar_scope>
<target_understanding>
Before generating counterarguments, fully understand the target:
- What is the core thesis or recommendation?
- What evidence supports it?
- What assumptions does it rely on?
- What audience is it written for?
</target_understanding>

<attack_surface>
Focus adversarial review on:
- Claims presented as findings that are actually assertions
- Mechanisms that are asserted to transfer without evidence of transfer
- Scope assumptions (too narrow or too broad)
- Internal contradictions between sections
- The target violating its own stated principles
- Confident prose covering unverified claims
</attack_surface>

<constraints>
- Steel-man every argument (strongest version, not strawman)
- Attack the strongest claims, not the weakest
- Do NOT pad with weak arguments — 3 strong beat 7 weak
- Distinguish genuine weaknesses from contrarian pattern-matching
- Do NOT soften with "overall this is great, but..."
</constraints>
</spar_scope>

<output_structure>
Save to: `.prompts/{num}-{topic}-spar/{topic}-spar.md`

Structure counterarguments using this XML format:

```xml
<spar>
  <target_summary>
    {2-3 sentence summary of what the target claims}
  </target_summary>

  <counterarguments>
    <argument type="{structural|presentation|scope|evidence|consistency}" strength="{strong|moderate|weak}">
      <title>{Concise argument title}</title>
      <claim>{The specific claim being challenged}</claim>
      <challenge>{Steel-manned counterargument}</challenge>
      <impact>{What breaks or weakens if this criticism is valid}</impact>
      <verdict>{Is this a genuine weakness or contrarian pattern-matching? One sentence.}</verdict>
    </argument>
    <!-- Additional arguments -->
  </counterarguments>

  <what_survives>
    {Which claims withstand adversarial review and why — this is as important as the criticisms}
  </what_survives>

  <self_audit>
    <strongest_argument>{number} — {why it matters}</strongest_argument>
    <weakest_argument>{number} — {why it might be posturing}</weakest_argument>
    <blind_spots>{What the adversarial review itself might be missing}</blind_spots>
  </self_audit>

  <metadata>
    <confidence level="{high|medium|low}">
      {How confident in the adversarial analysis}
    </confidence>
    <dependencies>
      {What the plan stage needs to address from this spar}
    </dependencies>
    <open_questions>
      {Questions the spar raises that neither affirm nor deny — genuinely unresolved}
    </open_questions>
    <assumptions>
      {What the adversarial review itself assumed}
    </assumptions>
  </metadata>
</spar>
```
</output_structure>

<summary_requirements>
Create `.prompts/{num}-{topic}-spar/SUMMARY.md`

Load template: [summary-template.md](summary-template.md)

For spar, emphasize:
- Number of counterarguments and their strength distribution
- The single strongest criticism (one sentence)
- What survives scrutiny (one sentence)
- What the downstream plan must address
</summary_requirements>

<success_criteria>
- Every argument is steel-manned
- Arguments target the strongest claims, not the weakest
- Clear distinction between argument types (structural, presentation, scope, evidence, consistency)
- Self-audit honestly identifies strongest and weakest arguments
- <what_survives> section is substantive — not everything is torn down
- Metadata captures genuine open questions
- SUMMARY.md created with substantive one-liner
- Ready for plan stage to consume alongside research
</success_criteria>
```
</prompt_template>

<key_principles>

<steel_man_not_strawman>
Attack the strongest version of each claim:
```xml
<argument type="structural" strength="strong">
  <title>Transfer mechanism is asserted, not demonstrated</title>
  <claim>Mushin practice in the dojo builds resistance to AI sycophancy</claim>
  <challenge>Mushin developed in physical combat with immediate bodily feedback. Software engineering provides no equivalent correction mechanism. The essay asserts the practice transfers without demonstrating the transfer mechanism. The dojo corrects instantly; the IDE corrects weeks later in production.</challenge>
  <impact>If the transfer mechanism doesn't hold, the essay's central thesis — that contemplative practice provides structural resistance — is an appealing analogy rather than a demonstrated claim.</impact>
  <verdict>Genuine weakness. The essay needs either evidence of transfer or honest acknowledgment that the parallel is aspirational.</verdict>
</argument>
```
</steel_man_not_strawman>

<attack_strong_claims>
Target claims the author is most confident about:
```xml
<!-- GOOD: Attacks the central thesis -->
<argument type="evidence" strength="strong">
  <claim>"The person who has practiced mushin is structurally resistant to the sycophancy trap"</claim>
  <challenge>This is an assertion presented as a finding. No evidence is cited. The confident prose makes it read as established fact when it is speculation.</challenge>
</argument>

<!-- BAD: Attacks a peripheral detail -->
<argument type="presentation" strength="weak">
  <claim>The Redis caching example is too simple</claim>
  <challenge>A more complex example would be more convincing</challenge>
</argument>
```
</attack_strong_claims>

<what_survives_matters>
The spar should identify what withstands scrutiny:
```xml
<what_survives>
The core observation — that AI is structurally optimized to agree and that this creates ego risks — is well-supported by the RLHF mechanism description and consistent with observable behavior. The practical mitigations (asking AI to argue against your approach, treating agreement as null signal) are sound regardless of whether the Zen framework is accepted.

The weakest link is the transfer mechanism between dojo practice and engineering practice. The strongest link is the specific, concrete description of how AI validation hooks identity formation.
</what_survives>
```
</what_survives_matters>

</key_principles>

<spar_types>

<thesis_spar>
For challenging a research finding or essay thesis:

```xml
<spar_objective>
Challenge ego-ai-research with adversarial review.

Target: @.prompts/003-ego-ai-research/ego-ai-research.md
</spar_objective>

<spar_scope>
<attack_surface>
- Is the central claim evidence-backed or assertion-dressed-as-evidence?
- Does the mechanism (Zen → engineering) actually transfer?
- Is the scope appropriate (too narrow: only AI? too broad: all ego problems)?
- Does the target contradict itself?
- Would the target audience find this convincing or motivational-speaker-adjacent?
</attack_surface>
</spar_scope>
```
</thesis_spar>

<plan_spar>
For challenging a plan before implementation:

```xml
<spar_objective>
Challenge auth-plan with adversarial review.

Target: @.prompts/002-auth-plan/auth-plan.md
</spar_objective>

<spar_scope>
<attack_surface>
- Are the phases ordered correctly, or do dependencies suggest a different sequence?
- Are effort estimates realistic or optimistic?
- What failure modes are not addressed?
- What assumptions about the codebase or team could be wrong?
- Is the plan solving the stated problem or a different, easier problem?
</attack_surface>
</spar_scope>
```
</plan_spar>

<priority_spar>
For challenging backlog prioritization:

```xml
<spar_objective>
Challenge the current backlog priority ordering.

Target: @BACKLOG.md
</spar_objective>

<spar_scope>
<attack_surface>
- Is the #1 priority genuinely the most impactful, or is it there because of momentum/sunk cost?
- Are any Ideas items being ignored that would deliver more value than current Up Next items?
- Is the In Progress list actually active, or is anything stale?
- Is the ranking anchored to prior decisions rather than current reality?
</attack_surface>
</spar_scope>
```
</priority_spar>

</spar_types>

<chain_integration>
Spar prompts are consumed by downstream plan or do prompts:

```xml
<!-- In a plan prompt that follows a spar -->
<context>
Research findings: @.prompts/001-auth-research/auth-research.md
Adversarial review: @.prompts/002-auth-spar/auth-spar.md

This plan must address the counterarguments raised in the spar output.
For each strong counterargument, either:
1. Modify the plan to account for it
2. Explicitly justify why the plan proceeds despite it
3. Flag it as a known risk with mitigation

Do NOT ignore spar output. The plan is stronger because it survived scrutiny.
</context>
```

When chain detection finds a `*-spar.md` file for a topic, automatically include it as a reference for downstream prompts and add the instruction above.
</chain_integration>

<folder_structure>
Spar prompts follow the standard folder convention:

```
.prompts/
├── 001-auth-research/
│   ├── completed/
│   │   └── 001-auth-research.md
│   ├── auth-research.md
│   └── SUMMARY.md
├── 002-auth-spar/
│   ├── completed/
│   │   └── 002-auth-spar.md
│   ├── auth-spar.md           # Counterarguments
│   └── SUMMARY.md
├── 003-auth-plan/
│   ├── completed/
│   │   └── 003-auth-plan.md   # References both research AND spar
│   ├── auth-plan.md
│   └── SUMMARY.md
```
</folder_structure>

<execution_notes>

<dependency_handling>
Spar prompts depend on the target output existing:
- Check target file exists before execution
- If target missing, offer to create the research/plan prompt first

```xml
<dependency_check>
If `.prompts/{num}-{topic}-{target_purpose}/{topic}-{target_purpose}.md` not found:
- Error: "Cannot spar — target output doesn't exist"
- Offer: "Create the {target_purpose} prompt first?"
</dependency_check>
```
</dependency_handling>

<no_archive_of_target>
Spar does NOT modify or archive the target. It produces a new artifact alongside it. The target author (human or AI) decides what to change based on the spar output.
</no_archive_of_target>

</execution_notes>

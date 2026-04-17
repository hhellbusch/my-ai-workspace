# Workflow: Synthesize Findings

<required_reading>
**Read these before proceeding:**
1. templates/assessment-template.md
2. All files in `research/{subject}/findings/`
3. The manifest at `research/{subject}/manifest.md`
</required_reading>

<process>

## Step 1: Read All Findings

Read every batch findings file from `research/{subject}/findings/`. Build a mental model of:
- Which claims were verified and at what confidence level
- Which claims had problems (misleading, stripped of context, unsupported)
- Which claims couldn't be verified and why
- What patterns emerged across the analysis

## Step 2: Categorize by Confidence

Sort all analyzed claims into tiers:

- **High confidence** — verified by authoritative sources (official docs, peer-reviewed papers)
- **Medium confidence** — verified directionally but with caveats (maturity omissions, context stripping)
- **Low confidence** — problematic (misleading numbers, unsupported by cited source)
- **Unverifiable** — source unreachable and no alternative confirmation found

## Step 3: Identify Patterns

Look for systemic patterns across findings:
- Are economic claims consistently overstated?
- Are maturity levels systematically omitted?
- Is the article advocacy, analysis, or documentation?
- Which topic areas are strongest/weakest?
- Are there signs of AI-generated content (consistent style, lack of nuance)?

## Step 4: Write the Assessment

Copy `templates/assessment-template.md` to `research/{subject}/assessment.md`.

Fill in:
- **Summary** — 3-5 sentence overview of what we found
- **Confidence table** — one row per topic area with confidence rating and basis
- **Key findings** — numbered findings with supporting evidence from batch analysis
- **Recommendations** — what a reader should trust, what they should verify independently, what they should discard
- **Methodology** — how many sources checked, what we couldn't reach, tools used

## Step 5: Cross-Reference Back

Review the assessment against the original article one more time:
- Is our assessment fair? Are we being too harsh or too generous?
- Did we miss any major claim areas?
- Are there claims we initially flagged that actually hold up when considering the full picture?

## Step 6: Deliver

Present the assessment to the user with:
- A brief verbal summary of the key findings
- The file path to the full assessment
- Any recommended follow-up actions (e.g., "the economic claims need independent verification before sharing with leadership")

</process>

<success_criteria>
This workflow is complete when:
- [ ] All batch findings have been read and synthesized
- [ ] Confidence table covers every major topic area
- [ ] Key findings are supported by specific evidence
- [ ] Assessment file is written to disk
- [ ] Patterns and systemic issues are documented
- [ ] User has received the assessment and knows what to trust
</success_criteria>

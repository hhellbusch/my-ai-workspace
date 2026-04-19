# Workflow: Analyze Claims

<required_reading>
**Read these before proceeding:**
1. templates/batch-findings-template.md
2. references/verification-patterns.md
3. The manifest at `research/{subject}/manifest.md` (to know what's available)
</required_reading>

<process>

## Step 1: Understand the Scope

Read the manifest to determine:
- How many sources were fetched successfully
- Which topic areas they cover
- Whether this is a standard article (claims map to external citations) or a transcript/single-source (claims are assertions within the source itself)

**For transcript/single-source analysis:** The manifest will list extracted claims (`C1`, `C2`, ...) rather than cited references. Each claim is evaluated for:
- Internal coherence and self-consistency
- Verifiability against external sources (for factual/architectural claims)
- Directional plausibility (for predictive claims)
- Workspace connections and tensions (for talks that relate to existing research)

If the original article is on disk (`sources/original-article.md`) or the transcript is at `sources/ref-01-transcript.md`, read it to confirm the claims list is complete before batching.

## Step 2: Plan Batches

**Standard path (article with citations):** Group sources into batches of 3-5 files by topic area. Prioritize:
1. **Economic/quantitative claims** — these are most likely to be misleading
2. **Architecture claims** — verifiable against official documentation
3. **Feature maturity claims** — check for GA vs. preview vs. alpha status
4. **Strategic/qualitative claims** — hardest to falsify, check last

**Transcript/single-source path:** Group the extracted claims into thematic batches of 5-8 claims. Suggested groupings:
1. **Factual/verifiable claims** — specific numbers, product states, dates
2. **Architectural claims** — how systems work (check against public repos/docs if available)
3. **Predictive/framework claims** — evaluate coherence and supporting evidence
4. **Workspace connections** — how claims connect to or tension with existing research, essays, library entries

Create a batch plan:
```
Batch 1: Economic claims (refs 1, 61, 62)
Batch 2: Serving architecture (refs 3, 8, 12)
Batch 3: ...
```

## Step 3: Process Batches in Parallel

**Batches are independent — launch them concurrently using Task agents.**

For each batch, launch a `generalPurpose` Task agent with this prompt structure:

```
You are analyzing sources for a research verification exercise.
Read source files from {research_dir}/sources/ and compare them
against the original article at {research_dir}/sources/original-article.md.

Sources to analyze: [list of ref files for this batch]

The article claims: [specific claims mapped to these sources]

For each source:
1. Read the source file
2. Find the specific claims the article maps to it
3. Compare article vs source — note omissions, context stripping, maturity levels
4. Assign verdict: VERIFIED | VERIFIED WITH CAVEATS | MISLEADING | UNSUPPORTED | UNVERIFIABLE

Write findings to: {research_dir}/findings/batch-{nn}-{topic}.md
Use the batch findings template structure.
```

**Parallelization rules:**
- Launch up to 4 batch agents simultaneously in a single message (multiple Task tool calls)
- Each agent reads/writes its own files — no conflicts
- Wait for all agents to return before proceeding
- If more than 4 batches, launch the first 4, wait, then launch the remainder
- After all batches complete, verify all expected findings files exist on disk

**Each agent needs these context elements in its prompt:**
- Path to the original article on disk
- Path to the source files it should read
- The specific claims from the article that map to those sources
- The batch findings template structure (inline or by reference)
- Instructions to check for maturity levels (GA vs Tech Preview vs alpha)

Key questions per source (include in each agent's prompt):
- Does the article accurately represent what the source says?
- Is important context omitted?
- Are numbers quoted correctly, including their conditions and caveats?
- Is the source authoritative for the claim being made?
- What maturity/readiness level does the source describe?

## Step 4: Handle Gaps

For claims whose sources couldn't be fetched:
- Can the claim be cross-checked against other fetched sources?
- Can a web search find the specific number or fact?
- If neither, mark as "unverifiable" with a note on what we tried

## Step 5: Incremental Progress

After each batch:
- Write findings to disk immediately (don't accumulate in memory)
- Update the manifest to note which refs have been analyzed
- Give the user a brief status update

If the conversation needs to reset, all progress is on disk and the next session can pick up where this one left off.

## Step 6: Phase-Boundary Checkpoint — HARD STOP

**Do not proceed to synthesis. Stop here and report to the user.**

Tell the user:
- Total claims analyzed: verified / verified-with-caveats / misleading / unsupported / unverifiable
- Which topic areas had the most issues
- Key pattern emerging across the batches (1-2 sentences)
- Confirm all findings files are on disk: list `research/{subject}/findings/` contents

Then ask:

> **Analysis phase complete.** Findings are at `research/{subject}/findings/`. Ready to synthesize into a final assessment?
> - Yes — proceed to `synthesize-findings.md`
> - No — describe what to revisit

**Wait for explicit confirmation before starting synthesis.**

</process>

<success_criteria>
This workflow is complete when:
- [ ] All sources/claims have been read and evaluated
- [ ] Findings for each batch are written to disk (verified by listing the files)
- [ ] Each finding includes: what is claimed, what the source says, verdict, impact
- [ ] Unverifiable claims are documented with explanation
- [ ] User has explicitly confirmed readiness to proceed to synthesis
</success_criteria>

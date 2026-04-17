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
- What claims from the original article map to which sources

If the original article is on disk (`sources/original-article.md`), read it to extract the key claims to verify.

## Step 2: Plan Batches

Group sources into batches of 3-5 files by topic area. Prioritize:
1. **Economic/quantitative claims** — these are most likely to be misleading
2. **Architecture claims** — verifiable against official documentation
3. **Feature maturity claims** — check for GA vs. preview vs. alpha status
4. **Strategic/qualitative claims** — hardest to falsify, check last

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

## Step 6: Checkpoint

When all batches are done, tell the user:
- Number of claims verified / problematic / unverifiable
- Which topic areas had issues
- Recommended next step (synthesize findings)

</process>

<success_criteria>
This workflow is complete when:
- [ ] All fetched sources have been read and compared to article claims
- [ ] Findings for each batch are written to disk
- [ ] Each finding includes: what the article claims, what the source says, verdict
- [ ] Unverifiable claims are documented with explanation
- [ ] User knows the status and patterns emerging
</success_criteria>

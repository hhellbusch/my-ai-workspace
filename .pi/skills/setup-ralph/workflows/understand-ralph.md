# Workflow: Understand Ralph

<required_reading>
**Read these reference files NOW:**
1. references/ralph-fundamentals.md
</required_reading>

<process>
## Step 1: Identify Learning Goal

Ask the user using AskUserQuestion:
"What aspect of Ralph would you like to understand better?"

Options:
1. **The core concept** - What Ralph is and why it works
2. **The three phases** - Planning, building, and observation
3. **Backpressure** - How tests and validation steer Ralph
4. **AGENTS.md** - How to capture and evolve learnings
5. **When to use Ralph** - Is it right for my project?

## Step 2: Explain Based on Selection

### If "The core concept":

Explain:
```
Ralph is Geoffrey Huntley's autonomous coding technique. In its purest form:

    while :; do cat PROMPT.md | claude ; done

That's it. 16 characters of bash plus a prompt file.

WHY IT WORKS:

1. Fresh context every iteration
   - Each loop starts with clean 200K context window
   - No accumulated history, no stale assumptions
   - Forces decisions to be grounded in files on disk

2. File I/O as state
   - IMPLEMENTATION_PLAN.md is the only persistent state
   - Claude reads it, updates it, commits it
   - No sophisticated orchestration needed

3. Backpressure as steering
   - Tests, type checks, lints provide feedback
   - If code doesn't pass validation, loop continues
   - Quality is enforced, not hoped for

4. The loop is inevitable
   - Given enough iterations, progress happens
   - Bad iterations get rejected by validation
   - Good iterations accumulate as commits

The insight: "Deterministically bad in an undeterministic world"
- Traditional AI coding fights probabilistic nature of LLMs
- Ralph embraces chaos by resetting context each iteration
- Plan on disk provides deterministic shared state
```

### If "The three phases":

Explain:
```
Ralph has three distinct phases:

PHASE 1: PLANNING
- Objective: Gap analysis only
- Input: Specs and existing code
- Output: IMPLEMENTATION_PLAN.md (prioritized TODO list)
- Rule: No implementation, no commits
- Key instruction: "Don't assume not implemented; confirm with code search"

Run with: ./loop.sh plan

PHASE 2: BUILDING
- Objective: Implement from the plan
- Input: Plan, specs, existing code
- Output: Code changes + commits
- Rule: One task per loop iteration

Process each iteration:
1. Select most important task
2. Search existing code (don't assume)
3. Implement functionality
4. Run validation
5. Update plan
6. Commit changes
7. Exit (fresh context next iteration)

Run with: ./loop.sh

PHASE 3: OBSERVATION (Your Role)
- Objective: Sit on the loop, not in it
- Action: Engineer the environment

You DO:
- Watch for failure patterns
- Update AGENTS.md with learnings
- Tune prompts based on observed behavior
- Regenerate plan when trajectory fails
- Add backpressure mechanisms

You DON'T:
- Jump into the loop to fix things
- Manually implement features
- Edit code directly
- Interfere with the autonomous process

The shift: From implementer to environment engineer
```

### If "Backpressure":

Load `references/validation-strategy.md` then explain:
```
Backpressure is automated validation that rejects invalid work.

THE FEEDBACK LOOP:
1. Ralph implements task
2. Validation runs (tests, type checks, lints)
3. If fails → Ralph investigates and fixes
4. Loop continues until validation passes
5. Only then can Ralph commit and proceed

WITHOUT BACKPRESSURE: Ralph generates code that may not work
WITH BACKPRESSURE: Ralph must produce working code to progress

TYPES OF BACKPRESSURE:

Tests (most important)
- Binary pass/fail
- Aligned with requirements
- Fast feedback each iteration

Type checking
- Catches type errors before runtime
- Enforces interface contracts
- TypeScript: tsc --noEmit
- Python: mypy

Linting
- Enforces code style
- Catches common mistakes
- Start minimal, add rules as patterns emerge

Builds
- Catches syntax errors
- Verifies dependencies

VALIDATION LEVELS:
- Level 1: Tests only (fastest)
- Level 2: Tests + type checking (recommended)
- Level 3: Full validation (tests + types + lint + build)

If you have no tests, Ralph should create them as part of implementation.
```

### If "AGENTS.md":

Load `references/operational-learnings.md` then explain:
```
AGENTS.md captures project-specific learnings that Ralph needs.

START MINIMAL:
```markdown
# Operational Learnings
```

That's literally enough to start. Don't pre-populate.

WHEN TO ADD:

1. Repeated mistakes
   Ralph keeps reimplementing auth? Add:
   "Always use src/lib/auth.ts for authentication"

2. Project-specific commands
   Tests need special setup? Add:
   "Run: export NODE_ENV=test && npm test"

3. Discovered constraints
   Ralph keeps using wrong library? Add:
   "Do NOT use lodash (not installed)"

4. Architectural decisions
   Code in wrong places? Add:
   "UI components: src/components/"

WHEN NOT TO ADD:
- One-off mistakes (wait for pattern)
- General best practices (Claude knows these)
- Things already in specs (don't duplicate)
- Temporary workarounds (fix root cause)

EVOLUTION:
- Days 1-3: Mostly empty, watching for patterns
- Week 1: First entries, build commands, constraints
- Weeks 2-4: Known patterns documented
- Month 2+: Stable, changes infrequently
```

### If "When to use Ralph":

Explain:
```
RALPH WORKS BEST WHEN:

✓ You have clear specifications
  - Written requirements Ralph can study
  - Acceptance criteria defined
  - One topic per spec file

✓ Your project has test coverage
  - Tests create backpressure
  - Ralph can validate its own work
  - No tests = no feedback loop

✓ You can observe initially
  - First 30+ minutes need watching
  - Prompts evolve through observation
  - Early failures inform AGENTS.md

✓ You want autonomous operation
  - Overnight coding sessions
  - Hands-off implementation
  - Batch processing of tasks

RALPH IS NOT FOR:

✗ Exploratory coding
  - No clear specs to implement
  - "Figure out what we need" situations
  - Creative/design-heavy work

✗ Projects without tests
  - No validation = no steering
  - Ralph may accumulate errors
  - Add tests first, then use Ralph

✗ Quick one-off changes
  - Loop overhead not worth it
  - Just make the change directly

✗ Highly interactive work
  - Constant human decisions needed
  - Approval gates every step
  - Design reviews mid-implementation

THE QUESTION TO ASK:
"Can I write specs clear enough that passing tests proves completion?"

If yes → Ralph can help
If no → Consider manual implementation or clarify specs first
```

## Step 3: Offer Follow-up

Ask: "Would you like to:"
1. **Learn about another concept** - Continue exploring Ralph
2. **Set up a Ralph loop** - Route to setup-new-loop.md
3. **Return to main menu** - Done learning for now

If option 1, return to Step 1.
If option 2, route to `workflows/setup-new-loop.md`.
</process>

<success_criteria>
This workflow is complete when:
- [ ] User selected a learning topic
- [ ] Relevant explanation provided with examples
- [ ] User offered follow-up options
- [ ] User understands enough to proceed or continue learning
</success_criteria>

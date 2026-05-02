# Workflow: Customize Ralph Loop

<required_reading>
**Read these reference files NOW:**
1. references/prompt-design.md
2. references/validation-strategy.md
3. references/operational-learnings.md
</required_reading>

<process>
## Step 1: Identify Customization Goal

Ask the user using AskUserQuestion:
"What would you like to customize?"

Options:
1. **Prompts** - Modify PROMPT_plan.md or PROMPT_build.md
2. **Validation** - Change test/lint/build commands
3. **Loop behavior** - Model, limits, stuck detection, backup
4. **AGENTS.md** - Add project-specific learnings

## Step 2: Handle Based on Selection

### If "Prompts":

Ask: "Which prompt do you want to modify?"
- **Planning prompt** - PROMPT_plan.md
- **Building prompt** - PROMPT_build.md
- **Both** - I'll guide you through each

For each selected prompt:

1. Read the current prompt file
2. Ask: "What behavior do you want to change?"
   - Ralph keeps missing something → Add specific instruction
   - Ralph does too much per iteration → Add clearer exit criteria
   - Ralph uses wrong patterns → Add pattern guidance
   - Subagent counts need adjustment → Update parallelism numbers
   - Other (describe)

3. Apply the principle: **Start minimal, evolve through observation**
   - Don't add rules you haven't seen need for
   - Add ONE change at a time
   - Test the change with a few iterations
   - If it helps, keep it; if not, remove it

4. Make the edit and explain:
   ```
   Added to [prompt file]:
   [The change]

   Why: [Observation that led to this]

   Watch for: [How to know if it's working]
   ```

### If "Validation":

1. Read current PROMPT_build.md to find validation section
2. Ask: "What validation changes do you need?"
   - **Add tests** - Run additional test command
   - **Add type checking** - Add tsc/mypy/etc
   - **Add linting** - Add eslint/ruff/etc
   - **Add build** - Add build verification
   - **Remove validation** - Validation is too slow
   - **Custom command** - I'll specify

3. For additions, update the validation section in PROMPT_build.md:
   ```markdown
   4. Validate
      - Run: [commands]
      - If validation fails, investigate and fix
      - Do not commit until all validation passes
   ```

4. Warn about removing validation:
   ```
   Removing validation reduces backpressure. Ralph may:
   - Produce code that doesn't work
   - Accumulate errors across iterations
   - Go off track without feedback

   Only remove validation if you're certain it's not needed.
   ```

### If "Loop behavior":

Ask: "What loop setting do you want to change?"
- **Model** - Switch between opus/sonnet/haiku
- **Iteration limit** - Set max iterations
- **Stuck detection** - Change failure threshold
- **Remote backup** - Enable/disable GitHub push
- **Verbosity** - More/less output

For each:

**Model:**
```bash
# In loop.sh or via command line
./loop.sh --model sonnet  # Faster, cheaper
./loop.sh --model opus    # More capable (default)

# Or set default in environment
export RALPH_MODEL=sonnet
```

Guidance:
- opus: Best for complex reasoning, architecture decisions
- sonnet: Good for straightforward implementation tasks
- haiku: Fast for simple tasks (not recommended for Ralph)

**Iteration limit:**
```bash
./loop.sh 20        # Build mode, max 20 tasks
./loop.sh plan 5    # Plan mode, max 5 iterations
```

Default is unlimited (runs until complete or Ctrl+C).

**Stuck detection:**
```bash
export RALPH_MAX_STUCK=5  # Fail 5 times before skipping (default: 3)
```

Note: Stuck detection auto-skips tasks. If you prefer manual intervention, set high value or watch the loop.

**Remote backup:**
```bash
export RALPH_BACKUP=false  # Disable auto-push to GitHub
export RALPH_BACKUP=true   # Enable (default)
```

**Verbosity:**
```bash
./loop.sh --verbose  # More detailed Claude output
```

### If "AGENTS.md":

1. Read current AGENTS.md
2. Ask: "What pattern or learning do you want to add?"
   - **Build/test command** - How to run validation
   - **Code pattern** - Where things go, how they're structured
   - **Constraint** - What NOT to do
   - **Gotcha** - Non-obvious behavior to remember

3. Apply the entry following the format:
   ```markdown
   ## [Section]

   ### [Topic]
   [Concise guidance - 1-3 lines]
   ```

4. Remind the user:
   ```
   AGENTS.md best practices:
   - Keep entries concise (1-3 lines)
   - Add only after observing repeated issues
   - Remove entries that become stale
   - Don't duplicate what's in specs
   ```

## Step 3: Verify and Test

After making changes:

1. Summarize what was changed
2. Suggest testing:
   ```
   To test this change:
   1. Run: ./loop.sh [plan|build] 1  # Single iteration
   2. Watch the behavior
   3. If good, continue; if not, revert with:
      git checkout [file]
   ```

## Step 4: Offer Follow-up

Ask: "Would you like to:"
1. **Make another customization** - Return to Step 1
2. **Run the loop to test** - Exit and let user run
3. **Return to main menu** - Done customizing
</process>

<success_criteria>
This workflow is complete when:
- [ ] User identified what to customize
- [ ] Appropriate changes made or guidance provided
- [ ] User understands how to test the changes
- [ ] User knows how to revert if needed
</success_criteria>

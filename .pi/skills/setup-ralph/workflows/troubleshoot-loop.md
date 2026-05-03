# Workflow: Troubleshoot Ralph Loop

<required_reading>
**Read these reference files NOW:**
1. references/ralph-fundamentals.md (escape hatches section)
2. references/validation-strategy.md (handling failures section)
</required_reading>

<process>
## Step 1: Identify the Problem

Ask the user using AskUserQuestion:
"What issue are you experiencing?"

Options:
1. **Ralph is stuck on a task** - Same task failing repeatedly
2. **Ralph went off track** - Implementing wrong things
3. **Validation keeps failing** - Tests/builds won't pass
4. **Loop won't start** - Errors before first iteration
5. **Performance issues** - Too slow, using too many resources
6. **Other** - Describe the problem

## Step 2: Diagnose and Fix

### If "Ralph is stuck on a task":

Check:
1. Look at `.ralph_stuck_tracker` if it exists
2. Check `ralph.log` for recent output
3. Review `IMPLEMENTATION_PLAN.md` for the stuck task

Common causes and fixes:

**Task is genuinely hard:**
- Break it into smaller tasks in the plan
- Add more specific guidance to AGENTS.md
- Clarify the spec for that feature

**Task description is ambiguous:**
```bash
# Edit IMPLEMENTATION_PLAN.md to clarify the task
# Be specific: "Add login endpoint" → "Add POST /api/auth/login endpoint that validates credentials and returns JWT"
```

**Missing dependency:**
- Check if another task should be done first
- Reorder priorities in the plan

**Stuck detection triggered incorrectly:**
```bash
# Reset the stuck tracker
rm .ralph_stuck_tracker

# Increase threshold if tasks legitimately need retries
export RALPH_MAX_STUCK=5
./loop.sh
```

### If "Ralph went off track":

The answer is usually: **Regenerate the plan**

```bash
# Stop the loop
Ctrl+C

# Review what Ralph did
git log --oneline -10
git diff HEAD~5..HEAD --stat

# If recent work is bad, revert
git reset --hard HEAD~[number]

# Regenerate plan from current state
rm IMPLEMENTATION_PLAN.md
./loop.sh plan
```

Then investigate WHY:
- Specs unclear? → Update specs
- Missing context? → Add to AGENTS.md
- Prompt too vague? → Add specific instructions

### If "Validation keeps failing":

1. **Read the error output:**
   ```bash
   # Check recent log
   tail -100 ralph.log
   ```

2. **Common validation issues:**

   **Test failures:**
   - Is the test correct? Sometimes specs changed but tests didn't
   - Is Ralph implementing the wrong behavior?
   - Add test-specific guidance to AGENTS.md

   **Type errors:**
   - Check if interfaces changed
   - Ralph may be using outdated patterns
   - Add type patterns to AGENTS.md

   **Lint errors:**
   - Often style issues Ralph can fix
   - If lint is too strict, consider relaxing rules
   - Or add lint-specific patterns to AGENTS.md

   **Build failures:**
   - Missing imports/dependencies
   - Syntax errors
   - Check if Ralph is generating valid code for your framework

3. **If Ralph can't fix it:**
   ```bash
   # Stop loop
   Ctrl+C

   # Fix manually
   [make the fix]

   # Commit the fix
   git add . && git commit -m "Manual fix: [description]"

   # Add learning to prevent recurrence
   # Edit AGENTS.md with what you learned

   # Resume
   ./loop.sh
   ```

### If "Loop won't start":

**Check prompt files exist:**
```bash
ls -la PROMPT_plan.md PROMPT_build.md
```
If missing, run setup again or create from templates.

**Check Claude CLI:**
```bash
claude --version
```
If not found: `npm install -g @anthropic-ai/claude-code`

**Check OAuth token (for headless mode):**
```bash
# Verify token exists
cat ~/.claude-oauth-token

# If missing, run:
claude setup-token
# Save to ~/.claude-oauth-token

# Set permissions
chmod 600 ~/.claude-oauth-token
```

**Check plan file for build mode:**
```bash
ls IMPLEMENTATION_PLAN.md
```
If missing, run `./loop.sh plan` first.

**Check permissions:**
```bash
chmod +x loop.sh
```

### If "Performance issues":

**Too slow per iteration:**
- Switch to Sonnet: `./loop.sh --model sonnet`
- Reduce validation: Remove slow checks from PROMPT_build.md
- Smaller tasks: Break tasks into smaller units

**Using too many resources:**
- Reduce subagent counts in prompts (250 → 50)
- Use Docker mode for isolation with resource limits:
  ```bash
  # In loop-docker.sh, docker run could add:
  # --memory=4g --cpus=2
  ```

**Too many API calls:**
- Run fewer iterations: `./loop.sh 10`
- Increase sleep between iterations (edit loop.sh)
- Use batch backup (reduce push frequency)

### If "Other":

Ask user to describe the specific issue, then:

1. Check `ralph.log` for error messages
2. Check `IMPLEMENTATION_PLAN.md` for state
3. Check git log for recent changes
4. Check AGENTS.md for relevant guidance

## Step 3: Emergency Escape Hatches

If nothing else works:

**Stop everything:**
```bash
Ctrl+C
```

**Revert all uncommitted changes:**
```bash
git reset --hard HEAD
```

**Revert to known good state:**
```bash
git log --oneline -20  # Find good commit
git reset --hard [commit-hash]
```

**Start fresh with new plan:**
```bash
rm IMPLEMENTATION_PLAN.md
rm .ralph_stuck_tracker
./loop.sh plan
```

**Nuclear option - start completely over:**
```bash
# Keep your source code, reset Ralph state
rm IMPLEMENTATION_PLAN.md
rm AGENTS.md
rm .ralph_stuck_tracker
rm ralph.log
rm REPORT.md

# Reinitialize
# Edit PROMPT_*.md if needed
./loop.sh plan
```

## Step 4: Prevent Recurrence

After fixing the issue:

1. **Add to AGENTS.md** if relevant pattern discovered
2. **Update specs** if requirements were unclear
3. **Update prompts** if Claude needed different instructions
4. **Consider Docker mode** if safety is a concern

Ask: "Would you like to:"
1. **Add a learning to AGENTS.md** - Document what went wrong
2. **Update prompts** - Change Claude's instructions
3. **Resume the loop** - Continue with the fix applied
4. **Return to main menu** - Done troubleshooting
</process>

<success_criteria>
This workflow is complete when:
- [ ] User's issue identified
- [ ] Diagnosis steps followed
- [ ] Fix applied or guidance provided
- [ ] Prevention steps discussed
- [ ] User can resume work
</success_criteria>

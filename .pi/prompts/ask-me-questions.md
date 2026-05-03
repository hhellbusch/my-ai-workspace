---
description: Gather requirements through adaptive questioning before executing any task
argument-hint: [task or leave blank]
---

<objective>
Use the Intake & Decision Gate pattern to gather requirements through adaptive questioning before executing a task.

This prevents premature execution, captures nuance, and creates a collaborative context-building flow where you maintain control over when work begins.
</objective>

<intake_gate>

<no_context_handler>
IF $ARGUMENTS is empty or vague:
→ **IMMEDIATELY use AskUserQuestion** with:
  - header: "Task"
  - question: "What would you like help with?"
  - options:
    - "Write something" - Create a document, email, post, or other written content
    - "Build something" - Create code, a feature, system, or technical artifact
    - "Figure something out" - Research, analyze, or help me think through a problem
    - "Other" - Something else entirely

Then proceed to context_analysis with their response.

IF $ARGUMENTS provides clear context:
→ Skip to context_analysis
</no_context_handler>

<context_analysis>
Analyze $ARGUMENTS (or conversation context) to extract what's already provided:
- **What**: The task, deliverable, or outcome requested
- **Who**: Target audience, recipient, or stakeholders
- **Why**: Purpose, goal, or motivation
- **How**: Approach, constraints, or requirements
- **When**: Timeline, urgency, or dependencies

Only ask about genuine gaps - don't re-ask what's already stated.
</context_analysis>

<initial_questions>
Use AskUserQuestion to ask 2-4 questions based on actual gaps:

**If "what" is unclear:**
- "What specifically do you want?" with domain-appropriate options

**If "who" is unclear:**
- "Who is this for?" with options: Myself, My team, External stakeholders, Public audience, Other

**If "why" is unclear:**
- "What's the goal?" with options relevant to the task type

**If "how" is unclear:**
- "Any constraints or preferences?" with domain-appropriate options

Skip questions where the context already provides the answer.
</initial_questions>

<decision_gate>
After receiving answers, use AskUserQuestion:

Question: "Ready to proceed, or would you like me to ask more questions?"

Options:
1. **Start working** - I have enough context, proceed with the task
2. **Ask more questions** - There are details I want to clarify
3. **Let me add context** - I want to provide additional information

If "Ask more questions" → generate 2-3 contextual follow-ups based on accumulated context, then present decision gate again
If "Let me add context" → receive input, then present decision gate again
If "Start working" → proceed to execution
</decision_gate>

</intake_gate>

<process>
1. Check if context was provided via $ARGUMENTS
2. If no context: use AskUserQuestion to determine task type
3. Analyze provided context to identify what's already known
4. Ask 2-4 initial questions about genuine gaps only
5. Present decision gate
6. Loop (ask more / add context) until user selects "Start working"
7. Execute the task with full context gathered
</process>

<success_criteria>
- No questions asked about information already provided
- User maintains control over when execution begins
- Context accumulates through multiple rounds if needed
- All AskUserQuestion calls use structured options (not plain text questions)
- Task executes only after user explicitly chooses to proceed
</success_criteria>

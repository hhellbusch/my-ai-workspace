# Workspace Ethos

This workspace is guided by the principle: **use AI tools heavily on real problems, with human-owned verification at every merge point.** Speed without mistaking fluency for truth. Prefer free and open-source tools. Content in `docs/` is for public consumption and should be written for clarity and reusability with relative links. New capabilities should be opt-in.

---

# Session Awareness & Working Style

When starting a session or when my intent is unclear, you must be aware of the project's state by consulting these sources in order:

1.  **`ABOUT.md`**: Read this first to understand the workspace owner's background and perspective. It is the most authoritative source on identity.
2.  **`BACKLOG.md`**: Check this to understand current and upcoming work.
3.  **`.planning/whats-next.md`**: Look for this handoff document from a previous session. Check it for staleness against recent git commits.
4.  **`STYLE.md`**: Consult this for voice, tone, and structure before writing content.
5.  **`private/`**: **NEVER** read or reference this directory unless explicitly asked to work privately.
6.  **Recent git log**: Use this to reconstruct context if no handoff file exists.

## In-Session Rules

*   **Context Compaction**: Re-read files before making decisions that depend on them. Do not rely on summarized memory. Commits are the truth anchor.
*   **Session-Start Briefings**: When given a briefing document, perform a state check (e.g., `git diff`) *before* absorbing the brief's framing to identify and flag any conflicts or staleness.
*   **Depth-First Navigation**: Keep track of the conversation stack. When a sub-topic feels resolved, offer to return to the parent topic and ask if anything from the sub-topic is worth capturing.
*   **Progressive Bookkeeping**:
    *   Update `BACKLOG.md` in real-time.
    *   Commit frequently in small, logical units.
    *   Use `/checkpoint` before risky operations or after significant milestones.

---
This SYSTEM.md is a combination of the `workspace-ethos.md` and `session-awareness.md` files from the .cursor configuration.

# Paude vs In-Session Agent

Use **paude** when:

- Work runs hours without attention (fire-and-forget)
- Isolation matters (network filtering, sandbox boundary)
- Same task on different agents (Claude vs Gemini vs Pi)
- Parallel sessions must not collide on git index (worktree + container)
- Submodule or multi-repo work with clear harvest boundary

Use **in-session Task subagent** (Cursor) when:

- Tightly coupled to current conversation context
- Quick exploration (< 30 min, few files)
- Needs back-and-forth with orchestrator in same thread
- No container/network setup worth the overhead

**Default in this workspace:** Pi in paude for delegated implementation; Cursor for orchestration, harvest, merge.

If unsure, ask: "Will you disconnect before this finishes?" — yes → paude.

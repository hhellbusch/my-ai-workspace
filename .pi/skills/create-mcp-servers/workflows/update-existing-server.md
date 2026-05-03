# Update Existing MCP Server

<required_reading>
- [references/validation-checkpoints.md](../references/validation-checkpoints.md) - For verifying changes
</required_reading>

<process>

<step name="1_identify">
<title>Identify Server</title>

List installed servers:
```bash
claude mcp list
```

Ask user which server to modify and what changes are needed.
</step>

<step name="2_locate">
<title>Locate Server Files</title>

Standard location: `~/Developer/mcp/{server-name}/`

Read current implementation:
- `src/server.py` or `src/index.ts`
- `pyproject.toml` or `package.json`
- Any `operations.json` if using on-demand discovery pattern
</step>

<step name="3_understand">
<title>Understand Current Architecture</title>

Determine current pattern:
- Traditional (flat tools): Look for `@app.list_tools()` returning Tool list
- On-demand discovery: Look for 4 meta-tools (discover, get_schema, execute, continue)

Note current:
- Operation count
- Authentication method
- Response optimization (if any)
</step>

<step name="4_plan_changes">
<title>Plan Changes</title>

Based on user's request, determine:
- Adding new operations? May require architecture change if crossing 2→3 threshold
- Changing auth? May need OAuth pattern from [references/oauth-implementation.md](../references/oauth-implementation.md)
- Adding list/search? May need response optimization from [references/response-optimization.md](../references/response-optimization.md)

Present plan to user for confirmation.
</step>

<step name="5_implement">
<title>Implement Changes</title>

Make changes following the same patterns used in create workflow:
- Load relevant references for new functionality
- Apply patterns consistently with existing code
- Update operations.json if using on-demand discovery
</step>

<step name="6_verify">
<title>Verify Changes</title>

Run relevant validation checkpoints:
- [references/validation-checkpoints.md#code-syntax](../references/validation-checkpoints.md#code-syntax)
- [references/validation-checkpoints.md#claude-code-install](../references/validation-checkpoints.md#claude-code-install)

Test:
```bash
claude mcp list
# Should show ✓ Connected

# Check logs for errors
tail -20 ~/Library/Logs/Claude/mcp-server-{name}.log
```
</step>

</process>

<success_criteria>
Update is complete when:
- Changes implemented
- Server still shows ✓ Connected in `claude mcp list`
- No new errors in logs
- User confirms functionality works as expected
</success_criteria>

# Troubleshoot MCP Server

<required_reading>
- [references/validation-checkpoints.md](../references/validation-checkpoints.md) - All validation checks
</required_reading>

<process>

<step name="1_identify_symptom">
<title>Identify Symptom</title>

Common symptoms:
- Server not appearing in `claude mcp list`
- Server showing ✗ Disconnected
- "command not found" errors
- Environment variable not found
- Tools not working as expected
- Secrets visible in conversation (CRITICAL)
</step>

<step name="2_gather_diagnostics">
<title>Gather Diagnostics</title>

Run these commands:
```bash
# Check server status
claude mcp list

# Check logs
tail -50 ~/Library/Logs/Claude/mcp-server-{name}.log

# Check if command exists
which uv && which node && which python

# Check environment variables (existence only, not values)
env | grep -E "^[A-Z_]+=" | cut -d= -f1 | sort
```
</step>

<step name="3_diagnose">
<title>Diagnose Issue</title>

<issue type="not_appearing">
<symptom>Server not in `claude mcp list`</symptom>
<causes>
- Server never added
- Wrong server name
- Config file syntax error
</causes>
<solution>
Check Claude Code config:
```bash
cat ~/.claude/settings.json | jq '.mcpServers'
```
Re-add if missing using `claude mcp add` command.
</solution>
</issue>

<issue type="disconnected">
<symptom>Server shows ✗ Disconnected</symptom>
<causes>
- Command path incorrect
- Missing dependencies
- Syntax error in server code
- Missing environment variables
</causes>
<solution>
1. Check logs for specific error
2. Verify absolute paths: `which uv`, `which node`
3. Test server standalone: `cd ~/Developer/mcp/{name} && uv run python -m src.server`
4. Check for missing env vars in error message
</solution>
</issue>

<issue type="command_not_found">
<symptom>"command not found" in logs</symptom>
<causes>
- Relative path used instead of absolute
- Tool not installed
- Wrong path in config
</causes>
<solution>
1. Find absolute path: `which uv` or `which node`
2. Update config with absolute path
3. Remove and re-add server:
```bash
claude mcp remove {name}
claude mcp add --transport stdio {name} -- /absolute/path/to/uv ...
```
</solution>
</issue>

<issue type="env_var_missing">
<symptom>Environment variable not found</symptom>
<causes>
- Variable not set in ~/.zshrc
- Shell not reloaded after setting
- Variable name mismatch
</causes>
<solution>
1. Check if set: `echo $VAR_NAME`
2. If missing, add to ~/.zshrc:
```bash
echo 'export VAR_NAME="value"' >> ~/.zshrc
source ~/.zshrc
```
3. Restart Claude Code to pick up new variables
</solution>
</issue>

<issue type="secrets_visible">
<symptom>Secrets visible in conversation</symptom>
<severity>CRITICAL</severity>
<solution>
1. STOP immediately
2. Delete conversation
3. Rotate compromised credentials
4. Never paste secrets in chat
5. Use environment variables with exact commands for user to run in terminal
</solution>
</issue>

</step>

<step name="4_apply_fix">
<title>Apply Fix</title>

Based on diagnosis:
1. Make required changes
2. Run relevant validation checkpoint
3. Verify server connects: `claude mcp list`
4. Check logs are clean: `tail -20 ~/Library/Logs/Claude/mcp-server-{name}.log`
</step>

</process>

<success_criteria>
Troubleshooting complete when:
- Root cause identified
- Fix applied
- Server shows ✓ Connected
- No errors in recent logs
- User confirms issue resolved
</success_criteria>

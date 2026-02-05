# Validation Checkpoints

Reusable validation commands for each step.

## api-research

```bash
# Check document exists
test -f ~/Developer/mcp/{server-name}/API_RESEARCH.md && echo "✓ Research doc exists" || echo "✗ Missing API_RESEARCH.md"

# Verify required sections present
grep -q "## Authentication" ~/Developer/mcp/{server-name}/API_RESEARCH.md && echo "✓ Authentication documented" || echo "✗ Missing authentication"
grep -q "## Official SDK" ~/Developer/mcp/{server-name}/API_RESEARCH.md && echo "✓ SDK documented" || echo "✗ Missing SDK info"
grep -q "## Required Endpoints" ~/Developer/mcp/{server-name}/API_RESEARCH.md && echo "✓ Endpoints documented" || echo "✗ Missing endpoints"
grep -q "## Rate Limits" ~/Developer/mcp/{server-name}/API_RESEARCH.md && echo "✓ Rate limits documented" || echo "✗ Missing rate limits"

# Verify recency (2024-2025 sources only)
grep -E "(2024|2025)" ~/Developer/mcp/{server-name}/API_RESEARCH.md && echo "✓ Sources are current" || echo "✗ No 2024-2025 sources found"

# Count verified endpoints
VERIFIED_COUNT=$(grep -c "Verified: ✓" ~/Developer/mcp/{server-name}/API_RESEARCH.md)
echo "Verified endpoints: $VERIFIED_COUNT (expected: {count from Step 0})"
```

**Required before Step 2:**
- [ ] API_RESEARCH.md exists
- [ ] All required sections present
- [ ] Every planned operation has verified endpoint
- [ ] All sources dated 2024-2025
- [ ] Endpoint count matches Step 0

## project-structure

```bash
# Verify structure
test -d ~/Developer/mcp/{server-name} && echo "✓ Directory exists" || echo "✗ Missing"
test -f ~/Developer/mcp/{server-name}/pyproject.toml && echo "✓ Project initialized" || echo "✗ Not initialized"
```

**Required before Step 4:**
- [ ] Directory exists
- [ ] Project initialized

## code-syntax

```bash
# Verify code exists
test -f ~/Developer/mcp/{server-name}/src/server.py && echo "✓ Code created" || echo "✗ Missing"

# Check syntax (Python)
cd ~/Developer/mcp/{server-name}
python -m py_compile src/server.py && echo "✓ Valid syntax" || echo "✗ Syntax error"

# OR build (TypeScript)
npm run build && echo "✓ Build successful" || echo "✗ Build failed"
```

**Required before Step 5:**
- [ ] Code file exists
- [ ] Syntax valid / build successful

## env-vars

```bash
# Check variables set (without showing values)
for var in {ENV_VAR1} {ENV_VAR2}; do
  [ -z "${!var}" ] && echo "✗ $var not set" || echo "✓ $var set"
done
```

**Required before Step 6:**
- [ ] All environment variables set

## claude-code-install

```bash
# Verify installation
claude mcp list | grep {server-name}
# Expected: "{server-name}: ... - ✓ Connected"
```

**If not connected, check logs:**
```bash
tail -50 ~/Library/Logs/Claude/mcp-server-{server-name}.log
```

**Required before Step 7:**
- [ ] Server shows "✓ Connected" status

## claude-desktop-config

```bash
# Verify config entry exists
jq '.mcpServers | has("{server-name}")' "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
# Expected: true
```

**Required before Step 8:**
- [ ] Config entry exists for server

# Auto-Installation for MCP Servers

Complete guide for automatically installing MCP servers in both Claude Code and Claude Desktop with safe credential management.

## Overview

When you build an MCP server, you want it instantly available in both:
- **Claude Code** - For development and coding workflows
- **Claude Desktop** - For conversational usage

This guide provides scripts and patterns for zero-friction installation.

## The Problem

Manual MCP installation requires:
1. Adding to Claude Code via CLI (`claude mcp add`)
2. Editing Claude Desktop config JSON manually
3. Copying credentials to multiple places
4. Restarting both applications
5. Testing that everything works

This is tedious and error-prone.

## The Solution

A manual configuration approach with secure patterns:
1. Store credentials in `~/.mcp_secrets` with `chmod 600`
2. Use variable expansion (`${VAR}`) in all configs
3. Install in Claude Code (user scope)
4. Manually update Claude Desktop config with variable references
5. Never write hardcoded secrets to configuration files

**Why not automated?** Auto-installation scripts that write actual credential values to configs are insecure. The recommended pattern uses variable expansion everywhere.

## Secure Installation Guide

### Step 1: Set Up Secrets

Create `~/.mcp_secrets`:
```bash
# ~/.mcp_secrets
export META_ACCESS_TOKEN="your_token_here"
export META_AD_ACCOUNT_ID="act_123456"
export STRIPE_API_KEY="sk_live_xyz"
```

Secure it:
```bash
chmod 600 ~/.mcp_secrets
```

Load in shell profile (`~/.zshrc` or `~/.bashrc`):
```bash
# Load MCP secrets
if [ -f ~/.mcp_secrets ]; then
  source ~/.mcp_secrets
fi
```

Reload:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### Step 2: Install in Claude Code

```bash
# Source secrets
source ~/.mcp_secrets

# Install with actual values (Claude Code stores them securely)
claude mcp add --transport stdio meta-ads \
  --scope user \
  --env META_ACCESS_TOKEN=${META_ACCESS_TOKEN} \
  --env META_AD_ACCOUNT_ID=${META_AD_ACCOUNT_ID} \
  -- uv --directory ~/Developer/mcp/meta-ads-mcp run python -m src.server
```

**Note:** When using `claude mcp add`, you pass actual values. Claude Code stores them securely in `~/.claude/.claude.json` and references them correctly.

### Step 3: Configure Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "meta-ads": {
      "command": "/Users/username/.local/bin/uv",
      "args": ["--directory", "/Users/username/Developer/mcp/meta-ads-mcp", "run", "python", "-m", "src.server"],
      "cwd": "/Users/username/Developer/mcp/meta-ads-mcp",
      "env": {
        "META_ACCESS_TOKEN": "${META_ACCESS_TOKEN}",
        "META_AD_ACCOUNT_ID": "${META_AD_ACCOUNT_ID}"
      }
    }
  }
}
```

**CRITICAL:** Use variable expansion (`${VAR}`), never hardcode values.

### Step 4: Verify Installation

```bash
# Check Claude Code
claude mcp list

# Test environment variables
echo $META_ACCESS_TOKEN  # Should show value
```

Restart Claude Desktop and test.

## Complete Examples

### Example 1: Stripe MCP Server

**1. Add to `~/.mcp_secrets`:**
```bash
export STRIPE_API_KEY="sk_live_abc123"
```

**2. Install in Claude Code:**
```bash
source ~/.mcp_secrets
claude mcp add --transport stdio stripe \
  --scope user \
  --env STRIPE_API_KEY=${STRIPE_API_KEY} \
  -- uv --directory ~/Developer/mcp/stripe-mcp run python -m src.server
```

**3. Configure Claude Desktop:**
```json
{
  "mcpServers": {
    "stripe": {
      "command": "/Users/username/.local/bin/uv",
      "args": ["--directory", "/Users/username/Developer/mcp/stripe-mcp", "run", "python", "-m", "src.server"],
      "cwd": "/Users/username/Developer/mcp/stripe-mcp",
      "env": {
        "STRIPE_API_KEY": "${STRIPE_API_KEY}"
      }
    }
  }
}
```

### Example 2: Multi-Profile Server (GoHighLevel)

**1. Add to `~/.mcp_secrets`:**
```bash
export GHL_MAIN_API_TOKEN="pit_main_abc"
export GHL_MAIN_LOCATION_ID="loc_main_123"
export GHL_CLIENT_API_TOKEN="pit_client_xyz"
export GHL_CLIENT_LOCATION_ID="loc_client_456"
```

**2. Install in Claude Code:**
```bash
source ~/.mcp_secrets
claude mcp add --transport stdio ghl \
  --scope user \
  --env GHL_MAIN_API_TOKEN=${GHL_MAIN_API_TOKEN} \
  --env GHL_MAIN_LOCATION_ID=${GHL_MAIN_LOCATION_ID} \
  --env GHL_CLIENT_API_TOKEN=${GHL_CLIENT_API_TOKEN} \
  --env GHL_CLIENT_LOCATION_ID=${GHL_CLIENT_LOCATION_ID} \
  -- uv --directory ~/Developer/mcp/ghl-mcp run python -m src.server
```

**3. Configure Claude Desktop:**
```json
{
  "mcpServers": {
    "ghl": {
      "command": "/Users/username/.local/bin/uv",
      "args": ["--directory", "/Users/username/Developer/mcp/ghl-mcp", "run", "python", "-m", "src.server"],
      "cwd": "/Users/username/Developer/mcp/ghl-mcp",
      "env": {
        "GHL_MAIN_API_TOKEN": "${GHL_MAIN_API_TOKEN}",
        "GHL_MAIN_LOCATION_ID": "${GHL_MAIN_LOCATION_ID}",
        "GHL_CLIENT_API_TOKEN": "${GHL_CLIENT_API_TOKEN}",
        "GHL_CLIENT_LOCATION_ID": "${GHL_CLIENT_LOCATION_ID}"
      }
    }
  }
}
```

## Credential Management Best Practices

### Use ~/.mcp_secrets

Store all MCP server credentials in `~/.mcp_secrets`:

```bash
# ~/.mcp_secrets
# Meta Ads
export META_MAIN_ACCESS_TOKEN="EAAJxdR0..."
export META_MAIN_AD_ACCOUNT_ID="act_123456789"

# Stripe
export STRIPE_API_KEY="sk_live_..."

# GoHighLevel
export GHL_MAIN_API_TOKEN="pit-..."
export GHL_MAIN_LOCATION_ID="PpE1PIlJ..."

# Zoom
export ZOOM_ACCOUNT_ID="5ZozWfDX..."
export ZOOM_CLIENT_ID="or2VVA9x..."
export ZOOM_CLIENT_SECRET="oRO3NKXX..."
```

Secure it:
```bash
chmod 600 ~/.mcp_secrets
```

Load in shell profile:
```bash
# Add to ~/.zshrc or ~/.bashrc
if [ -f ~/.mcp_secrets ]; then
  source ~/.mcp_secrets
fi
```

### Security Checklist

- [ ] `~/.mcp_secrets` has `chmod 600` permissions
- [ ] All configs use `${VAR}` variable expansion
- [ ] `.env` files are in `.gitignore`
- [ ] Pre-commit hook installed to catch secrets
- [ ] Never commit actual credential values
- [ ] Rotate credentials if accidentally exposed

## Verification

### Check Claude Code Installation
```bash
# List all installed servers
claude mcp list

# Get specific server details
claude mcp get meta-ads

# Remove if needed
claude mcp remove meta-ads
```

### Check Claude Desktop Configuration

```bash
# View all servers
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq '.mcpServers'

# Check specific server
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq '.mcpServers["meta-ads"]'

# Verify cwd property is set
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq '.mcpServers["meta-ads"].cwd'

# Verify env uses variable expansion
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq '.mcpServers["meta-ads"].env'
```

Ensure configs show `${VAR}` syntax, not actual values.

### Test in Conversation

**Claude Code:**
- Open any project
- Ask: "List available MCP servers"
- Ask: "What Meta Ads operations are available?"

**Claude Desktop:**
- Restart the app
- Ask: "List available MCP servers"
- Ask: "What Meta Ads operations are available?"

## Workflow Integration

When creating MCP servers, include installation in your development process:

### Final Installation Steps

1. **Add credentials to `~/.mcp_secrets`**
2. **Install in Claude Code** using `claude mcp add` with actual values
3. **Configure Claude Desktop** with variable expansion (`${VAR}`)
4. **Verify with security checklist**
5. **Test in both environments**

This ensures secure, consistent installation across all clients.

## Troubleshooting

**"Command not found: claude"**
- Install Claude Code CLI: Open Claude Code → run `/install-cli`

**"jq: command not found"**
```bash
brew install jq  # macOS
```

**"Server not appearing in Claude Code"**
```bash
# Check installation
claude mcp list

# Try removing and reinstalling
claude mcp remove <server-name>
~/.claude/scripts/install-mcp.sh ...
```

**"Server not appearing in Claude Desktop"**
- Verify JSON syntax: `jq '.' ~/Library/Application\ Support/Claude/claude_desktop_config.json`
- Check backup file if config is corrupted
- Restart Claude Desktop

**"Environment variable not found"**
- Check `~/.claude/.env` exists
- Verify variable names match exactly
- Ensure no extra spaces: `KEY=value` not `KEY = value`

## TypeScript/Node Servers

### Installation Pattern

**Claude Code:**
```bash
claude mcp add --transport stdio my-ts-server \
  --scope user \
  --env API_KEY=${API_KEY} \
  -- node ~/Developer/mcp/my-ts-server/dist/index.js
```

**Claude Desktop:**
```json
{
  "mcpServers": {
    "my-ts-server": {
      "command": "/usr/local/bin/node",
      "args": ["/Users/username/Developer/mcp/my-ts-server/dist/index.js"],
      "cwd": "/Users/username/Developer/mcp/my-ts-server",
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

**Note:** TypeScript servers have natural isolation through `node_modules/`.

## Advanced: HTTP/SSE Servers

For remote servers:

```bash
# HTTP server
claude mcp add --transport http my-server https://api.example.com/mcp

# SSE server with headers
claude mcp add --transport sse my-server \
  --header "Authorization: Bearer $API_TOKEN" \
  https://mcp.example.com/sse
```

## Security Best Practices Summary

### Critical Security Rules

1. **Never hardcode credentials** - Always use `${VAR}` variable expansion
2. **Secure credential files** - `chmod 600 ~/.mcp_secrets`
3. **Use `.gitignore`** - Never commit `.env`, `.env.local`, `*.key`, `secrets.json`
4. **Variable expansion everywhere** - Claude Desktop configs must use `${VAR}`
5. **Token rotation** - Update `~/.mcp_secrets`, restart clients
6. **Pre-commit hooks** - Install to catch accidental commits
7. **Always include `cwd`** - Set working directory in all configs
8. **Absolute paths** - Command, args, cwd must all be absolute
9. **User scope for secrets** - Keep credentials out of project configs
10. **Validate before deploy** - Run security checklist

### What Good Looks Like

**✅ Secure Configuration:**
```json
{
  "command": "/Users/username/.local/bin/uv",
  "args": ["--directory", "/Users/username/Developer/mcp/my-server", "run", "python", "-m", "src.server"],
  "cwd": "/Users/username/Developer/mcp/my-server",
  "env": {
    "API_KEY": "${API_KEY}",
    "DB_URL": "${DB_URL:-postgres://localhost/mydb}"
  }
}
```

**❌ Insecure Configuration:**
```json
{
  "command": "uv",
  "args": ["--directory", "./my-server", "run", "python", "-m", "src.server"],
  "env": {
    "API_KEY": "sk_live_abc123"
  }
}
```

Issues: Relative command path, relative directory, hardcoded secret, no `cwd` property.

# Automated MCP Server Creation Workflow

<overview>
This workflow creates a complete, working MCP server from scratch with zero manual configuration. Use this when Lex wants to build a new MCP server - it handles everything automatically.

**End state**: Server running in both Claude Code and Claude Desktop with all credentials configured.
</overview>

<workflow>

## Task Progress Checklist

Copy this and check off items as you complete them:

```
- [ ] Step 1: Gather requirements
- [ ] Step 2: Create project structure
- [ ] Step 3: Generate server code
- [ ] Step 4: Configure environment variables
- [ ] Step 5: Install in Claude Code
- [ ] Step 6: Install in Claude Desktop
- [ ] Step 7: Test and verify
```

---

## Step 1: Gather Requirements

Use AskUserQuestion to collect all information upfront:

```xml
<questions>
  <question>
    <header>Server Name</header>
    <question>What should this MCP server be called? (lowercase-with-hyphens)</question>
    <options>
      <option>
        <label>Suggest based on purpose</label>
        <description>I'll suggest a name after you describe what it does</description>
      </option>
      <option>
        <label>I have a name</label>
        <description>I know exactly what to call it</description>
      </option>
    </options>
    <multiSelect>false</multiSelect>
  </question>

  <question>
    <header>Language</header>
    <question>Which language should I use?</question>
    <options>
      <option>
        <label>Python</label>
        <description>Recommended for API integrations, data processing, most use cases</description>
      </option>
      <option>
        <label>TypeScript</label>
        <description>Better for Node.js integrations, when you need strict typing</description>
      </option>
    </options>
    <multiSelect>false</multiSelect>
  </question>

  <question>
    <header>Purpose</header>
    <question>What should this server do? What capabilities will it provide?</question>
    <options>
      <option>
        <label>API Integration</label>
        <description>Connect to external APIs (Stripe, Airtable, etc.)</description>
      </option>
      <option>
        <label>File Operations</label>
        <description>Read, write, process files on the filesystem</description>
      </option>
      <option>
        <label>Database Access</label>
        <description>Query and manage database records</description>
      </option>
      <option>
        <label>Custom Tools</label>
        <description>Specialized functions/calculations</description>
      </option>
    </options>
    <multiSelect>true</multiSelect>
  </question>

  <question>
    <header>Credentials</header>
    <question>What environment variables/API keys does this server need?</question>
    <options>
      <option>
        <label>API Keys</label>
        <description>External service API keys</description>
      </option>
      <option>
        <label>Database URL</label>
        <description>Database connection string</description>
      </option>
      <option>
        <label>None</label>
        <description>No credentials needed</description>
      </option>
    </options>
    <multiSelect>true</multiSelect>
  </question>
</questions>
```

**After gathering requirements:**
- If server name wasn't provided, suggest one based on purpose
- Confirm the name: `{purpose}-mcp` (e.g., "stripe-mcp", "notion-mcp")
- List out all environment variables that will be needed
- **Determine architecture based on operation count:**
  - **1-2 operations:** Traditional architecture (flat tools)
  - **3+ operations:** On-demand discovery architecture (meta-tools + resources)
  - Explain: "I'll use on-demand discovery to minimize context usage - this means only loading operation schemas when needed instead of all upfront."

---

## Step 2: Create Project Structure

Execute these commands to set up the project:

**For Python:**
```bash
# Create directory
mkdir -p ~/Developer/mcp/{server-name}/src
cd ~/Developer/mcp/{server-name}

# Initialize project
uv init

# Add dependencies
uv add mcp

# If API integration, add requests
uv add httpx

# Create .gitignore
cat > .gitignore << 'EOF'
.env
.venv/
__pycache__/
*.pyc
.DS_Store
EOF

# Create README template
cat > README.md << 'EOF'
# {Server Name} MCP Server

## Description
{What this server does}

## Setup
1. Install: `uv sync`
2. Configure environment variables in ~/.zshrc
3. Run: `uv run python -m src.server`

## Environment Variables
{List of required env vars}
EOF
```

**For TypeScript:**
```bash
# Create directory
mkdir -p ~/Developer/mcp/{server-name}/src
cd ~/Developer/mcp/{server-name}

# Initialize npm project
npm init -y

# Add dependencies
npm install @modelcontextprotocol/sdk

# If API integration
npm install axios

# Create tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "./build",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true
  }
}
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
.env
node_modules/
build/
.DS_Store
EOF

# Create README
cat > README.md << 'EOF'
# {Server Name} MCP Server

## Description
{What this server does}

## Setup
1. Install: `npm install`
2. Build: `npm run build`
3. Configure environment variables in ~/.zshrc
4. Run: `node build/index.js`

## Environment Variables
{List of required env vars}
EOF
```

**Verify structure created:**
```bash
ls -la ~/Developer/mcp/{server-name}/
```

---

## Step 3: Generate Server Code

Write the server implementation based on requirements and chosen architecture.

### Architecture Decision

**If 1-2 operations:** Use traditional template below
**If 3+ operations:** Use on-demand discovery template (see [references/large-api-pattern.md](large-api-pattern.md) for complete implementation)

---

### Traditional Architecture Template (1-2 Operations)

**Python Template (API Integration):**

```python
# src/server.py
import os
import sys
from typing import Any
import httpx
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Configuration
API_KEY = os.getenv("{ENV_VAR_NAME}")
if not API_KEY:
    print("ERROR: {ENV_VAR_NAME} environment variable not set", file=sys.stderr)
    sys.exit(1)

BASE_URL = "{api_base_url}"

app = Server("{server-name}")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools."""
    return [
        Tool(
            name="{tool_name}",
            description="{What this tool does}",
            inputSchema={
                "type": "object",
                "properties": {
                    "{param_name}": {
                        "type": "string",
                        "description": "{Parameter description}"
                    }
                },
                "required": ["{param_name}"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute a tool."""
    try:
        if name == "{tool_name}":
            param = arguments["{param_name}"]

            # Make API request
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{BASE_URL}/{endpoint}",
                    headers={"Authorization": f"Bearer {API_KEY}"},
                    params={"param": param}
                )
                response.raise_for_status()
                data = response.json()

            return [TextContent(
                type="text",
                text=f"Result: {data}"
            )]

        raise ValueError(f"Unknown tool: {name}")

    except Exception as e:
        print(f"Error in {name}: {e}", file=sys.stderr)
        return [TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]

async def main():
    """Run the MCP server."""
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

**TypeScript Template (API Integration):**

```typescript
// src/index.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import axios from "axios";

const API_KEY = process.env.{ENV_VAR_NAME};
if (!API_KEY) {
  console.error("ERROR: {ENV_VAR_NAME} environment variable not set");
  process.exit(1);
}

const BASE_URL = "{api_base_url}";

const server = new Server(
  { name: "{server-name}", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler("tools/list", async () => ({
  tools: [
    {
      name: "{tool_name}",
      description: "{What this tool does}",
      inputSchema: {
        type: "object",
        properties: {
          {param_name}: {
            type: "string",
            description: "{Parameter description}"
          }
        },
        required: ["{param_name}"]
      }
    }
  ]
}));

server.setRequestHandler("tools/call", async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === "{tool_name}") {
      const param = args.{param_name};

      const response = await axios.get(`${BASE_URL}/{endpoint}`, {
        headers: { Authorization: `Bearer ${API_KEY}` },
        params: { param }
      });

      return {
        content: [
          {
            type: "text",
            text: `Result: ${JSON.stringify(response.data)}`
          }
        ]
      };
    }

    throw new Error(`Unknown tool: ${name}`);
  } catch (error) {
    console.error(`Error in ${name}:`, error);
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`
        }
      ]
    };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

**Customize the template:**
- Replace `{server-name}`, `{tool_name}`, `{ENV_VAR_NAME}` with actual values
- Add multiple tools if needed
- Implement specific API logic based on requirements
- Add proper error handling for the specific API

---

### On-Demand Discovery Architecture (3+ Operations)

**Why:** Minimizes context usage by loading operation schemas only when needed.

**Implementation:** Follow the complete guide in [references/large-api-pattern.md](large-api-pattern.md) which includes:

1. **4 Meta-Tools Pattern:**
   - `discover` - Browse available operations
   - `get_schema` - Get parameters for one operation
   - `execute` - Run an operation
   - `continue` - Handle pagination

2. **Operations JSON File:** All operation definitions in `operations.json` (not hardcoded in Python)

3. **MCP Resources:** Operations exposed as resources with URIs like `{server}://operations/{category}/{action}`

4. **Smart Dispatch:** Maps operation strings to actual implementations

**Quick reference for on-demand architecture:**
```python
# The 4 meta-tools handle everything
@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(name="discover", ...),
        Tool(name="get_schema", ...),
        Tool(name="execute", ...),
        Tool(name="continue", ...)
    ]

# Operations stored as MCP resources
@app.list_resources()
async def list_resources() -> list[Resource]:
    # Load from operations.json
    # Expose as resources
```

**See large-api-pattern.md for:**
- Complete Python implementation
- TypeScript implementation
- Operations JSON schema
- Dispatch layer implementation
- Testing and debugging

---

### Write the Generated Code

```bash
# For Python
cat > ~/Developer/mcp/{server-name}/src/server.py << 'EOF'
{generated code}
EOF

# For TypeScript (then build)
cat > ~/Developer/mcp/{server-name}/src/index.ts << 'EOF'
{generated code}
EOF
npm run build
```

---

## Step 4: Configure Environment Variables

**SECURITY CRITICAL:** NEVER ask Lex to paste secrets into chat. Secrets must never go through Anthropic's servers or appear in conversation history.

### Provide Exact Commands

For each required environment variable, give Lex the exact commands to run in his terminal.

**Step 4.1: Show required variables and where to get them**

Present to Lex:
```
📋 Required Environment Variables:

{ENV_VAR_NAME_1} - {Description}
  Get it from: {URL or instructions}

{ENV_VAR_NAME_2} - {Description}
  Get it from: {URL or instructions}
```

**Step 4.2: Give exact commands to add to ~/.zshrc**

```
Run these commands in your terminal:

# Add {Server Name} credentials
cat >> ~/.zshrc << 'EOF'

# {Server Name} MCP Server
export {ENV_VAR_NAME_1}="your-value-here"
export {ENV_VAR_NAME_2}="your-value-here"
EOF

# Reload shell
source ~/.zshrc
```

**Step 4.3: Wait for confirmation**

Ask using AskUserQuestion:
```xml
<question>
  <header>Environment Setup</header>
  <question>Have you added the environment variables to ~/.zshrc?</question>
  <options>
    <option>
      <label>Yes, added and sourced</label>
      <description>Variables are ready</description>
    </option>
    <option>
      <label>Skip for now</label>
      <description>I'll add them later</description>
    </option>
  </options>
  <multiSelect>false</multiSelect>
</question>
```

**Step 4.4: Verify variables exist (without showing values)**

```bash
# Check each variable is set (without printing values)
for var in {ENV_VAR_1} {ENV_VAR_2}; do
  if [ -z "${!var}" ]; then
    echo "✗ $var not set - please add to ~/.zshrc and run: source ~/.zshrc"
  else
    echo "✓ $var is set"
  fi
done
```

**Important notes:**
- Variables are checked for existence only (not values)
- Values never appear in conversation or output
- If variables aren't set, stop and wait for Lex to add them

---

## Step 5: Install in Claude Code

```bash
# Get absolute path to uv (for Python) or node (for TypeScript)
UV_PATH=$(which uv)
NODE_PATH=$(which node)

# Build environment flags
ENV_FLAGS=""
for var in {ENV_VAR1} {ENV_VAR2}; do
  ENV_FLAGS+="--env $var=\${$var} "
done

# Install based on language
if [ "{language}" = "Python" ]; then
  claude mcp add --transport stdio {server-name} \
    $ENV_FLAGS \
    -- uv --directory ~/Developer/mcp/{server-name} run python -m src.server
else
  claude mcp add --transport stdio {server-name} \
    $ENV_FLAGS \
    -- node ~/Developer/mcp/{server-name}/build/index.js
fi

# Verify installation
claude mcp list | grep {server-name}
```

**Expected output:**
```
{server-name}: ... - ✓ Connected
```

---

## Step 6: Install in Claude Desktop

```bash
# Get paths
UV_PATH=$(which uv)
NODE_PATH=$(which node)
DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# Backup config
cp "$DESKTOP_CONFIG" "$DESKTOP_CONFIG.backup.$(date +%s)"

# Create server config based on language
if [ "{language}" = "Python" ]; then
  SERVER_CONFIG=$(cat <<EOF
{
  "command": "$UV_PATH",
  "args": ["--directory", "$HOME/Developer/mcp/{server-name}", "run", "python", "-m", "src.server"],
  "env": {
    {env_json}
  }
}
EOF
)
else
  SERVER_CONFIG=$(cat <<EOF
{
  "command": "$NODE_PATH",
  "args": ["$HOME/Developer/mcp/{server-name}/build/index.js"],
  "env": {
    {env_json}
  }
}
EOF
)
fi

# Add to config using jq
jq --arg name "{server-name}" \
   --argjson config "$SERVER_CONFIG" \
   '.mcpServers[$name] = $config' \
   "$DESKTOP_CONFIG" > "$DESKTOP_CONFIG.tmp"

mv "$DESKTOP_CONFIG.tmp" "$DESKTOP_CONFIG"

echo "✓ Installed in Claude Desktop"
echo "⚠️  IMPORTANT: Restart Claude Desktop for changes to take effect"
```

**Generate env_json from environment variables:**
```bash
# For each env var, create JSON entry
{
  "ENV_VAR1": "${ENV_VAR1}",
  "ENV_VAR2": "${ENV_VAR2}"
}
```

---

## Step 7: Test and Verify

**Test the server standalone:**
```bash
cd ~/Developer/mcp/{server-name}

# For Python
uv run python -m src.server

# For TypeScript
node build/index.js

# Should wait for input (stdio mode)
# Press Ctrl+C to exit
```

**Verify in Claude Code:**
```bash
# Check server appears
claude mcp list

# Check logs (if there are issues)
tail -50 ~/Library/Logs/Claude/mcp-server-{server-name}.log
```

**Verify in Claude Desktop:**
1. Restart Claude Desktop
2. Open new conversation
3. Try using a tool from the server
4. Check it works

**Final checklist:**
```
- [ ] Server appears in `claude mcp list` with ✓ Connected
- [ ] Environment variables are set in ~/.zshrc
- [ ] Server added to Claude Desktop config
- [ ] Test tool call succeeds
- [ ] No errors in logs
```

</workflow>

<validation>

## Validation After Each Step

**Step 2 validation:**
```bash
# Verify directory exists
test -d ~/Developer/mcp/{server-name} && echo "✓ Directory created" || echo "✗ Directory missing"

# Verify files exist
test -f ~/Developer/mcp/{server-name}/pyproject.toml && echo "✓ Project initialized" || echo "✗ Project not initialized"
```

**Step 3 validation:**
```bash
# Verify server file exists
test -f ~/Developer/mcp/{server-name}/src/server.py && echo "✓ Server code created" || echo "✗ Server code missing"

# For Python: Check syntax
cd ~/Developer/mcp/{server-name}
python -m py_compile src/server.py && echo "✓ Syntax valid" || echo "✗ Syntax error"

# For TypeScript: Check build
npm run build && echo "✓ Build successful" || echo "✗ Build failed"
```

**Step 4 validation:**
```bash
# Verify env vars are set
for var in {ENV_VAR1} {ENV_VAR2}; do
  if [ -z "${!var}" ]; then
    echo "✗ $var not set"
  else
    echo "✓ $var set"
  fi
done
```

**Step 5 validation:**
```bash
# Check Claude Code installation
claude mcp list | grep -q "{server-name}" && echo "✓ Installed in Claude Code" || echo "✗ Not installed"
```

**Step 6 validation:**
```bash
# Check Claude Desktop config
jq '.mcpServers | has("{server-name}")' "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
# Should output: true
```

**Step 7 validation:**
```bash
# Check server health
claude mcp list | grep "{server-name}"
# Should show: ✓ Connected
```

</validation>

<troubleshooting>

## Common Issues During Creation

**"uv: command not found":**
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Reload shell
source ~/.zshrc
```

**"Environment variable not set":**
```bash
# Check if in ~/.zshrc
grep "ENV_VAR_NAME" ~/.zshrc

# If missing, add manually
echo 'export ENV_VAR_NAME="value"' >> ~/.zshrc
source ~/.zshrc
```

**"Server not appearing in Claude Code":**
```bash
# Check installation
claude mcp list

# Check logs
tail -50 ~/Library/Logs/Claude/mcp-server-{server-name}.log

# Reinstall
claude mcp remove {server-name}
# Then repeat Step 5
```

**"jq: command not found":**
```bash
# Install jq
brew install jq
```

**"Syntax error in server code":**
```bash
# For Python
cd ~/Developer/mcp/{server-name}
python -m py_compile src/server.py
# Fix errors shown

# For TypeScript
npm run build
# Fix TypeScript errors shown
```

</troubleshooting>

<notes>

## Important Notes

**Always use absolute paths:**
- Find with: `which uv`, `which node`
- Claude Desktop requires absolute paths

**Environment variable security:**
- Never hardcode secrets in code
- Always use `${VAR}` expansion in configs
- Store in ~/.zshrc for persistence

**Testing first:**
- Always test standalone before installing
- Check logs if server doesn't connect
- Verify env vars are actually set

**Backup before modifying:**
- Claude Desktop config is backed up automatically
- Can restore with: `cp claude_desktop_config.json.backup.<timestamp> claude_desktop_config.json`

</notes>

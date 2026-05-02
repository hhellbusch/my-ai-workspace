# Traditional MCP Server Pattern (1-2 Operations)

<overview>
For simple MCP servers with 1-2 operations, use the traditional flat tools pattern. This is simpler than on-demand discovery and has negligible context overhead.

**Use when:**
- 1-2 distinct operations total
- All operations will be used in most conversations
- Simplicity is more important than context optimization
</overview>

## Architecture

<structure>
Traditional MCP servers expose each operation as a distinct tool:

```python
@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(name="operation_1", description="...", inputSchema={...}),
        Tool(name="operation_2", description="...", inputSchema={...})
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "operation_1":
        # Implementation
    elif name == "operation_2":
        # Implementation
```

**Context overhead:** ~150-300 tokens per operation (negligible for 1-2 operations)
</structure>

## Python Template

<python_api_integration>
### API Integration Server

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
API_KEY = os.getenv("YOUR_API_KEY")
if not API_KEY:
    print("ERROR: YOUR_API_KEY environment variable not set", file=sys.stderr)
    sys.exit(1)

BASE_URL = "https://api.example.com"

app = Server("your-server-name")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools."""
    return [
        Tool(
            name="your_operation_name",
            description="What this operation does",
            inputSchema={
                "type": "object",
                "properties": {
                    "param_name": {
                        "type": "string",
                        "description": "Parameter description"
                    }
                },
                "required": ["param_name"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Execute a tool."""
    try:
        if name == "your_operation_name":
            param = arguments["param_name"]

            # Make API request
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{BASE_URL}/endpoint",
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
</python_api_integration>

<python_file_operations>
### File Operations Server

```python
# src/server.py
import os
from pathlib import Path
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

app = Server("file-processor")

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="read_json",
            description="Read and parse a JSON file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to JSON file"
                    }
                },
                "required": ["path"]
            }
        ),
        Tool(
            name="write_json",
            description="Write data to a JSON file",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string"},
                    "data": {"type": "object"}
                },
                "required": ["path", "data"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    try:
        if name == "read_json":
            import json
            path = Path(arguments["path"]).expanduser()
            with open(path) as f:
                data = json.load(f)
            return [TextContent(
                type="text",
                text=json.dumps(data, indent=2)
            )]

        elif name == "write_json":
            import json
            path = Path(arguments["path"]).expanduser()
            with open(path, "w") as f:
                json.dump(arguments["data"], f, indent=2)
            return [TextContent(
                type="text",
                text=f"Wrote data to {path}"
            )]

        raise ValueError(f"Unknown tool: {name}")

    except Exception as e:
        return [TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]

async def main():
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
</python_file_operations>

<python_custom_tools>
### Custom Tools Server

```python
# src/server.py
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

app = Server("calculator")

@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="calculate",
            description="Perform mathematical calculation",
            inputSchema={
                "type": "object",
                "properties": {
                    "expression": {
                        "type": "string",
                        "description": "Mathematical expression to evaluate"
                    }
                },
                "required": ["expression"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    try:
        if name == "calculate":
            # Safe evaluation (limited to math operations)
            import ast
            import operator

            operators = {
                ast.Add: operator.add,
                ast.Sub: operator.sub,
                ast.Mult: operator.mul,
                ast.Div: operator.truediv,
                ast.Pow: operator.pow
            }

            def eval_expr(node):
                if isinstance(node, ast.Num):
                    return node.n
                elif isinstance(node, ast.BinOp):
                    return operators[type(node.op)](
                        eval_expr(node.left),
                        eval_expr(node.right)
                    )
                raise ValueError("Unsupported operation")

            expr = arguments["expression"]
            tree = ast.parse(expr, mode='eval')
            result = eval_expr(tree.body)

            return [TextContent(
                type="text",
                text=f"{expr} = {result}"
            )]

        raise ValueError(f"Unknown tool: {name}")

    except Exception as e:
        return [TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]

async def main():
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
</python_custom_tools>

## TypeScript Template

<typescript_api_integration>
### API Integration Server

```typescript
// src/index.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import axios from "axios";

const API_KEY = process.env.YOUR_API_KEY;
if (!API_KEY) {
  console.error("ERROR: YOUR_API_KEY environment variable not set");
  process.exit(1);
}

const BASE_URL = "https://api.example.com";

const server = new Server(
  { name: "your-server-name", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler("tools/list", async () => ({
  tools: [
    {
      name: "your_operation_name",
      description: "What this operation does",
      inputSchema: {
        type: "object",
        properties: {
          param_name: {
            type: "string",
            description: "Parameter description"
          }
        },
        required: ["param_name"]
      }
    }
  ]
}));

server.setRequestHandler("tools/call", async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === "your_operation_name") {
      const param = args.param_name;

      const response = await axios.get(`${BASE_URL}/endpoint`, {
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
</typescript_api_integration>

## Adding Multiple Operations

<multiple_operations>
For 2 operations, simply add more tools:

```python
@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(name="operation_1", ...),
        Tool(name="operation_2", ...)
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "operation_1":
        # Implementation 1
    elif name == "operation_2":
        # Implementation 2
```

**Threshold:** If you find yourself adding a 3rd operation, consider switching to on-demand discovery pattern (see [large-api-pattern.md](large-api-pattern.md)).
</multiple_operations>

## Error Handling

<error_handling_pattern>
Always return errors as TextContent, never raise exceptions to Claude:

```python
@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    try:
        # Your implementation
        return [TextContent(type="text", text=result)]
    except Exception as e:
        # Log to stderr for debugging
        print(f"Error in {name}: {e}", file=sys.stderr)

        # Return error to Claude
        return [TextContent(
            type="text",
            text=f"Error: {str(e)}"
        )]
```
</error_handling_pattern>

## Testing

<testing_pattern>
Test standalone before installing:

```bash
cd ~/Developer/mcp/your-server

# Python
uv run python -m src.server
# Should wait for stdin (stdio mode), press Ctrl+C to exit

# TypeScript
node build/index.js
# Should wait for stdin (stdio mode), press Ctrl+C to exit
```

If the server waits for input, it's working correctly.
</testing_pattern>

## When to Migrate

<migration_threshold>
If your server grows to 3+ operations:

1. Read [large-api-pattern.md](large-api-pattern.md)
2. Refactor to on-demand discovery architecture
3. Context savings become significant at this scale (90-98% reduction)

**Signs you need on-demand discovery:**
- Adding 3rd+ operation
- Context overhead > 500 tokens
- Not all operations used per conversation
- Operations group into logical categories
</migration_threshold>

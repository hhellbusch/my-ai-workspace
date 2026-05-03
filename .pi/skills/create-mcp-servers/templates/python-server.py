"""
MCP Server Template - Python (Traditional Pattern)

Use this template for servers with 1-2 operations.
For 3+ operations, use the on-demand discovery pattern instead.

Replace:
- {SERVER_NAME}: Your server name (e.g., "my-api")
- {TOOL_NAME}: Tool name (e.g., "search_items")
- {TOOL_DESCRIPTION}: What the tool does
- {API_CLIENT}: Your API client initialization
"""

import asyncio
import logging
import os
from contextlib import redirect_stdout, redirect_stderr
from io import StringIO
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Configure logging to file (never stdout/stderr for MCP)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.FileHandler(os.path.expanduser(f"~/Library/Logs/Claude/mcp-server-{SERVER_NAME}.log"))]
)
logger = logging.getLogger("{SERVER_NAME}")

app = Server("{SERVER_NAME}")

# =============================================================================
# API Client Setup
# =============================================================================

def get_client():
    """Initialize API client. Add OAuth stdio isolation if needed."""
    api_key = os.environ.get("{API_KEY_VAR}")
    if not api_key:
        raise ValueError("{API_KEY_VAR} environment variable not set")

    # Initialize your client here
    # return YourAPIClient(api_key)
    pass


# =============================================================================
# Tool Definitions
# =============================================================================

@app.list_tools()
async def list_tools() -> list[Tool]:
    """Return available tools."""
    return [
        Tool(
            name="{tool_name}",
            description="{TOOL_DESCRIPTION}",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query"
                    }
                },
                "required": ["query"]
            }
        ),
        # Add more tools here for 1-2 operation servers
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls."""
    logger.info(f"Tool called: {name} with args: {arguments}")

    try:
        if name == "{tool_name}":
            result = await handle_{tool_name}(arguments)
        else:
            raise ValueError(f"Unknown tool: {name}")

        return [TextContent(type="text", text=str(result))]

    except Exception as e:
        logger.error(f"Error in {name}: {e}")
        return [TextContent(type="text", text=f"Error: {str(e)}")]


# =============================================================================
# Tool Handlers
# =============================================================================

async def handle_{tool_name}(args: dict[str, Any]) -> dict:
    """Handle {tool_name} tool."""
    query = args.get("query")

    # Implement your logic here
    # client = get_client()
    # result = client.search(query)

    return {"status": "success", "query": query}


# =============================================================================
# OAuth Stdio Isolation (if needed)
# =============================================================================

class StdioIsolation:
    """Context manager to isolate stdout/stderr during OAuth operations."""

    def __enter__(self):
        self._stdout = StringIO()
        self._stderr = StringIO()
        self._redirect_stdout = redirect_stdout(self._stdout)
        self._redirect_stderr = redirect_stderr(self._stderr)
        self._redirect_stdout.__enter__()
        self._redirect_stderr.__enter__()
        return self

    def __exit__(self, *args):
        self._redirect_stdout.__exit__(*args)
        self._redirect_stderr.__exit__(*args)
        # Log captured output instead of printing
        stdout_content = self._stdout.getvalue()
        stderr_content = self._stderr.getvalue()
        if stdout_content:
            logger.debug(f"Captured stdout: {stdout_content}")
        if stderr_content:
            logger.debug(f"Captured stderr: {stderr_content}")


# =============================================================================
# Main Entry Point
# =============================================================================

async def main():
    """Run the MCP server."""
    logger.info("Starting {SERVER_NAME} MCP server")
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())

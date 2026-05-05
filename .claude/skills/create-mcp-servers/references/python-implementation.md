# Python MCP Server Implementation

<overview>
Python implementation using the mcp package provides clean async/await patterns, decorator-based APIs, and strong type hints. This guide covers Python-specific features and best practices.
</overview>

## Project Setup

<dependencies>
```toml
# pyproject.toml
[project]
name = "my-mcp-server"
version = "1.0.0"
dependencies = [
    "mcp>=0.1.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-asyncio>=0.21.0",
    "mypy>=1.0.0",
]

[project.scripts]
my-mcp-server = "my_mcp_server.server:main"

# Or using setup.py/requirements.txt:
# mcp>=0.1.0
# pydantic>=2.0.0
```
</dependencies>

<directory_structure>
```
my_mcp_server/
├── __init__.py
├── server.py          # Main server implementation
├── tools/             # Tool implementations
│   ├── __init__.py
│   ├── calculator.py
│   └── api_client.py
├── resources/         # Resource handlers
│   ├── __init__.py
│   └── file_system.py
└── config.py          # Configuration
```
</directory_structure>

## Server Structure

<full_example>
```python
"""MCP Server implementation."""
import asyncio
import sys
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
    Resource,
    Prompt,
    PromptMessage,
    GetPromptResult,
)
from pydantic import BaseModel, Field

# Server instance
app = Server("my-mcp-server")

# Type-safe argument models using Pydantic
class AddNumbersArgs(BaseModel):
    """Arguments for add_numbers tool."""
    a: float = Field(description="First number")
    b: float = Field(description="Second number")

class SearchArgs(BaseModel):
    """Arguments for search tool."""
    query: str = Field(min_length=1, max_length=500, description="Search query")
    limit: int = Field(default=10, ge=1, le=100, description="Maximum results")
    filters: list[str] | None = Field(default=None, description="Optional filters")

# Tool handlers
@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools."""
    return [
        Tool(
            name="add_numbers",
            description="Add two numbers together",
            inputSchema=AddNumbersArgs.model_json_schema(),
        ),
        Tool(
            name="search",
            description="Search for items",
            inputSchema=SearchArgs.model_json_schema(),
        ),
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls."""
    if name == "add_numbers":
        args = AddNumbersArgs(**arguments)
        result = args.a + args.b
        return [TextContent(
            type="text",
            text=f"{args.a} + {args.b} = {result}"
        )]

    elif name == "search":
        args = SearchArgs(**arguments)
        results = await perform_search(args.query, args.limit, args.filters)
        return [TextContent(
            type="text",
            text=f"Found {len(results)} results for '{args.query}'"
        )]

    raise ValueError(f"Unknown tool: {name}")

# Resource handlers
@app.list_resources()
async def list_resources() -> list[Resource]:
    """List available resources."""
    return [
        Resource(
            uri="config://settings",
            name="Server Configuration",
            description="Current server settings",
            mimeType="application/json",
        ),
        Resource(
            uri="file:///{path}",
            name="File System",
            description="Read files from filesystem",
            mimeType="text/plain",
        ),
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read a resource by URI."""
    if uri == "config://settings":
        import json
        config = load_config()
        return json.dumps(config.__dict__, indent=2)

    elif uri.startswith("file:///"):
        path = uri[8:]  # Remove "file:///"
        async with aiofiles.open(path, "r") as f:
            return await f.read()

    raise ValueError(f"Unknown resource: {uri}")

# Prompt handlers
@app.list_prompts()
async def list_prompts() -> list[Prompt]:
    """List available prompts."""
    return [
        Prompt(
            name="code_review",
            description="Review code for best practices",
            arguments=[
                {"name": "language", "description": "Programming language", "required": True},
                {"name": "code", "description": "Code to review", "required": True},
            ],
        ),
    ]

@app.get_prompt()
async def get_prompt(name: str, arguments: dict[str, str] | None) -> GetPromptResult:
    """Get a prompt by name."""
    if name == "code_review":
        language = arguments.get("language", "unknown")
        code = arguments.get("code", "")

        return GetPromptResult(
            description=f"Code review for {language}",
            messages=[
                PromptMessage(
                    role="user",
                    content=TextContent(
                        type="text",
                        text=f"Review this {language} code for best practices:\n\n{code}"
                    ),
                ),
            ],
        )

    raise ValueError(f"Unknown prompt: {name}")

# Helper functions
async def perform_search(query: str, limit: int, filters: list[str] | None) -> list[dict]:
    """Perform search operation."""
    # Implementation here
    return []

def load_config():
    """Load server configuration."""
    from .config import Config
    return Config()

# Main entry point
async def main():
    """Run the MCP server."""
    async with stdio_server() as (read_stream, write_stream):
        # Log to stderr (stdout is for MCP protocol)
        print("my-mcp-server starting...", file=sys.stderr)

        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )

def run():
    """Synchronous entry point for CLI."""
    asyncio.run(main())

if __name__ == "__main__":
    run()
```
</full_example>

## Type-Safe Patterns

<pydantic_models>
**Using Pydantic for Validation**:

```python
from pydantic import BaseModel, Field, field_validator, model_validator
from typing import Annotated

class SearchArgs(BaseModel):
    """Search arguments with validation."""
    query: Annotated[str, Field(min_length=1, max_length=500)]
    limit: Annotated[int, Field(ge=1, le=100)] = 10
    sort_by: str | None = None
    ascending: bool = True

    @field_validator('query')
    @classmethod
    def validate_query(cls, v: str) -> str:
        """Validate search query."""
        if v.strip() != v:
            raise ValueError("Query cannot have leading/trailing whitespace")
        return v

    @model_validator(mode='after')
    def validate_sort(self) -> 'SearchArgs':
        """Validate sort parameters."""
        if self.sort_by and self.sort_by not in ['date', 'relevance', 'title']:
            raise ValueError(f"Invalid sort_by: {self.sort_by}")
        return self

# Use in tool handler
@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    if name == "search":
        try:
            args = SearchArgs(**arguments)
            results = await perform_search(args)
            return [TextContent(type="text", text=str(results))]
        except ValidationError as e:
            # Return validation errors to Claude
            return [TextContent(
                type="text",
                text=f"Invalid arguments: {e}"
            )]

    raise ValueError(f"Unknown tool: {name}")
```
</pydantic_models>

<async_patterns>
**Async/Await Best Practices**:

```python
import asyncio
from typing import Any

# Concurrent operations
async def fetch_multiple_sources(queries: list[str]) -> list[dict]:
    """Fetch from multiple sources concurrently."""
    tasks = [fetch_source(query) for query in queries]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    # Filter out errors
    return [r for r in results if not isinstance(r, Exception)]

async def fetch_source(query: str) -> dict:
    """Fetch from a single source."""
    async with aiohttp.ClientSession() as session:
        async with session.get(f"https://api.example.com/search?q={query}") as response:
            return await response.json()

# Timeout handling
async def tool_with_timeout(args: dict) -> TextContent:
    """Tool with timeout protection."""
    try:
        result = await asyncio.wait_for(
            slow_operation(args),
            timeout=30.0  # 30 second timeout
        )
        return TextContent(type="text", text=result)
    except asyncio.TimeoutError:
        return TextContent(
            type="text",
            text="Operation timed out after 30 seconds"
        )

# Background tasks
class ServerState:
    """Maintain server state."""
    def __init__(self):
        self.cache: dict[str, Any] = {}
        self._cleanup_task: asyncio.Task | None = None

    async def start_cleanup(self):
        """Start background cleanup task."""
        self._cleanup_task = asyncio.create_task(self._cleanup_loop())

    async def _cleanup_loop(self):
        """Periodically clean cache."""
        while True:
            await asyncio.sleep(300)  # Every 5 minutes
            self.cache.clear()
            print("Cache cleaned", file=sys.stderr)

    async def stop(self):
        """Stop background tasks."""
        if self._cleanup_task:
            self._cleanup_task.cancel()
            try:
                await self._cleanup_task
            except asyncio.CancelledError:
                pass

state = ServerState()

async def main():
    """Run server with state management."""
    await state.start_cleanup()

    try:
        async with stdio_server() as (read_stream, write_stream):
            await app.run(
                read_stream,
                write_stream,
                app.create_initialization_options()
            )
    finally:
        await state.stop()
```
</async_patterns>

## Error Handling

<error_patterns>
```python
import sys
import traceback
from typing import Any
from mcp.types import TextContent

class ToolError(Exception):
    """Base exception for tool errors."""
    pass

class InvalidArgumentError(ToolError):
    """Invalid tool arguments."""
    pass

class ExternalAPIError(ToolError):
    """External API call failed."""
    pass

@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls with comprehensive error handling."""
    try:
        # Validate tool exists
        if name not in AVAILABLE_TOOLS:
            raise ToolError(f"Unknown tool: {name}")

        # Execute tool
        result = await execute_tool(name, arguments)
        return [result]

    except InvalidArgumentError as e:
        # Client error - return helpful message
        print(f"Invalid arguments for {name}: {e}", file=sys.stderr)
        return [TextContent(
            type="text",
            text=f"Invalid arguments: {e}\n\nPlease check the tool's input schema."
        )]

    except ExternalAPIError as e:
        # Upstream error - inform user
        print(f"External API error in {name}: {e}", file=sys.stderr)
        return [TextContent(
            type="text",
            text=f"External service error: {e}\n\nPlease try again later."
        )]

    except Exception as e:
        # Unexpected error - log and return generic message
        print(f"Unexpected error in {name}:", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        return [TextContent(
            type="text",
            text=f"An unexpected error occurred. Please contact support."
        )]

async def execute_tool(name: str, arguments: dict[str, Any]) -> TextContent:
    """Execute a tool with proper error handling."""
    if name == "api_call":
        try:
            args = APICallArgs(**arguments)
        except Exception as e:
            raise InvalidArgumentError(str(e)) from e

        try:
            response = await make_api_request(args)
            return TextContent(type="text", text=response)
        except aiohttp.ClientError as e:
            raise ExternalAPIError(f"API request failed: {e}") from e

    raise ToolError(f"Unknown tool: {name}")
```
</error_patterns>

## Configuration

<env_config>
```python
# config.py
import os
from dataclasses import dataclass
from pathlib import Path

@dataclass
class Config:
    """Server configuration."""
    api_key: str
    api_endpoint: str
    max_retries: int
    debug: bool
    cache_dir: Path

    @classmethod
    def from_env(cls) -> 'Config':
        """Load configuration from environment variables."""
        api_key = os.getenv("API_KEY")
        if not api_key:
            raise ValueError("API_KEY environment variable is required")

        return cls(
            api_key=api_key,
            api_endpoint=os.getenv("API_ENDPOINT", "https://api.example.com"),
            max_retries=int(os.getenv("MAX_RETRIES", "3")),
            debug=os.getenv("DEBUG", "").lower() == "true",
            cache_dir=Path(os.getenv("CACHE_DIR", "~/.cache/my-mcp-server")).expanduser(),
        )

    def __post_init__(self):
        """Validate and prepare configuration."""
        # Ensure cache directory exists
        self.cache_dir.mkdir(parents=True, exist_ok=True)

        # Log configuration (without secrets)
        if self.debug:
            print(f"Config: endpoint={self.api_endpoint}, retries={self.max_retries}",
                  file=sys.stderr)

# Load config globally
config = Config.from_env()

# Use in tools
@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    if name == "api_call":
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f"{config.api_endpoint}/data",
                headers={"Authorization": f"Bearer {config.api_key}"}
            ) as response:
                data = await response.json()
                return [TextContent(type="text", text=str(data))]

    raise ValueError(f"Unknown tool: {name}")
```

**.env file**:
```
API_KEY=your_api_key_here
API_ENDPOINT=https://api.example.com
MAX_RETRIES=3
DEBUG=true
CACHE_DIR=~/.cache/my-mcp-server
```

**Load .env in development**:
```python
# At top of server.py
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # dotenv not required in production
```
</env_config>

## Advanced Features

<caching>
**Caching Pattern**:

```python
from functools import lru_cache
from datetime import datetime, timedelta
from typing import Any

class Cache:
    """Simple time-based cache."""
    def __init__(self):
        self._cache: dict[str, tuple[Any, datetime]] = {}

    def get(self, key: str, ttl: int = 300) -> Any | None:
        """Get cached value if not expired."""
        if key in self._cache:
            value, timestamp = self._cache[key]
            if datetime.now() - timestamp < timedelta(seconds=ttl):
                return value
            del self._cache[key]
        return None

    def set(self, key: str, value: Any):
        """Set cached value."""
        self._cache[key] = (value, datetime.now())

    def clear(self):
        """Clear all cached values."""
        self._cache.clear()

cache = Cache()

async def cached_api_call(url: str) -> dict:
    """API call with caching."""
    cached = cache.get(url, ttl=300)
    if cached is not None:
        print(f"Cache hit: {url}", file=sys.stderr)
        return cached

    print(f"Cache miss: {url}", file=sys.stderr)
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            data = await response.json()
            cache.set(url, data)
            return data
```
</caching>

<logging>
**Structured Logging**:

```python
import logging
import sys
from datetime import datetime

# Configure logging to stderr
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stderr
)

logger = logging.getLogger("my-mcp-server")

@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls with logging."""
    logger.info(f"Tool called: {name}", extra={
        "tool_name": name,
        "arg_keys": list(arguments.keys()),
    })

    try:
        result = await execute_tool(name, arguments)
        logger.info(f"Tool completed: {name}")
        return [result]
    except Exception as e:
        logger.error(f"Tool failed: {name}", exc_info=True, extra={
            "tool_name": name,
            "error_type": type(e).__name__,
        })
        raise
```
</logging>

## Build and Distribution

<package_setup>
```toml
# pyproject.toml
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "my-mcp-server"
version = "1.0.0"
description = "MCP server for X"
readme = "README.md"
requires-python = ">=3.10"
dependencies = [
    "mcp>=0.1.0",
    "pydantic>=2.0.0",
    "aiohttp>=3.9.0",
]

[project.scripts]
my-mcp-server = "my_mcp_server.server:run"

[project.urls]
Homepage = "https://github.com/yourusername/my-mcp-server"
Repository = "https://github.com/yourusername/my-mcp-server"
```
</package_setup>

<publishing>
**Build and publish**:

```bash
# Build
python -m pip install build
python -m build

# Publish to PyPI
python -m pip install twine
python -m twine upload dist/*
```

Users install with:
```bash
pip install my-mcp-server
```

Claude Desktop config:
```json
{
  "mcpServers": {
    "my-server": {
      "command": "my-mcp-server"
    }
  }
}
```

Or with uvx (recommended):
```json
{
  "mcpServers": {
    "my-server": {
      "command": "uvx",
      "args": ["my-mcp-server"]
    }
  }
}
```
</publishing>

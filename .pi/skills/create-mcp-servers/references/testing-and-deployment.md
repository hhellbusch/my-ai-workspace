# Testing and Deployment

<overview>
Production MCP servers require thorough testing and reliable deployment strategies. This guide covers testing approaches, packaging, and distribution for both TypeScript and Python servers.
</overview>

## Testing Strategies

<testing_pyramid>
**Test Pyramid for MCP Servers**:

1. **Unit Tests** (70%): Test individual tool/resource handlers
2. **Integration Tests** (20%): Test server protocol compliance
3. **End-to-End Tests** (10%): Test with actual Claude Desktop

</testing_pyramid>

## TypeScript Testing

<typescript_unit_tests>
**Unit Testing with Vitest**:

```bash
npm install -D vitest @vitest/ui
```

```typescript
// tests/tools/calculator.test.ts
import { describe, it, expect } from "vitest";
import { addNumbersTool } from "../../src/tools/calculator";

describe("Calculator Tools", () => {
  describe("addNumbersTool", () => {
    it("should add two positive numbers", async () => {
      const result = await addNumbersTool({ a: 5, b: 3 });

      expect(result).toEqual({
        type: "text",
        text: "5 + 3 = 8",
      });
    });

    it("should handle negative numbers", async () => {
      const result = await addNumbersTool({ a: -5, b: 3 });

      expect(result).toEqual({
        type: "text",
        text: "-5 + 3 = -2",
      });
    });

    it("should handle decimals", async () => {
      const result = await addNumbersTool({ a: 1.5, b: 2.7 });

      expect(result).toEqual({
        type: "text",
        text: "1.5 + 2.7 = 4.2",
      });
    });
  });
});
```

```json
// package.json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  }
}
```
</typescript_unit_tests>

<typescript_integration_tests>
**Integration Testing**:

```typescript
// tests/integration/server.test.ts
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { createServer } from "../../src/server";

describe("MCP Server Integration", () => {
  let server: Server;
  let transport: InMemoryTransport;

  beforeAll(async () => {
    server = createServer();
    transport = new InMemoryTransport();
    await server.connect(transport);
  });

  afterAll(async () => {
    await server.close();
  });

  it("should list tools", async () => {
    const response = await transport.request({
      method: "tools/list",
    });

    expect(response.tools).toBeArrayOfSize(3);
    expect(response.tools).toContainEqual(
      expect.objectContaining({
        name: "add_numbers",
        description: expect.any(String),
      })
    );
  });

  it("should call tool successfully", async () => {
    const response = await transport.request({
      method: "tools/call",
      params: {
        name: "add_numbers",
        arguments: { a: 5, b: 3 },
      },
    });

    expect(response.content).toEqual([
      {
        type: "text",
        text: "5 + 3 = 8",
      },
    ]);
  });

  it("should return error for unknown tool", async () => {
    await expect(
      transport.request({
        method: "tools/call",
        params: {
          name: "unknown_tool",
          arguments: {},
        },
      })
    ).rejects.toThrow("Unknown tool");
  });

  it("should validate tool arguments", async () => {
    await expect(
      transport.request({
        method: "tools/call",
        params: {
          name: "add_numbers",
          arguments: { a: "not a number", b: 3 },
        },
      })
    ).rejects.toThrow();
  });
});
```
</typescript_integration_tests>

<typescript_mocking>
**Mocking External Dependencies**:

```typescript
// tests/tools/api-client.test.ts
import { describe, it, expect, vi, beforeEach } from "vitest";
import { apiClientTool } from "../../src/tools/api-client";

// Mock fetch
global.fetch = vi.fn();

describe("API Client Tool", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("should make successful API call", async () => {
    const mockResponse = { data: "test" };

    (global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => mockResponse,
    });

    const result = await apiClientTool({
      endpoint: "/users/123",
      method: "GET",
    });

    expect(global.fetch).toHaveBeenCalledWith(
      "https://api.example.com/users/123",
      expect.objectContaining({
        method: "GET",
      })
    );

    expect(result).toEqual({
      type: "text",
      text: JSON.stringify(mockResponse, null, 2),
    });
  });

  it("should handle API errors", async () => {
    (global.fetch as any).mockRejectedValueOnce(new Error("Network error"));

    await expect(
      apiClientTool({
        endpoint: "/users/123",
        method: "GET",
      })
    ).rejects.toThrow("Network error");
  });
});
```
</typescript_mocking>

## Python Testing

<python_unit_tests>
**Unit Testing with pytest**:

```bash
pip install pytest pytest-asyncio pytest-cov
```

```python
# tests/tools/test_calculator.py
import pytest
from my_mcp_server.tools.calculator import add_numbers_tool
from my_mcp_server.types import AddNumbersArgs

@pytest.mark.asyncio
async def test_add_positive_numbers():
    """Test adding two positive numbers."""
    args = AddNumbersArgs(a=5, b=3)
    result = await add_numbers_tool(args)

    assert result.type == "text"
    assert result.text == "5 + 3 = 8"

@pytest.mark.asyncio
async def test_add_negative_numbers():
    """Test adding negative numbers."""
    args = AddNumbersArgs(a=-5, b=3)
    result = await add_numbers_tool(args)

    assert result.type == "text"
    assert result.text == "-5 + 3 = -2"

@pytest.mark.asyncio
async def test_add_decimals():
    """Test adding decimal numbers."""
    args = AddNumbersArgs(a=1.5, b=2.7)
    result = await add_numbers_tool(args)

    assert result.type == "text"
    assert result.text == "1.5 + 2.7 = 4.2"

def test_invalid_arguments():
    """Test validation of invalid arguments."""
    with pytest.raises(ValueError):
        AddNumbersArgs(a="not a number", b=3)
```

```toml
# pyproject.toml
[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]

[tool.coverage.run]
source = ["my_mcp_server"]
omit = ["*/tests/*"]
```

```json
// package.json (for npm scripts)
{
  "scripts": {
    "test": "pytest",
    "test:coverage": "pytest --cov --cov-report=html",
    "test:watch": "pytest-watch"
  }
}
```
</python_unit_tests>

<python_integration_tests>
**Integration Testing**:

```python
# tests/integration/test_server.py
import pytest
from mcp.server import Server
from mcp.types import TextContent
from my_mcp_server.server import app, list_tools, call_tool

@pytest.mark.asyncio
async def test_list_tools():
    """Test listing available tools."""
    tools = await list_tools()

    assert len(tools) == 3
    assert any(tool.name == "add_numbers" for tool in tools)

@pytest.mark.asyncio
async def test_call_tool_success():
    """Test successful tool call."""
    result = await call_tool("add_numbers", {"a": 5, "b": 3})

    assert len(result) == 1
    assert result[0].type == "text"
    assert result[0].text == "5 + 3 = 8"

@pytest.mark.asyncio
async def test_call_unknown_tool():
    """Test calling unknown tool."""
    with pytest.raises(ValueError, match="Unknown tool"):
        await call_tool("unknown_tool", {})

@pytest.mark.asyncio
async def test_call_tool_invalid_args():
    """Test calling tool with invalid arguments."""
    with pytest.raises(Exception):  # Pydantic ValidationError
        await call_tool("add_numbers", {"a": "not a number", "b": 3})

@pytest.mark.asyncio
async def test_resources():
    """Test resource handlers."""
    from my_mcp_server.server import list_resources, read_resource

    resources = await list_resources()
    assert len(resources) > 0

    # Test reading a resource
    content = await read_resource("config://settings")
    assert isinstance(content, str)
```
</python_integration_tests>

<python_mocking>
**Mocking External Dependencies**:

```python
# tests/tools/test_api_client.py
import pytest
from unittest.mock import AsyncMock, patch
from my_mcp_server.tools.api_client import api_client_tool
from my_mcp_server.types import APIClientArgs

@pytest.mark.asyncio
@patch("aiohttp.ClientSession.get")
async def test_api_call_success(mock_get):
    """Test successful API call."""
    # Setup mock
    mock_response = AsyncMock()
    mock_response.json = AsyncMock(return_value={"data": "test"})
    mock_response.raise_for_status = AsyncMock()
    mock_get.return_value.__aenter__.return_value = mock_response

    # Execute
    args = APIClientArgs(endpoint="/users/123", method="GET")
    result = await api_client_tool(args)

    # Verify
    assert result.type == "text"
    assert '"data": "test"' in result.text
    mock_get.assert_called_once()

@pytest.mark.asyncio
@patch("aiohttp.ClientSession.get")
async def test_api_call_error(mock_get):
    """Test API call error handling."""
    # Setup mock to raise error
    mock_get.side_effect = Exception("Network error")

    # Execute and verify
    args = APIClientArgs(endpoint="/users/123", method="GET")
    with pytest.raises(Exception, match="Network error"):
        await api_client_tool(args)
```
</python_mocking>

## End-to-End Testing

<e2e_manual>
**Manual E2E Testing with Claude Desktop**:

1. **Build your server**:
   ```bash
   # TypeScript
   npm run build

   # Python
   python -m pip install -e .
   ```

2. **Configure Claude Desktop**:
   ```json
   {
     "mcpServers": {
       "test-server": {
         "command": "node",
         "args": ["/absolute/path/to/dist/index.js"]
       }
     }
   }
   ```

3. **Restart Claude Desktop**

4. **Test in conversation**:
   - "List available tools"
   - "Use the add_numbers tool with 5 and 3"
   - "Read the config://settings resource"

5. **Check logs**:
   - macOS: `~/Library/Logs/Claude/mcp*.log`
   - Look for your server's stderr output

</e2e_manual>

<e2e_automated>
**Automated E2E Testing** (Advanced):

```typescript
// tests/e2e/claude-integration.test.ts
import { describe, it, expect } from "vitest";
import { spawn } from "child_process";
import { once } from "events";

describe("E2E: Claude Desktop Integration", () => {
  it("should start server and respond to requests", async () => {
    // Start server as subprocess
    const server = spawn("node", ["dist/index.js"], {
      stdio: ["pipe", "pipe", "pipe"],
    });

    // Wait for server to be ready
    await new Promise((resolve) => setTimeout(resolve, 1000));

    // Send MCP protocol message
    const request = {
      jsonrpc: "2.0",
      id: 1,
      method: "tools/list",
    };

    server.stdin.write(JSON.stringify(request) + "\n");

    // Read response
    const [output] = await once(server.stdout, "data");
    const response = JSON.parse(output.toString());

    expect(response.result.tools).toBeDefined();
    expect(response.result.tools.length).toBeGreaterThan(0);

    // Cleanup
    server.kill();
  });
});
```

```python
# tests/e2e/test_claude_integration.py
import pytest
import asyncio
import json
from my_mcp_server.server import main

@pytest.mark.asyncio
async def test_server_protocol():
    """Test server responds to MCP protocol."""
    # This is a simplified example - real implementation would use
    # proper stdio mocking or subprocess communication

    # Start server in background
    server_task = asyncio.create_task(main())

    # Give it time to start
    await asyncio.sleep(1)

    # In practice, you'd send actual MCP protocol messages
    # and verify responses

    # Cleanup
    server_task.cancel()
    try:
        await server_task
    except asyncio.CancelledError:
        pass
```
</e2e_automated>

## Packaging and Distribution

<typescript_packaging>
**TypeScript: npm Package**:

```json
// package.json
{
  "name": "my-mcp-server",
  "version": "1.0.0",
  "description": "MCP server for X",
  "main": "dist/index.js",
  "bin": {
    "my-mcp-server": "./dist/index.js"
  },
  "files": [
    "dist/**/*",
    "README.md",
    "LICENSE"
  ],
  "scripts": {
    "build": "tsc && chmod +x dist/index.js",
    "prepublishOnly": "npm run build && npm test"
  },
  "keywords": ["mcp", "mcp-server", "claude"],
  "author": "Your Name",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/yourusername/my-mcp-server"
  }
}
```

**Publishing**:
```bash
# Test locally first
npm link
# Test in Claude Desktop with: "command": "my-mcp-server"

# Publish to npm
npm login
npm publish

# Users install with:
# npm install -g my-mcp-server
```
</typescript_packaging>

<python_packaging>
**Python: PyPI Package**:

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
license = {text = "MIT"}
keywords = ["mcp", "mcp-server", "claude"]
authors = [
    {name = "Your Name", email = "your.email@example.com"}
]
classifiers = [
    "Development Status :: 4 - Beta",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]
dependencies = [
    "mcp>=0.1.0",
    "pydantic>=2.0.0",
]

[project.urls]
Homepage = "https://github.com/yourusername/my-mcp-server"
Repository = "https://github.com/yourusername/my-mcp-server"
Issues = "https://github.com/yourusername/my-mcp-server/issues"

[project.scripts]
my-mcp-server = "my_mcp_server.server:run"
```

**Publishing**:
```bash
# Build
python -m build

# Test locally first
pip install -e .
# Test in Claude Desktop

# Publish to PyPI
python -m twine upload dist/*

# Users install with:
# pip install my-mcp-server
# OR uvx my-mcp-server (recommended)
```
</python_packaging>

<docker_deployment>
**Docker Deployment** (for server-based MCP):

```dockerfile
# Dockerfile
FROM node:20-slim

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY dist ./dist

EXPOSE 3000

CMD ["node", "dist/index.js"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  mcp-server:
    build: .
    ports:
      - "3000:3000"
    environment:
      - API_KEY=${API_KEY}
      - DEBUG=false
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```
</docker_deployment>

## CI/CD

<github_actions>
**GitHub Actions Workflow**:

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test-typescript:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run build
      - run: npm test
      - run: npm run test:coverage

  test-python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install -e ".[dev]"
      - run: pytest --cov

  publish-npm:
    needs: test-typescript
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
          registry-url: 'https://registry.npmjs.org'
      - run: npm ci
      - run: npm run build
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

  publish-pypi:
    needs: test-python
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install build twine
      - run: python -m build
      - run: python -m twine upload dist/*
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_TOKEN }}
```
</github_actions>

# MCP Server Best Practices

<overview>
Production-ready MCP servers require attention to security, reliability, performance, and maintainability. This guide covers essential best practices for building robust servers.
</overview>

## Security

<input_validation>
**Always Validate Inputs**:

```typescript
// TypeScript - Use Zod for strict validation
import { z } from "zod";

const FileReadSchema = z.object({
  path: z.string()
    .min(1, "Path required")
    .max(500, "Path too long")
    .refine(
      (path) => !path.includes(".."),
      "Path traversal not allowed"
    )
    .refine(
      (path) => !path.startsWith("/etc"),
      "System directories not allowed"
    ),
});

async function readFileTool(args: z.infer<typeof FileReadSchema>) {
  // Validation happens automatically via Zod
  const validated = FileReadSchema.parse(args);

  // Additional runtime checks
  const fullPath = path.resolve(ALLOWED_DIR, validated.path);
  if (!fullPath.startsWith(ALLOWED_DIR)) {
    throw new Error("Access denied: Path outside allowed directory");
  }

  // Safe to proceed
  return await fs.readFile(fullPath, "utf-8");
}
```

```python
# Python - Use Pydantic with validators
from pydantic import BaseModel, Field, field_validator
from pathlib import Path

class FileReadArgs(BaseModel):
    path: str = Field(min_length=1, max_length=500)

    @field_validator('path')
    @classmethod
    def validate_path(cls, v: str) -> str:
        # Prevent path traversal
        if ".." in v:
            raise ValueError("Path traversal not allowed")

        # Prevent system directories
        if v.startswith("/etc") or v.startswith("/sys"):
            raise ValueError("System directories not allowed")

        return v

async def read_file_tool(args: FileReadArgs) -> TextContent:
    # Additional runtime checks
    full_path = (Path(ALLOWED_DIR) / args.path).resolve()
    if not str(full_path).startswith(ALLOWED_DIR):
        raise ValueError("Access denied: Path outside allowed directory")

    # Safe to proceed
    async with aiofiles.open(full_path, "r") as f:
        content = await f.read()
        return TextContent(type="text", text=content)
```

**Key principles**:
- Validate all inputs with strict schemas
- Check for path traversal attacks (`..`, absolute paths)
- Whitelist allowed directories/operations
- Validate at schema level AND runtime
- Never trust user input
</input_validation>

<secrets_management>
**Secrets Management**:

```typescript
// TypeScript - Environment variables, never hardcode
import dotenv from "dotenv";
dotenv.config();

interface Config {
  apiKey: string;
  dbPassword: string;
}

function loadConfig(): Config {
  const apiKey = process.env.API_KEY;
  const dbPassword = process.env.DB_PASSWORD;

  if (!apiKey || !dbPassword) {
    throw new Error("Missing required environment variables");
  }

  // NEVER log secrets
  console.error("Config loaded successfully");

  return { apiKey, dbPassword };
}

const config = loadConfig();

// NEVER return secrets to Claude
@app.list_resources()
async def list_resources() -> list[Resource]:
    return [
        Resource(
            uri="config://server",
            name="Server Config",
            description="Server configuration (secrets redacted)",
        )
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    if uri == "config://server":
        return json.dumps({
            "endpoint": config.api_endpoint,
            "timeout": config.timeout,
            # NEVER expose secrets:
            # "apiKey": config.apiKey,  ❌
        })
```

```python
# Python - Use python-dotenv or environment variables
import os
from dataclasses import dataclass

@dataclass
class Config:
    api_key: str
    db_password: str

    @classmethod
    def from_env(cls) -> 'Config':
        api_key = os.getenv("API_KEY")
        db_password = os.getenv("DB_PASSWORD")

        if not api_key or not db_password:
            raise ValueError("Missing required environment variables")

        # NEVER log secrets
        print("Config loaded successfully", file=sys.stderr)

        return cls(api_key=api_key, db_password=db_password)

config = Config.from_env()
```

**Key principles**:
- Use environment variables for secrets
- Never hardcode credentials
- Never log secrets (even in debug mode)
- Never return secrets to Claude
- Use `.env` for development, proper secret management in production
- Rotate secrets regularly
</secrets_management>

<rate_limiting>
**Rate Limiting and Resource Protection**:

```typescript
// TypeScript - Simple rate limiter
class RateLimiter {
  private requests = new Map<string, number[]>();

  check(key: string, limit: number, windowMs: number): boolean {
    const now = Date.now();
    const requests = this.requests.get(key) || [];

    // Remove old requests outside window
    const recent = requests.filter((time) => now - time < windowMs);

    if (recent.length >= limit) {
      return false; // Rate limited
    }

    recent.push(now);
    this.requests.set(key, recent);
    return true;
  }
}

const limiter = new RateLimiter();

async function callTool(name: string, args: any) {
  // Rate limit: 10 requests per minute per tool
  if (!limiter.check(name, 10, 60000)) {
    throw new Error(`Rate limit exceeded for ${name}`);
  }

  // Proceed with tool execution
  return await executeTool(name, args);
}
```

```python
# Python - Rate limiter with asyncio
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Dict, List

class RateLimiter:
    def __init__(self):
        self.requests: Dict[str, List[datetime]] = defaultdict(list)

    def check(self, key: str, limit: int, window_seconds: int) -> bool:
        now = datetime.now()
        cutoff = now - timedelta(seconds=window_seconds)

        # Remove old requests
        self.requests[key] = [
            req_time for req_time in self.requests[key]
            if req_time > cutoff
        ]

        if len(self.requests[key]) >= limit:
            return False  # Rate limited

        self.requests[key].append(now)
        return True

limiter = RateLimiter()

async def call_tool(name: str, args: dict) -> list[TextContent]:
    # Rate limit: 10 requests per minute per tool
    if not limiter.check(name, limit=10, window_seconds=60):
        raise ValueError(f"Rate limit exceeded for {name}")

    # Proceed with tool execution
    return await execute_tool(name, args)
```
</rate_limiting>

<sql_injection>
**SQL Injection Prevention**:

```typescript
// TypeScript - ALWAYS use parameterized queries
import { Pool } from "pg";

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// ✅ CORRECT - Parameterized query
async function getUserById(id: string) {
  const result = await pool.query(
    "SELECT * FROM users WHERE id = $1",
    [id]
  );
  return result.rows[0];
}

// ❌ WRONG - String concatenation (SQL injection!)
async function getUserByIdWrong(id: string) {
  const result = await pool.query(
    `SELECT * FROM users WHERE id = '${id}'`
  );
  return result.rows[0];
}
```

```python
# Python - Use parameterized queries with asyncpg
import asyncpg

async def get_user_by_id(user_id: str) -> dict:
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        # ✅ CORRECT - Parameterized query
        row = await conn.fetchrow(
            "SELECT * FROM users WHERE id = $1",
            user_id
        )
        return dict(row) if row else None
    finally:
        await conn.close()

# ❌ WRONG - String formatting (SQL injection!)
async def get_user_by_id_wrong(user_id: str) -> dict:
    conn = await asyncpg.connect(DATABASE_URL)
    try:
        row = await conn.fetchrow(
            f"SELECT * FROM users WHERE id = '{user_id}'"
        )
        return dict(row) if row else None
    finally:
        await conn.close()
```
</sql_injection>

<authentication>
**Authentication & Authorization**:

MCP servers may need to authenticate users or protect sensitive operations. Use OAuth 2.1 for production scenarios.

```typescript
// TypeScript - OAuth Resource Server with FastMCP
import { FastMCP } from "@modelcontextprotocol/server-fastmcp";
import { TokenVerifier, AccessToken } from "@modelcontextprotocol/server-auth";

class JWTTokenVerifier implements TokenVerifier {
  async verifyToken(token: string): Promise<AccessToken | null> {
    try {
      // Verify JWT token (use a library like jose)
      const payload = await verifyJWT(token, process.env.JWT_PUBLIC_KEY);

      return {
        sub: payload.sub,
        scope: payload.scope || "",
        exp: payload.exp,
      };
    } catch (error) {
      return null;
    }
  }
}

const mcp = new FastMCP("Protected API", {
  tokenVerifier: new JWTTokenVerifier(),
  auth: {
    issuerUrl: "https://auth.example.com",
    resourceServerUrl: "http://localhost:3000",
    requiredScopes: ["api:read"],
  },
});

// Tools automatically protected by auth
mcp.tool("get_sensitive_data", async (args, ctx) => {
  // Access token info from context
  const token = ctx.auth?.accessToken;
  if (!token) {
    throw new Error("Unauthorized");
  }

  // Check scopes
  if (!token.scope.includes("data:read")) {
    throw new Error("Insufficient permissions");
  }

  return { data: "sensitive information" };
});
```

```python
# Python - OAuth Resource Server
from mcp.server.fastmcp import FastMCP
from mcp.server.auth.provider import TokenVerifier, AccessToken
from pydantic import AnyHttpUrl
import jwt

class JWTTokenVerifier(TokenVerifier):
    async def verify_token(self, token: str) -> AccessToken | None:
        try:
            # Verify JWT (use PyJWT)
            payload = jwt.decode(
                token,
                os.environ["JWT_PUBLIC_KEY"],
                algorithms=["RS256"]
            )

            return AccessToken(
                sub=payload["sub"],
                scope=payload.get("scope", ""),
                exp=payload["exp"],
            )
        except jwt.InvalidTokenError:
            return None

mcp = FastMCP(
    "Protected API",
    token_verifier=JWTTokenVerifier(),
    auth=AuthSettings(
        issuer_url=AnyHttpUrl("https://auth.example.com"),
        resource_server_url=AnyHttpUrl("http://localhost:3000"),
        required_scopes=["api:read"],
    ),
)

@mcp.tool()
async def get_sensitive_data(ctx: Context) -> str:
    """Get sensitive data (requires authentication)."""
    # Access token from context
    token = ctx.request_context.auth.access_token
    if not token:
        raise ValueError("Unauthorized")

    # Check scopes
    if "data:read" not in token.scope:
        raise ValueError("Insufficient permissions")

    return "sensitive information"
```

**API Key Authentication (simpler, less secure)**:

```typescript
// TypeScript - Simple API key auth
const API_KEY = process.env.API_KEY;

server.setRequestHandler("tools/call", async (request) => {
  // Check API key in request metadata
  const apiKey = request.params._meta?.apiKey;

  if (apiKey !== API_KEY) {
    throw new Error("Invalid API key");
  }

  // Proceed with tool execution
  return await handleTool(request.params.name, request.params.arguments);
});
```

```python
# Python - API key in environment variables
API_KEY = os.environ.get("API_KEY")

@mcp.call_tool()
async def call_tool(name: str, arguments: dict, ctx: Context) -> list[TextContent]:
    # Extract API key from request metadata
    api_key = arguments.get("_api_key")

    if api_key != API_KEY:
        raise ValueError("Invalid API key")

    # Proceed with tool execution
    return await execute_tool(name, arguments)
```

**Key principles**:
- Use OAuth 2.1 for production (proper token verification, scope checking)
- API keys only for simple/internal use cases
- Never log tokens or API keys
- Verify authentication on every tool call
- Check authorization (scopes/permissions) per operation
- Return 401 for authentication failures, 403 for authorization failures
- Token verification should be fast (cache public keys)
</authentication>

## Dependency Isolation

<why_it_matters>
**The Problem: Dependency Conflicts Break Everything**

Real story: A pydantic version conflict broke 6 MCP servers simultaneously. One server updated pydantic to 2.10, breaking 5 other servers that required pydantic 2.9. All MCPs failed to start because they shared the same global Python interpreter.

When MCP servers share Python interpreters or global package installations:
- **One server's dependencies can break other servers** (version conflicts cascade)
- **Upgrades become dangerous** (updating one server risks breaking others)
- **Debugging is impossible** (which server caused the conflict?)
- **Rollbacks require reinstalling everything** (no per-server isolation)

**The Solution: Every MCP server needs its own isolated environment**
</why_it_matters>

<uv_tooling>
**Primary Approach: `uv` (Official MCP Recommendation)**

`uv` is the official tool for Python MCP servers. It automatically creates isolated environments per-project and manages dependencies without global installs.

**Development workflow**:
```bash
# Initialize new MCP server with uv
uv init my-mcp-server
cd my-mcp-server

# Add dependencies
uv add mcp aiohttp

# Development/testing
uv run mcp dev server.py

# Install for Claude Desktop
uv run mcp install server.py
```

**Claude Desktop configuration** (automatic isolation):
```json
{
  "mcpServers": {
    "my-server": {
      "command": "uv",
      "args": [
        "--directory",
        "/Users/username/Developer/mcp/my-server",
        "run",
        "python",
        "server.py"
      ]
    }
  }
}
```

The `--directory` flag tells `uv` to:
1. Use the project's local environment (`.venv/`)
2. Install dependencies from `pyproject.toml` automatically
3. Isolate this server from all others

**Published servers** (for distribution):
```bash
# Users install with uvx (no global pollution)
uvx mcp-server-name
```

**Real examples from working configuration**:

```json
{
  "Workshop": {
    "command": "uv",
    "args": [
      "--directory",
      "/Users/lexchristopherson/Developer/workshops/mcp-server",
      "run",
      "python",
      "server.py"
    ]
  },
  "finance": {
    "command": "uv",
    "args": [
      "--directory",
      "/Users/lexchristopherson/Developer/finance/mcp-server-finance",
      "run",
      "python",
      "server.py"
    ]
  },
  "zoom": {
    "command": "uv",
    "args": [
      "--directory",
      "/Users/lexchristopherson/Developer/mcp/zoom-mcp",
      "run",
      "python",
      "-m",
      "zoom_mcp.server"
    ],
    "env": {
      "ZOOM_ACCOUNT_ID": "...",
      "ZOOM_CLIENT_ID": "...",
      "ZOOM_CLIENT_SECRET": "..."
    }
  }
}
```

Each server runs in complete isolation with its own dependencies.
</uv_tooling>

<anti_patterns>
**What NOT To Do**

**❌ Never use bare `python` or `python3` commands**:
```json
{
  "my-server": {
    "command": "python",
    "args": ["/path/to/server.py"]
  }
}
```
**Why it breaks**: Uses global Python interpreter. Installing dependencies for one server affects all servers. Pydantic conflicts, async library version mismatches, and numpy/pandas incompatibilities will cascade across all MCPs.

**❌ Never use global pip installs**:
```bash
# This breaks isolation
pip install mcp aiohttp pydantic
```
**Why it breaks**: Installs packages globally. When another MCP needs a different version, `pip install --upgrade` breaks the first server. Recovery requires tracking down every affected package.

**❌ Never point to virtual environments directly without `uv`**:
```json
{
  "my-server": {
    "command": "/path/to/.venv/bin/python",
    "args": ["server.py"]
  }
}
```
**Why it breaks**: While this creates isolation, it requires manual venv management. When dependencies change, you must manually reinstall. `uv` handles this automatically via `pyproject.toml`.

**❌ Never share interpreters between servers**:
```bash
# Creating one venv for multiple servers
python -m venv ~/.mcp-shared-env
~/.mcp-shared-env/bin/pip install mcp server1-deps server2-deps
```
**Why it breaks**: Same problem as global installs, just in a different location. Version conflicts still cascade.

**✅ Always use `uv --directory` pattern**:
```json
{
  "my-server": {
    "command": "uv",
    "args": ["--directory", "/full/path/to/project", "run", "python", "server.py"]
  }
}
```
</anti_patterns>

<practical_examples>
**Before: Fragile Configuration** (6 servers broke from one pydantic update)
```json
{
  "mcpServers": {
    "server1": {
      "command": "python",
      "args": ["/path/to/server1.py"]
    },
    "server2": {
      "command": "python",
      "args": ["/path/to/server2.py"]
    },
    "server3": {
      "command": "/path/.venv/bin/python",
      "args": ["server3.py"]
    }
  }
}
```

**After: Isolated Configuration** (each server has own dependencies)
```json
{
  "mcpServers": {
    "server1": {
      "command": "uv",
      "args": [
        "--directory",
        "/Users/username/mcp/server1",
        "run",
        "python",
        "server.py"
      ]
    },
    "server2": {
      "command": "uv",
      "args": [
        "--directory",
        "/Users/username/mcp/server2",
        "run",
        "python",
        "server.py"
      ]
    },
    "server3": {
      "command": "uv",
      "args": [
        "--directory",
        "/Users/username/mcp/server3",
        "run",
        "python",
        "server.py"
      ]
    }
  }
}
```

**Migration guide**:

1. **For each existing MCP server**:
```bash
cd /path/to/mcp-server

# Initialize uv project (creates pyproject.toml)
uv init

# Add your dependencies
uv add mcp aiohttp pydantic
# uv automatically creates isolated .venv/

# Test locally
uv run python server.py
```

2. **Update claude_desktop_config.json**:
```json
{
  "my-server": {
    "command": "uv",
    "args": [
      "--directory",
      "/absolute/path/to/mcp-server",
      "run",
      "python",
      "server.py"
    ]
  }
}
```

3. **Restart Claude Desktop**

Each server now has isolated dependencies. Updating one server's packages never affects others.
</practical_examples>

<typescript_note>
**TypeScript MCP servers** have natural isolation through npm/node_modules:

```json
{
  "my-ts-server": {
    "command": "node",
    "args": ["/path/to/server/dist/index.js"]
  }
}
```

Each TypeScript project has its own `node_modules/` directory, providing automatic isolation. No additional tooling needed.

For published TypeScript servers:
```json
{
  "published-server": {
    "command": "npx",
    "args": ["-y", "@org/mcp-server-name"]
  }
}
```

The `-y` flag installs to npx's cache, isolated from other packages.
</typescript_note>

## Error Handling

<comprehensive_errors>
**Comprehensive Error Handling**:

```typescript
// TypeScript - Error hierarchy
class MCPError extends Error {
  constructor(message: string, public code: string) {
    super(message);
    this.name = "MCPError";
  }
}

class ValidationError extends MCPError {
  constructor(message: string) {
    super(message, "VALIDATION_ERROR");
  }
}

class ExternalServiceError extends MCPError {
  constructor(message: string) {
    super(message, "EXTERNAL_SERVICE_ERROR");
  }
}

class NotFoundError extends MCPError {
  constructor(message: string) {
    super(message, "NOT_FOUND");
  }
}

// Tool handler with proper error handling
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  try {
    const tool = tools.get(request.params.name);

    if (!tool) {
      throw new NotFoundError(`Tool not found: ${request.params.name}`);
    }

    // Validate arguments
    let validatedArgs;
    try {
      validatedArgs = tool.schema.parse(request.params.arguments);
    } catch (error) {
      if (error instanceof z.ZodError) {
        const messages = error.errors.map((e) => `${e.path}: ${e.message}`);
        throw new ValidationError(`Invalid arguments:\n${messages.join("\n")}`);
      }
      throw error;
    }

    // Execute with timeout
    const result = await Promise.race([
      tool.handler(validatedArgs),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Timeout")), 30000)
      ),
    ]);

    return { content: [result] };

  } catch (error) {
    // Log error details to stderr
    console.error("Tool execution error:", {
      tool: request.params.name,
      error: error instanceof Error ? error.message : "Unknown error",
      stack: error instanceof Error ? error.stack : undefined,
    });

    // Return user-friendly error message
    if (error instanceof MCPError) {
      return {
        content: [
          {
            type: "text",
            text: `Error: ${error.message}`,
          },
        ],
        isError: true,
      };
    }

    // Generic error for unexpected issues
    return {
      content: [
        {
          type: "text",
          text: "An unexpected error occurred. Please contact support.",
        },
      ],
      isError: true,
    };
  }
});
```

```python
# Python - Error hierarchy
class MCPError(Exception):
    """Base MCP error."""
    def __init__(self, message: str, code: str):
        super().__init__(message)
        self.code = code

class ValidationError(MCPError):
    """Invalid input validation."""
    def __init__(self, message: str):
        super().__init__(message, "VALIDATION_ERROR")

class ExternalServiceError(MCPError):
    """External service failure."""
    def __init__(self, message: str):
        super().__init__(message, "EXTERNAL_SERVICE_ERROR")

class NotFoundError(MCPError):
    """Resource not found."""
    def __init__(self, message: str):
        super().__init__(message, "NOT_FOUND")

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Handle tool calls with comprehensive error handling."""
    try:
        # Find tool
        if name not in TOOLS:
            raise NotFoundError(f"Tool not found: {name}")

        tool = TOOLS[name]

        # Validate arguments
        try:
            validated_args = tool.args_model(**arguments)
        except ValidationError as e:
            raise ValidationError(f"Invalid arguments: {e}")

        # Execute with timeout
        result = await asyncio.wait_for(
            tool.handler(validated_args),
            timeout=30.0
        )

        return [result]

    except asyncio.TimeoutError:
        logger.error(f"Tool timeout: {name}")
        return [TextContent(
            type="text",
            text="Error: Tool execution timed out (30s limit)"
        )]

    except MCPError as e:
        logger.error(f"MCP error in {name}: {e.code} - {e}")
        return [TextContent(
            type="text",
            text=f"Error: {e}"
        )]

    except Exception as e:
        logger.exception(f"Unexpected error in {name}")
        return [TextContent(
            type="text",
            text="An unexpected error occurred. Please contact support."
        )]
```

**Key principles**:
- Create error hierarchy for different error types
- Always catch and handle errors gracefully
- Log detailed errors to stderr
- Return user-friendly messages to Claude
- Use timeouts to prevent hanging
- Never expose internal implementation details in errors
</comprehensive_errors>

## Logging

<structured_logging>
**Structured Logging**:

```typescript
// TypeScript - Winston logger
import winston from "winston";

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    // Log to stderr (stdout is for MCP protocol)
    new winston.transports.Console({ stream: process.stderr }),
    // Also log to file
    new winston.transports.File({ filename: "mcp-server.log" }),
  ],
});

// Use throughout application
logger.info("Server starting", { version: SERVER_VERSION });

logger.debug("Tool called", {
  tool: "search",
  args: { query: "test" },
});

logger.error("External API failed", {
  tool: "api_call",
  endpoint: "/users",
  error: error.message,
  stack: error.stack,
});
```

```python
# Python - Structured logging with structlog
import structlog
import sys

# Configure structlog
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.PrintLoggerFactory(file=sys.stderr),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Use throughout application
logger.info("server_starting", version=SERVER_VERSION)

logger.debug("tool_called", tool="search", query="test")

logger.error(
    "external_api_failed",
    tool="api_call",
    endpoint="/users",
    error=str(error),
    exc_info=True,
)
```

**Key principles**:
- Always log to stderr (never stdout - reserved for MCP protocol)
- Use structured logging (JSON format)
- Include context in logs (tool name, arguments, etc.)
- Log errors with stack traces
- Use appropriate log levels (debug, info, warn, error)
- Consider log rotation for production
</structured_logging>

## Performance

<context_optimization>
**Context Window Optimization**:

For servers wrapping large APIs (20+ operations), tool definitions can consume 8,000-15,000 tokens before any actual conversation begins. This is one of the biggest performance bottlenecks for MCP servers.

**Solution:** Use the meta-tools + resources pattern to achieve 90-98% context reduction.

See [Large API Pattern](large-api-pattern.md) for complete guide with real metrics:
- Traditional: 81 tools = 15,000 tokens
- Meta-tools pattern: 4 tools = 300 tokens
- **Savings: 98% context reduction**

This is essential for servers wrapping APIs like GitHub, Stripe, Slack, or any API with 50+ operations.
</context_optimization>

<caching>
**Caching Strategies**:

```typescript
// TypeScript - LRU cache
import { LRUCache } from "lru-cache";

const cache = new LRUCache<string, any>({
  max: 500, // Maximum 500 items
  ttl: 1000 * 60 * 5, // 5 minute TTL
  updateAgeOnGet: true,
});

async function cachedApiCall(url: string) {
  // Check cache first
  const cached = cache.get(url);
  if (cached !== undefined) {
    logger.debug("Cache hit", { url });
    return cached;
  }

  // Fetch if not cached
  logger.debug("Cache miss", { url });
  const response = await fetch(url);
  const data = await response.json();

  // Store in cache
  cache.set(url, data);
  return data;
}
```

```python
# Python - Simple TTL cache
from functools import lru_cache
from datetime import datetime, timedelta
from typing import Any, Dict, Tuple

class TTLCache:
    def __init__(self, ttl_seconds: int = 300):
        self.ttl = timedelta(seconds=ttl_seconds)
        self.cache: Dict[str, Tuple[Any, datetime]] = {}

    def get(self, key: str) -> Any | None:
        if key in self.cache:
            value, timestamp = self.cache[key]
            if datetime.now() - timestamp < self.ttl:
                return value
            del self.cache[key]
        return None

    def set(self, key: str, value: Any):
        self.cache[key] = (value, datetime.now())

cache = TTLCache(ttl_seconds=300)

async def cached_api_call(url: str) -> dict:
    # Check cache first
    cached = cache.get(url)
    if cached is not None:
        logger.debug("cache_hit", url=url)
        return cached

    # Fetch if not cached
    logger.debug("cache_miss", url=url)
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            data = await response.json()

    # Store in cache
    cache.set(url, data)
    return data
```
</caching>

<connection_pooling>
**Connection Pooling**:

```typescript
// TypeScript - Database connection pooling
import { Pool } from "pg";

// Create pool once at startup
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20, // Maximum 20 connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Reuse connections from pool
async function queryDatabase(sql: string, params: any[]) {
  const client = await pool.connect();
  try {
    const result = await client.query(sql, params);
    return result.rows;
  } finally {
    client.release();
  }
}
```

```python
# Python - asyncpg connection pool
import asyncpg

# Create pool at startup
pool: asyncpg.Pool | None = None

async def init_db():
    global pool
    pool = await asyncpg.create_pool(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        min_size=5,
        max_size=20,
    )

async def query_database(sql: str, *params) -> list[dict]:
    async with pool.acquire() as conn:
        rows = await conn.fetch(sql, *params)
        return [dict(row) for row in rows]

# Initialize in main
async def main():
    await init_db()
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())
    await pool.close()
```
</connection_pooling>

<async_concurrency>
**Async Concurrency**:

```typescript
// TypeScript - Concurrent operations
async function batchProcess(items: string[]) {
  // Process items concurrently (max 5 at a time)
  const results = [];

  for (let i = 0; i < items.length; i += 5) {
    const batch = items.slice(i, i + 5);
    const batchResults = await Promise.all(
      batch.map((item) => processItem(item))
    );
    results.push(...batchResults);
  }

  return results;
}
```

```python
# Python - Concurrent operations with semaphore
async def batch_process(items: list[str]) -> list[dict]:
    # Process items concurrently (max 5 at a time)
    semaphore = asyncio.Semaphore(5)

    async def process_with_semaphore(item: str):
        async with semaphore:
            return await process_item(item)

    tasks = [process_with_semaphore(item) for item in items]
    results = await asyncio.gather(*tasks)
    return results
```
</async_concurrency>

## Reliability

<retry_logic>
**Retry Logic with Exponential Backoff**:

```typescript
// TypeScript - Retry decorator
async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }

      const delay = baseDelay * Math.pow(2, attempt);
      logger.warn("Retry attempt", {
        attempt: attempt + 1,
        maxRetries,
        delay,
        error: error instanceof Error ? error.message : "Unknown",
      });

      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw new Error("Unreachable");
}

// Usage
const result = await withRetry(() => fetch(url));
```

```python
# Python - Retry decorator
import asyncio
from functools import wraps
from typing import Callable, TypeVar

T = TypeVar('T')

def with_retry(max_retries: int = 3, base_delay: float = 1.0):
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            for attempt in range(max_retries + 1):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_retries:
                        raise

                    delay = base_delay * (2 ** attempt)
                    logger.warning(
                        "retry_attempt",
                        attempt=attempt + 1,
                        max_retries=max_retries,
                        delay=delay,
                        error=str(e),
                    )

                    await asyncio.sleep(delay)

            raise RuntimeError("Unreachable")

        return wrapper
    return decorator

# Usage
@with_retry(max_retries=3, base_delay=1.0)
async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()
```
</retry_logic>

<health_checks>
**Health Checks**:

```python
@app.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="health_check",
            description="Check server health and dependencies",
            inputSchema={"type": "object", "properties": {}},
        ),
        # ... other tools
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "health_check":
        health_status = await check_health()
        return [TextContent(
            type="text",
            text=json.dumps(health_status, indent=2)
        )]

async def check_health() -> dict:
    """Check health of server and dependencies."""
    checks = {
        "server": "ok",
        "database": "unknown",
        "external_api": "unknown",
    }

    # Check database
    try:
        await pool.fetchval("SELECT 1")
        checks["database"] = "ok"
    except Exception as e:
        checks["database"] = f"error: {e}"

    # Check external API
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{config.api_url}/health", timeout=5) as response:
                if response.status == 200:
                    checks["external_api"] = "ok"
                else:
                    checks["external_api"] = f"error: HTTP {response.status}"
    except Exception as e:
        checks["external_api"] = f"error: {e}"

    return checks
```
</health_checks>

## Tool Design & Usability

<tool_descriptions>
**Writing Effective Tool Descriptions**:

Tool descriptions are critical - they determine whether Claude understands when and how to use your tools.

**Good vs Bad Descriptions**:

```typescript
// ❌ BAD: Vague, unclear when to use
{
  name: "search",
  description: "Search for things",
  // Claude doesn't know: What things? What format? When to use this?
}

// ✅ GOOD: Clear purpose, clear use case
{
  name: "search_github_repos",
  description: "Search GitHub repositories by keyword. Use when the user asks to find, discover, or search for GitHub projects. Returns repository name, description, stars, and URL.",
  // Claude knows: What it does, when to use it, what it returns
}
```

```python
# ❌ BAD: Technical jargon, unclear value
Tool(
    name="execute_query",
    description="Executes a SQL query against the database"
)

# ✅ GOOD: User benefit, clear constraints
Tool(
    name="get_user_orders",
    description="Retrieve all orders for a specific user by email address. Returns order ID, date, total, and status. Use when the user asks about their order history or purchase records."
)
```

**Description Best Practices**:

1. **Start with the action**: "Search GitHub...", "Create a calendar...", "Analyze sentiment..."
2. **Include the use case**: "Use when the user asks to..." or "Use this to..."
3. **Specify what it returns**: "Returns X, Y, Z"
4. **Mention important constraints**: "Maximum 100 results", "Requires API key", "Read-only"
5. **Use user language, not technical jargon**: "orders" not "transactional records"
6. **Be specific about data types**: "email address" not "user identifier"

**Naming Conventions**:

```typescript
// ✅ GOOD: Verb_noun format, clear and specific
"create_calendar_event"
"search_github_repos"
"analyze_sentiment"
"get_user_profile"

// ❌ BAD: Unclear, ambiguous, or too generic
"handle"  // Handle what?
"process"  // Process what?
"data"  // What data operation?
"execute"  // Execute what?
```

**Testing Descriptions with Claude**:

After writing descriptions, test them:
1. Ask Claude "what tools do you have?"
2. Give vague requests: "help me with GitHub"
3. Verify Claude selects the right tool
4. If wrong, improve description specificity

</tool_descriptions>

## Transport Selection

<transport_guide>
**Choosing the Right Transport**:

MCP supports three transport types. Choose based on your use case:

**1. stdio (Standard Input/Output)**

**Best for:**
- Claude Desktop integration
- CLI tools and scripts
- Simple request/response patterns
- Single-user, local execution

**Pros:**
- Simplest to implement
- No network configuration
- Works everywhere
- Built-in session management

**Cons:**
- No network access (local only)
- One client per server process
- No browser support

```json
{
  "command": "uv",
  "args": ["--directory", "/path/to/server", "run", "python", "server.py"]
}
```

**2. SSE (Server-Sent Events)**

**Best for:**
- Web applications
- Multiple concurrent clients
- Real-time updates to browser clients
- Read-heavy workloads

**Pros:**
- Browser-compatible
- Multiple clients per server
- Real-time streaming
- HTTP-based (works through proxies)

**Cons:**
- Requires HTTP server setup
- More complex than stdio
- One-way communication (server → client)

```python
mcp = FastMCP("My Server")

if __name__ == "__main__":
    mcp.run(transport="sse", port=8000)
```

**3. Streamable HTTP**

**Best for:**
- RESTful APIs
- Browser-based clients
- Stateless or stateful sessions
- Enterprise deployments

**Pros:**
- Full HTTP flexibility
- Browser-compatible
- Stateful or stateless modes
- Load balancer friendly

**Cons:**
- Most complex setup
- Requires CORS configuration for browsers
- Session management overhead (stateful mode)

```python
# Stateful (maintains session state)
mcp = FastMCP("Stateful Service")
mcp.run(transport="streamable-http")

# Stateless (no session persistence, simpler)
mcp = FastMCP("Stateless Service", stateless_http=True)
mcp.run(transport="streamable-http")
```

**Decision Matrix**:

| Use Case | Recommended Transport |
|----------|----------------------|
| Claude Desktop only | stdio |
| Browser client | Streamable HTTP or SSE |
| Multiple concurrent users | Streamable HTTP |
| Real-time updates | SSE |
| Simple local tool | stdio |
| Enterprise deployment | Streamable HTTP (stateless) |
| WebSocket alternative | SSE |

</transport_guide>

## Debugging & Development

<mcp_inspector>
**Using MCP Inspector**:

The official MCP Inspector is essential for debugging during development.

```bash
# Install globally
npm install -g @modelcontextprotocol/inspector

# Run your server through the inspector
npx @modelcontextprotocol/inspector uv --directory /path/to/server run python server.py
```

**Inspector Features**:
- **Protocol visualization**: See all MCP messages in real-time
- **Tool testing**: Call tools with custom arguments
- **Resource browsing**: List and read resources
- **Request/response inspection**: Debug message payloads
- **Error tracking**: See exactly where failures occur

**Debugging Workflow**:

1. **Start with Inspector**: Always test new tools/resources through Inspector first
2. **Verify protocol compliance**: Check message formats match MCP spec
3. **Test edge cases**: Try invalid inputs, missing parameters
4. **Check error messages**: Ensure errors are clear and actionable
5. **Validate JSON schemas**: Confirm inputSchema works as expected
6. **Test with Claude Desktop**: Only after Inspector validation passes

</mcp_inspector>

<log_analysis>
**Effective Logging for Debugging**:

```typescript
// TypeScript - Structured logging with context
import winston from "winston";

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({ stream: process.stderr }),
  ],
});

// Log with context
logger.info("Tool called", {
  tool: "search_repos",
  args: { query: "machine learning" },
  user: request.context?.user,
  requestId: generateRequestId(),
});
```

```python
# Python - Debug mode with detailed tracing
import logging
import sys

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stderr  # IMPORTANT: stderr, not stdout
)

logger = logging.getLogger(__name__)

@mcp.tool()
async def search_repos(query: str) -> str:
    logger.debug(f"search_repos called with query: {query}")
    try:
        result = await perform_search(query)
        logger.debug(f"search_repos returned {len(result)} results")
        return result
    except Exception as e:
        logger.error(f"search_repos failed: {e}", exc_info=True)
        raise
```

**Claude Desktop Logs**:

```bash
# macOS
tail -f ~/Library/Logs/Claude/mcp-server-your-server-name.log

# Look for:
# - Server startup errors
# - Tool execution failures
# - Protocol errors
# - Dependency issues
```

**Common Debugging Patterns**:

1. **Tools not appearing**: Check `tools/list` handler and tool descriptions
2. **Tool calls failing**: Check input schema validation and error messages
3. **Server not starting**: Check dependencies, imports, and syntax errors
4. **Slow responses**: Add timing logs around expensive operations
5. **Intermittent failures**: Check for race conditions in async code

</log_analysis>

## Monitoring & Observability

<production_monitoring>
**Metrics Collection**:

Track key metrics for production MCP servers:

```typescript
// TypeScript - Prometheus metrics
import { Counter, Histogram, Registry } from "prom-client";

const registry = new Registry();

const toolCallsTotal = new Counter({
  name: "mcp_tool_calls_total",
  help: "Total number of tool calls",
  labelNames: ["tool_name", "status"],
  registers: [registry],
});

const toolDuration = new Histogram({
  name: "mcp_tool_duration_seconds",
  help: "Tool execution duration",
  labelNames: ["tool_name"],
  registers: [registry],
});

// Instrument tool calls
async function callTool(name: string, args: any) {
  const end = toolDuration.labels(name).startTimer();

  try {
    const result = await executeTool(name, args);
    toolCallsTotal.labels(name, "success").inc();
    return result;
  } catch (error) {
    toolCallsTotal.labels(name, "error").inc();
    throw error;
  } finally {
    end();
  }
}

// Expose metrics endpoint
app.get("/metrics", async (req, res) => {
  res.set("Content-Type", registry.contentType);
  res.end(await registry.metrics());
});
```

```python
# Python - Custom metrics tracking
from dataclasses import dataclass
from datetime import datetime
from collections import defaultdict

@dataclass
class ToolMetrics:
    call_count: int = 0
    error_count: int = 0
    total_duration: float = 0.0

metrics = defaultdict(ToolMetrics)

@mcp.tool()
async def tracked_tool(args: str) -> str:
    """Tool with automatic metrics tracking."""
    start = datetime.now()
    tool_name = "tracked_tool"

    try:
        result = await perform_operation(args)
        metrics[tool_name].call_count += 1
        return result
    except Exception as e:
        metrics[tool_name].error_count += 1
        raise
    finally:
        duration = (datetime.now() - start).total_seconds()
        metrics[tool_name].total_duration += duration

# Expose metrics as a tool
@mcp.tool()
async def get_metrics() -> dict:
    """Get server metrics."""
    return {
        tool: {
            "calls": m.call_count,
            "errors": m.error_count,
            "avg_duration": m.total_duration / m.call_count if m.call_count > 0 else 0,
        }
        for tool, m in metrics.items()
    }
```

**Key Metrics to Track**:

- **Tool call count** (by tool name, by status)
- **Tool duration** (p50, p95, p99)
- **Error rate** (by tool, by error type)
- **Resource read count** (by URI pattern)
- **Active sessions** (for stateful servers)
- **Memory usage** (especially for long-running servers)
- **External API latency** (for wrapper MCPs)

**Alerting**:

Set up alerts for:
- Error rate > 5%
- p95 latency > 5 seconds
- Memory usage > 80%
- External API failures
- Server restarts/crashes

</production_monitoring>

## Documentation Standards

<readme_template>
**MCP Server README Template**:

Every MCP server should have a comprehensive README:

```markdown
# MCP Server Name

Brief description (one sentence).

## Features

- Feature 1 with specific benefit
- Feature 2 with specific benefit
- Feature 3 with specific benefit

## Installation

### Prerequisites

- Python 3.10+ / Node.js 18+
- Required API keys or credentials
- Any system dependencies

### Using uv (Recommended)

\```bash
# Development
uv run mcp dev server.py

# Claude Desktop
uv run mcp install server.py --name "Server Name"
\```

### Using pip

\```bash
pip install mcp-server-name

# Or from source
git clone https://github.com/user/mcp-server-name.git
cd mcp-server-name
uv sync
\```

## Configuration

### Claude Desktop

Add to `claude_desktop_config.json`:

\```json
{
  "mcpServers": {
    "server-name": {
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/server",
        "run",
        "python",
        "server.py"
      ],
      "env": {
        "API_KEY": "your-api-key-here"
      }
    }
  }
}
\```

### Environment Variables

- `API_KEY` (required): Your API key from [provider]
- `DEBUG` (optional): Set to `true` for debug logging
- `TIMEOUT` (optional): Request timeout in seconds (default: 30)

## Available Tools

### `tool_name`

Description of what this tool does and when to use it.

**Parameters:**
- `param1` (string, required): Description
- `param2` (number, optional): Description

**Returns:** Description of return value

**Example:**
\```json
{
  "tool": "tool_name",
  "arguments": {
    "param1": "value",
    "param2": 42
  }
}
\```

## Available Resources

### `resource://uri/pattern/{param}`

Description of this resource and its data.

## Troubleshooting

### Server not starting

- Check that all dependencies are installed
- Verify API keys are set correctly
- Check server logs at `~/Library/Logs/Claude/mcp-server-name.log`

### Tool calls failing

- Verify input parameters match the schema
- Check API rate limits
- See debug logs with `DEBUG=true`

## Development

\```bash
# Run tests
uv run pytest

# Type checking
uv run mypy src/

# Linting
uv run ruff check src/
\```

## License

MIT
```

</readme_template>

## Versioning & Lifecycle

<versioning_strategy>
**Semantic Versioning for MCP Servers**:

Follow semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes (removed tools, changed schemas, renamed parameters)
- **MINOR**: New features (new tools, new optional parameters)
- **PATCH**: Bug fixes (no API changes)

**Handling Breaking Changes**:

```typescript
// Version detection
const server = new Server({
  name: "my-server",
  version: "2.0.0",  // Incremented from 1.x
});

// Graceful deprecation
server.setRequestHandler("tools/list", async () => ({
  tools: [
    {
      name: "search_repos_v2",  // New tool
      description: "Search repositories (v2 with pagination)",
    },
    {
      name: "search_repos",  // Deprecated but still works
      description: "Search repositories (DEPRECATED: Use search_repos_v2)",
      deprecated: true,  // Signal to clients
    },
  ],
}));

// Version-aware handling
server.setRequestHandler("tools/call", async (request) => {
  if (request.params.name === "search_repos") {
    // Log deprecation warning
    logger.warn("Deprecated tool called", { tool: "search_repos" });

    // Still execute for backward compatibility
    return await handleLegacySearch(request.params.arguments);
  }

  if (request.params.name === "search_repos_v2") {
    return await handleNewSearch(request.params.arguments);
  }
});
```

**Migration Guides**:

When releasing breaking changes, provide migration guides:

```markdown
## Migrating from v1 to v2

### Breaking Changes

1. **Tool renamed**: `get_data` → `fetch_data`
   - **Before**: `get_data(id: string)`
   - **After**: `fetch_data(resource_id: string)`
   - **Migration**: Rename tool and parameter

2. **Schema change**: `search` now requires `query` parameter
   - **Before**: `search(terms: string)`
   - **After**: `search(query: string, filters?: object)`
   - **Migration**: Rename `terms` to `query`, add optional `filters`

3. **Removed tool**: `deprecated_tool`
   - **Alternative**: Use `new_tool` instead
   - **Migration**: See examples below

### Migration Examples

\```typescript
// v1
await callTool("get_data", { id: "123" });

// v2
await callTool("fetch_data", { resource_id: "123" });
\```
```

**Deprecation Timeline**:

1. **Version N**: Announce deprecation, keep functionality
2. **Version N+1**: Add warnings to logs
3. **Version N+2**: Remove deprecated features (MAJOR bump)

Maintain backward compatibility for at least 2 minor versions before breaking changes.

</versioning_strategy>

## Advanced Patterns

<multi_tenancy>
**Multi-Tenancy**:

Support multiple organizations/users in a single server:

```typescript
// TypeScript - Tenant isolation
interface TenantContext {
  tenantId: string;
  apiKey: string;
  config: TenantConfig;
}

class MultiTenantMCP {
  private tenants = new Map<string, TenantContext>();

  async loadTenant(tenantId: string): Promise<TenantContext> {
    // Load from database or config
    return {
      tenantId,
      apiKey: await getApiKey(tenantId),
      config: await getTenantConfig(tenantId),
    };
  }

  async handleToolCall(toolName: string, args: any, tenantId: string) {
    // Isolate by tenant
    const tenant = await this.loadTenant(tenantId);

    // Use tenant-specific API key
    const result = await externalAPI.call({
      apiKey: tenant.apiKey,
      config: tenant.config,
      ...args,
    });

    return result;
  }
}
```

```python
# Python - Tenant context per request
from contextvars import ContextVar

current_tenant = ContextVar("current_tenant", default=None)

@dataclass
class TenantContext:
    tenant_id: str
    api_key: str
    rate_limit: int

@mcp.tool()
async def tenant_aware_tool(query: str, ctx: Context) -> str:
    """Tool that respects tenant isolation."""
    # Extract tenant from request context
    tenant_id = ctx.request_context.metadata.get("tenant_id")
    tenant = await load_tenant(tenant_id)

    # Set tenant context for this request
    current_tenant.set(tenant)

    # Use tenant-specific configuration
    result = await external_api.query(
        query,
        api_key=tenant.api_key,
        rate_limit=tenant.rate_limit,
    )

    return result
```

**Key Considerations**:
- Isolate data by tenant ID
- Use tenant-specific API keys/credentials
- Enforce per-tenant rate limits
- Log with tenant context for debugging
- Consider database row-level security
- Test cross-tenant data leakage scenarios

</multi_tenancy>

<stateful_vs_stateless>
**Stateful vs Stateless Design**:

**Stateful Servers** (maintain session state):

```python
# Good for: Multi-step workflows, conversation context
mcp = FastMCP("Stateful Server")

# State persists across tool calls in same session
session_state = {}

@mcp.tool()
async def start_workflow(name: str, ctx: Context) -> str:
    """Start a multi-step workflow."""
    session_id = ctx.request_context.session_id
    session_state[session_id] = {
        "workflow_name": name,
        "step": 1,
        "data": {},
    }
    return f"Workflow '{name}' started"

@mcp.tool()
async def next_step(data: dict, ctx: Context) -> str:
    """Continue workflow with next step."""
    session_id = ctx.request_context.session_id
    state = session_state.get(session_id)

    if not state:
        return "Error: No active workflow"

    state["step"] += 1
    state["data"].update(data)
    return f"Step {state['step']} completed"
```

**Stateless Servers** (no session state):

```python
# Good for: Simple operations, horizontal scaling
mcp = FastMCP("Stateless Server", stateless_http=True)

@mcp.tool()
async def calculate(expression: str) -> float:
    """Pure function - no state needed."""
    return eval(expression)  # (Don't actually use eval!)

@mcp.tool()
async def fetch_data(id: str) -> dict:
    """Fetch from external source - no local state."""
    return await database.get(id)
```

**Decision Matrix**:

| Use Case | Recommendation |
|----------|---------------|
| Simple data fetching | Stateless |
| Multi-step workflows | Stateful |
| Need horizontal scaling | Stateless |
| Conversational context | Stateful |
| High traffic, simple ops | Stateless |
| Complex user sessions | Stateful |

</stateful_vs_stateless>

<idempotency>
**Idempotency for Safe Retries**:

Make operations safe to retry:

```typescript
// TypeScript - Idempotent operations
async function createResource(id: string, data: any) {
  // Check if already exists
  const existing = await database.findById(id);
  if (existing) {
    // Return existing instead of erroring
    return existing;
  }

  // Create only if doesn't exist
  return await database.create({ id, ...data });
}

// Idempotency keys for external APIs
async function chargePayment(amount: number, idempotencyKey: string) {
  return await stripe.charges.create(
    { amount, currency: "usd" },
    { idempotencyKey }  // Stripe handles duplicates
  );
}
```

```python
# Python - Idempotent tool with duplicate detection
@mcp.tool()
async def create_order(order_id: str, items: list[dict]) -> dict:
    """Create order (idempotent - safe to retry)."""
    # Check if already exists
    existing = await db.orders.find_one({"order_id": order_id})
    if existing:
        logger.info(f"Order {order_id} already exists, returning existing")
        return existing

    # Create only if doesn't exist
    order = await db.orders.insert_one({
        "order_id": order_id,
        "items": items,
        "created_at": datetime.now(),
    })

    return order
```

**Idempotency Patterns**:
- Use client-provided IDs (not auto-increment)
- Check-then-create with unique constraints
- Idempotency keys for external API calls
- Status checks before state changes
- Return existing result for duplicate requests

</idempotency>

<graceful_degradation>
**Graceful Degradation**:

Handle dependency failures gracefully:

```typescript
// TypeScript - Fallback strategies
async function searchWithFallback(query: string) {
  try {
    // Try primary search API
    return await primaryAPI.search(query);
  } catch (error) {
    logger.warn("Primary search failed, using fallback", { error });

    try {
      // Fallback to secondary API
      return await secondaryAPI.search(query);
    } catch (fallbackError) {
      // Return cached results if available
      const cached = await cache.get(`search:${query}`);
      if (cached) {
        logger.info("Returning cached results");
        return cached;
      }

      // Ultimate fallback: return partial results
      return {
        results: [],
        error: "Search temporarily unavailable",
        fallback: true,
      };
    }
  }
}
```

```python
# Python - Circuit breaker pattern
from datetime import datetime, timedelta

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, timeout: int = 60):
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.last_failure: datetime | None = None
        self.state = "closed"  # closed, open, half-open

    async def call(self, func, *args, **kwargs):
        if self.state == "open":
            # Check if timeout elapsed
            if datetime.now() - self.last_failure > timedelta(seconds=self.timeout):
                self.state = "half-open"
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = await func(*args, **kwargs)
            # Success - reset on half-open
            if self.state == "half-open":
                self.state = "closed"
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure = datetime.now()

            if self.failure_count >= self.failure_threshold:
                self.state = "open"
                logger.error("Circuit breaker opened")

            raise

# Usage
breaker = CircuitBreaker(failure_threshold=3, timeout=60)

@mcp.tool()
async def fetch_with_protection(url: str) -> str:
    """Fetch with circuit breaker protection."""
    try:
        return await breaker.call(fetch_url, url)
    except Exception as e:
        # Return degraded response
        return f"Service temporarily unavailable: {e}"
```

**Degradation Strategies**:
- Primary → Fallback → Cache → Minimal response
- Circuit breakers for failing dependencies
- Timeouts on all external calls
- Partial results better than errors
- Clear error messages about degraded state

</graceful_degradation>

<cost_optimization>
**Cost Optimization for API Wrappers**:

Reduce costs when wrapping paid APIs:

```typescript
// TypeScript - Intelligent caching
class CostOptimizedAPI {
  private cache = new LRUCache({ max: 1000, ttl: 1000 * 60 * 5 });

  async query(params: QueryParams) {
    const cacheKey = JSON.stringify(params);

    // Check cache first
    const cached = this.cache.get(cacheKey);
    if (cached) {
      logger.info("Cache hit - saved API call", { params });
      return cached;
    }

    // Call expensive API
    const result = await expensiveAPI.call(params);

    // Cache for reuse
    this.cache.set(cacheKey, result);

    // Track cost
    await trackCost(params, estimatedCost(params));

    return result;
  }
}

// Request deduplication
class RequestDeduplicator {
  private pending = new Map();

  async deduplicate(key: string, fn: () => Promise<any>) {
    // Check if request already in flight
    if (this.pending.has(key)) {
      logger.info("Deduplicating request", { key });
      return await this.pending.get(key);
    }

    // Execute and share result
    const promise = fn();
    this.pending.set(key, promise);

    try {
      const result = await promise;
      return result;
    } finally {
      this.pending.delete(key);
    }
  }
}
```

```python
# Python - Batching for bulk operations
class BatchingAPI:
    def __init__(self, batch_size: int = 10, batch_delay: float = 0.1):
        self.batch_size = batch_size
        self.batch_delay = batch_delay
        self.pending_requests: list = []

    async def query(self, item_id: str) -> dict:
        """Query single item - automatically batched."""
        # Add to batch
        future = asyncio.Future()
        self.pending_requests.append((item_id, future))

        # Trigger batch if full
        if len(self.pending_requests) >= self.batch_size:
            await self._process_batch()

        # Wait for result
        return await future

    async def _process_batch(self):
        """Process batch of requests in single API call."""
        if not self.pending_requests:
            return

        batch = self.pending_requests[:]
        self.pending_requests.clear()

        # Single API call for entire batch
        item_ids = [item_id for item_id, _ in batch]
        results = await api.batch_get(item_ids)

        # Distribute results to futures
        for (item_id, future), result in zip(batch, results):
            future.set_result(result)

# Usage
batcher = BatchingAPI(batch_size=10)

@mcp.tool()
async def get_items(ids: list[str]) -> list[dict]:
    """Get multiple items (automatically batched)."""
    return await asyncio.gather(*[batcher.query(id) for id in ids])
```

**Cost Reduction Strategies**:
- Aggressive caching (with appropriate TTLs)
- Request deduplication (multiple requests → one API call)
- Batching (combine N requests → single batch call)
- Rate limiting (prevent runaway costs)
- Cost tracking and alerts
- Cheaper alternatives for non-critical data
- Partial results when possible (don't fetch everything)

</cost_optimization>

# MCP Tools and Resources - Advanced Patterns

<overview>
Tools and Resources are the primary ways MCP servers expose functionality. This guide covers advanced patterns, best practices, and real-world examples for both primitives.
</overview>

## Tools: Deep Dive

<tool_design_principles>

**What makes a good tool?**

1. **Single responsibility**: Each tool does one thing well
2. **Clear description**: Claude knows when to use it
3. **Strict schema**: Input validation prevents errors
4. **Predictable output**: Consistent response format
5. **Error messages**: Help Claude understand what went wrong

**Examples**:

✅ **Good**: `search_emails(query: string, limit: number) -> SearchResults`
- Clear purpose, predictable output

❌ **Bad**: `do_stuff(action: string, params: any) -> any`
- Vague purpose, unpredictable output

</tool_design_principles>

<input_schemas>

## Input Schema Best Practices

**TypeScript (Zod)**:
```typescript
import { z } from "zod";

// Strict validation with helpful descriptions
const EmailSearchSchema = z.object({
  query: z.string()
    .min(1, "Query cannot be empty")
    .max(500, "Query too long")
    .describe("Search query for email content"),

  from: z.string()
    .email("Must be valid email address")
    .optional()
    .describe("Filter by sender email"),

  date_range: z.object({
    start: z.string().datetime().describe("Start date (ISO 8601)"),
    end: z.string().datetime().describe("End date (ISO 8601)"),
  }).optional().describe("Filter by date range"),

  limit: z.number()
    .int("Must be integer")
    .min(1, "Minimum 1 result")
    .max(100, "Maximum 100 results")
    .default(10)
    .describe("Maximum number of results"),

  include_attachments: z.boolean()
    .default(false)
    .describe("Include emails with attachments only"),
});
```

**Python (Pydantic)**:
```python
from pydantic import BaseModel, Field, EmailStr, field_validator
from datetime import datetime

class DateRange(BaseModel):
    """Date range filter."""
    start: datetime = Field(description="Start date")
    end: datetime = Field(description="End date")

    @field_validator('end')
    @classmethod
    def validate_range(cls, v: datetime, info) -> datetime:
        if 'start' in info.data and v < info.data['start']:
            raise ValueError("End date must be after start date")
        return v

class EmailSearchArgs(BaseModel):
    """Email search arguments."""
    query: str = Field(
        min_length=1,
        max_length=500,
        description="Search query for email content"
    )
    from_: EmailStr | None = Field(
        default=None,
        alias="from",
        description="Filter by sender email"
    )
    date_range: DateRange | None = Field(
        default=None,
        description="Filter by date range"
    )
    limit: int = Field(
        default=10,
        ge=1,
        le=100,
        description="Maximum number of results"
    )
    include_attachments: bool = Field(
        default=False,
        description="Include emails with attachments only"
    )
```

**Key takeaways**:
- Use `.describe()` / `description=` on every field
- Set sensible limits (min/max length, ranges)
- Provide defaults for optional parameters
- Validate relationships between fields
- Use domain-specific types (email, URL, datetime)

</input_schemas>

<output_formats>

## Output Formats

<text_content>
**Text Content** (most common):

```typescript
// TypeScript
return {
  content: [
    {
      type: "text",
      text: "Search results:\n\n1. Email from john@example.com...",
    },
  ],
};
```

```python
# Python
return [TextContent(
    type="text",
    text="Search results:\n\n1. Email from john@example.com..."
)]
```

**When to use**: General purpose results, formatted text, JSON data
</text_content>

<image_content>
**Image Content**:

```typescript
// TypeScript
return {
  content: [
    {
      type: "image",
      data: base64ImageData,
      mimeType: "image/png",
    },
  ],
};
```

```python
# Python
return [ImageContent(
    type="image",
    data=base64_image_data,
    mimeType="image/png"
)]
```

**When to use**: Charts, screenshots, diagrams, generated images
</image_content>

<embedded_resource>
**Embedded Resource**:

```typescript
// TypeScript
return {
  content: [
    {
      type: "resource",
      resource: {
        uri: "email://inbox/12345",
        name: "Email from john@example.com",
        mimeType: "message/rfc822",
        text: emailContent,
      },
    },
  ],
};
```

```python
# Python
return [EmbeddedResource(
    type="resource",
    resource={
        "uri": "email://inbox/12345",
        "name": "Email from john@example.com",
        "mimeType": "message/rfc822",
        "text": email_content,
    }
)]
```

**When to use**: Returning data that could be read as a resource later
</embedded_resource>

<multiple_content>
**Multiple Content Items**:

```typescript
// TypeScript - return multiple pieces of content
return {
  content: [
    {
      type: "text",
      text: "Analysis complete. Here are the results:",
    },
    {
      type: "image",
      data: chartImageBase64,
      mimeType: "image/png",
    },
    {
      type: "text",
      text: "Detailed findings:\n\n...",
    },
  ],
};
```

**When to use**: Complex results with mixed content types
</multiple_content>

</output_formats>

<tool_patterns>

## Common Tool Patterns

<api_client_tool>
**API Client Tool**:

```python
import aiohttp
from typing import Any

class APIClientArgs(BaseModel):
    endpoint: str = Field(description="API endpoint path")
    method: str = Field(default="GET", pattern="^(GET|POST|PUT|DELETE)$")
    body: dict[str, Any] | None = Field(default=None, description="Request body")
    headers: dict[str, str] | None = Field(default=None, description="Custom headers")

async def api_client_tool(args: APIClientArgs) -> TextContent:
    """Generic API client tool."""
    url = f"{config.api_base_url}{args.endpoint}"

    headers = {
        "Authorization": f"Bearer {config.api_key}",
        **(args.headers or {}),
    }

    async with aiohttp.ClientSession() as session:
        async with session.request(
            method=args.method,
            url=url,
            json=args.body,
            headers=headers,
        ) as response:
            response.raise_for_status()
            data = await response.json()

            return TextContent(
                type="text",
                text=json.dumps(data, indent=2)
            )
```
</api_client_tool>

<file_operation_tool>
**File Operation Tool**:

```typescript
import { z } from "zod";
import fs from "fs/promises";
import path from "path";

const WriteFileSchema = z.object({
  path: z.string().describe("File path to write"),
  content: z.string().describe("Content to write"),
  mode: z.enum(["overwrite", "append"]).default("overwrite"),
});

async function writeFileTool(args: z.infer<typeof WriteFileSchema>) {
  // Security: Restrict to allowed directories
  const allowedDir = "/Users/user/documents";
  const fullPath = path.resolve(allowedDir, args.path);

  if (!fullPath.startsWith(allowedDir)) {
    throw new Error("Access denied: Path outside allowed directory");
  }

  // Ensure directory exists
  await fs.mkdir(path.dirname(fullPath), { recursive: true });

  // Write file
  if (args.mode === "append") {
    await fs.appendFile(fullPath, args.content);
  } else {
    await fs.writeFile(fullPath, args.content);
  }

  return {
    content: [
      {
        type: "text",
        text: `File written: ${args.path} (${args.content.length} bytes)`,
      },
    ],
  };
}
```
</file_operation_tool>

<database_query_tool>
**Database Query Tool**:

```python
import asyncpg
from typing import Any

class QueryArgs(BaseModel):
    query: str = Field(description="SQL query to execute")
    params: list[Any] | None = Field(default=None, description="Query parameters")
    limit: int = Field(default=100, ge=1, le=1000, description="Row limit")

async def database_query_tool(args: QueryArgs) -> TextContent:
    """Execute database query."""
    # Connect to database
    conn = await asyncpg.connect(
        host=config.db_host,
        database=config.db_name,
        user=config.db_user,
        password=config.db_password,
    )

    try:
        # Security: Use parameterized queries
        query = f"{args.query} LIMIT {args.limit}"
        rows = await conn.fetch(query, *(args.params or []))

        # Format results
        results = [dict(row) for row in rows]

        return TextContent(
            type="text",
            text=json.dumps(results, indent=2, default=str)
        )
    finally:
        await conn.close()
```
</database_query_tool>

<batch_processing_tool>
**Batch Processing Tool**:

```typescript
const BatchProcessSchema = z.object({
  items: z.array(z.string()).min(1).max(100),
  operation: z.enum(["validate", "transform", "analyze"]),
});

async function batchProcessTool(args: z.infer<typeof BatchProcessSchema>) {
  const results = [];

  for (const item of args.items) {
    try {
      const result = await processItem(item, args.operation);
      results.push({ item, status: "success", result });
    } catch (error) {
      results.push({
        item,
        status: "error",
        error: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }

  const successCount = results.filter((r) => r.status === "success").length;

  return {
    content: [
      {
        type: "text",
        text: `Processed ${args.items.length} items: ${successCount} succeeded, ${
          args.items.length - successCount
        } failed\n\n${JSON.stringify(results, null, 2)}`,
      },
    ],
  };
}
```
</batch_processing_tool>

</tool_patterns>

## Resources: Deep Dive

<resource_design_principles>

**What makes a good resource?**

1. **Logical URI scheme**: Consistent, hierarchical addressing
2. **Clear naming**: Resource purpose is obvious
3. **Appropriate mime types**: Helps Claude understand content
4. **Template support**: Use URI templates for dynamic resources
5. **Efficient reading**: Don't load everything at once

**URI Scheme Examples**:

```
file:///{path}                    - File system
db:///{table}/{id}                - Database records
api:///{service}/{endpoint}       - API endpoints
config:///{section}               - Configuration
email:///{folder}/{id}            - Email messages
doc:///{category}/{id}            - Documentation
```

</resource_design_principles>

<resource_patterns>

## Common Resource Patterns

<file_system_resource>
**File System Resource**:

```python
import aiofiles
import os
from pathlib import Path

@app.list_resources()
async def list_resources() -> list[Resource]:
    """List file system resources."""
    base_dir = Path("/Users/user/documents")

    resources = [
        Resource(
            uri="file:///{path}",
            name="File System",
            description="Read files from documents directory",
            mimeType="text/plain",
        )
    ]

    # Also list recent files
    for file_path in base_dir.glob("**/*.txt"):
        rel_path = file_path.relative_to(base_dir)
        resources.append(Resource(
            uri=f"file:///{rel_path}",
            name=file_path.name,
            description=f"Text file: {rel_path}",
            mimeType="text/plain",
        ))

    return resources

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read file system resource."""
    if uri.startswith("file:///"):
        path = uri[8:]  # Remove "file:///"
        full_path = Path("/Users/user/documents") / path

        # Security check
        if not str(full_path).startswith("/Users/user/documents"):
            raise ValueError("Access denied")

        if not full_path.exists():
            raise ValueError(f"File not found: {path}")

        async with aiofiles.open(full_path, "r") as f:
            return await f.read()

    raise ValueError(f"Unknown resource: {uri}")
```
</file_system_resource>

<database_resource>
**Database Resource**:

```typescript
// List database resources
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  const tables = await db.query("SELECT table_name FROM information_schema.tables");

  const resources: Resource[] = tables.rows.map((row) => ({
    uri: `db:///${row.table_name}/{id}`,
    name: `${row.table_name} table`,
    description: `Database table: ${row.table_name}`,
    mimeType: "application/json",
  }));

  return { resources };
});

// Read database resource
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;
  const match = uri.match(/^db:\/\/\/([^/]+)\/(.+)$/);

  if (match) {
    const [, table, id] = match;

    // Security: Validate table name against whitelist
    const allowedTables = ["users", "posts", "comments"];
    if (!allowedTables.includes(table)) {
      throw new Error(`Access denied: ${table}`);
    }

    const result = await db.query(
      `SELECT * FROM ${table} WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      throw new Error(`Record not found: ${table}/${id}`);
    }

    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify(result.rows[0], null, 2),
        },
      ],
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});
```
</database_resource>

<api_resource>
**API Resource**:

```python
@app.list_resources()
async def list_resources() -> list[Resource]:
    """List API endpoint resources."""
    return [
        Resource(
            uri="api:///users/{user_id}",
            name="User Profile",
            description="Get user profile by ID",
            mimeType="application/json",
        ),
        Resource(
            uri="api:///posts/{post_id}",
            name="Blog Post",
            description="Get blog post by ID",
            mimeType="application/json",
        ),
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Read API resource."""
    if uri.startswith("api:///users/"):
        user_id = uri.split("/")[-1]
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f"{config.api_url}/users/{user_id}",
                headers={"Authorization": f"Bearer {config.api_key}"}
            ) as response:
                response.raise_for_status()
                data = await response.json()
                return json.dumps(data, indent=2)

    elif uri.startswith("api:///posts/"):
        post_id = uri.split("/")[-1]
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f"{config.api_url}/posts/{post_id}",
                headers={"Authorization": f"Bearer {config.api_key}"}
            ) as response:
                response.raise_for_status()
                data = await response.json()
                return json.dumps(data, indent=2)

    raise ValueError(f"Unknown resource: {uri}")
```
</api_resource>

<configuration_resource>
**Configuration Resource**:

```typescript
// List configuration resources
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: "config:///server",
        name: "Server Configuration",
        description: "Server settings and metadata",
        mimeType: "application/json",
      },
      {
        uri: "config:///api",
        name: "API Configuration",
        description: "API endpoints and credentials",
        mimeType: "application/json",
      },
    ],
  };
});

// Read configuration resource
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;

  if (uri === "config:///server") {
    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify(
            {
              name: SERVER_NAME,
              version: SERVER_VERSION,
              capabilities: ["tools", "resources"],
            },
            null,
            2
          ),
        },
      ],
    };
  }

  if (uri === "config:///api") {
    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify(
            {
              endpoint: config.apiEndpoint,
              timeout: config.timeout,
              // Don't expose secrets!
            },
            null,
            2
          ),
        },
      ],
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});
```
</configuration_resource>

</resource_patterns>

<pagination>

## Pagination for Large Resources

**Paginated Resource Pattern**:

```python
class PaginatedReadArgs(BaseModel):
    """Arguments for paginated resource reading."""
    uri: str
    offset: int = Field(default=0, ge=0, description="Starting offset")
    limit: int = Field(default=100, ge=1, le=1000, description="Items per page")

async def read_large_resource(uri: str, offset: int = 0, limit: int = 100) -> str:
    """Read resource with pagination."""
    if uri == "db:///logs":
        conn = await asyncpg.connect(config.db_url)
        try:
            rows = await conn.fetch(
                "SELECT * FROM logs ORDER BY timestamp DESC OFFSET $1 LIMIT $2",
                offset,
                limit
            )
            total = await conn.fetchval("SELECT COUNT(*) FROM logs")

            return json.dumps({
                "data": [dict(row) for row in rows],
                "pagination": {
                    "offset": offset,
                    "limit": limit,
                    "total": total,
                    "has_more": offset + limit < total,
                },
            }, indent=2, default=str)
        finally:
            await conn.close()

    raise ValueError(f"Unknown resource: {uri}")
```

</pagination>

## Scaling to Large APIs

<large_api_note>
**Building a server that wraps APIs with 20+ operations?**

The patterns above work well for small to medium servers (< 20 tools). However, if you're wrapping a large API (GitHub, Stripe, Slack, etc.), each tool definition consumes tokens in Claude's context window.

**Problem:** 50+ tools can consume 8,000-15,000 tokens just in tool definitions, before any actual conversation begins.

**Solution:** Use the **meta-tools + resources pattern** to achieve 90-98% context reduction by loading operation schemas on-demand instead of upfront.

See [Large API Pattern](large-api-pattern.md) for:
- Complete architecture guide
- Real metrics (15,000 → 300 tokens)
- When to use (and when not to use)
- Implementation examples
- Production results

This pattern is essential for servers wrapping APIs with 50+ operations.
</large_api_note>

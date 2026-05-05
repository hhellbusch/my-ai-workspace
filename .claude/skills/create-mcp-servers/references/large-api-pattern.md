# Resources-Based MCP Server Pattern

<overview>
**Achieving 98% Context Reduction Through On-Demand Operation Loading**

When wrapping large APIs (50+ operations) in MCP servers, traditional architecture consumes 15,000-30,000 tokens just loading tool definitions. This pattern reduces that overhead to ~300 tokens while maintaining full functionality.

This guide explains the architectural pattern used in production servers to achieve 90-98% context reduction.
</overview>

## The Problem

<traditional_architecture>
**Traditional MCP Server Architecture**

Most MCP servers expose operations as individual tools:

```python
@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(name="operation_1", description="...", inputSchema={...}),
        Tool(name="operation_2", description="...", inputSchema={...}),
        Tool(name="operation_3", description="...", inputSchema={...}),
        # ... 78 more tools
    ]
```

**Problem:** Every tool definition is sent to Claude on every conversation start, consuming massive context before any actual work begins.

**Real metrics with 81 operations:**
- Tool definitions: ~15,000 tokens
- Context available for conversation: 185,000 tokens (200k - 15k)
- Overhead: 7.5% of available context wasted on metadata

For APIs with 100+ operations, this can consume 20,000-30,000 tokens or more.
</traditional_architecture>

## The Solution

<resources_based_architecture>
**Resources-Based Architecture**

Instead of loading all tools upfront, expose a minimal set of **meta-tools** for discovery and execution, with operation schemas stored as **MCP resources** that are loaded on-demand.

```python
@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(name="discover", description="Browse available operations"),
        Tool(name="get_schema", description="Get operation parameters"),
        Tool(name="execute", description="Execute an operation"),
        Tool(name="continue", description="Paginate large responses")
    ]
```

**Result:** Only 4 tool definitions loaded upfront (~300 tokens), with 81 operation schemas available as resources.
</resources_based_architecture>

## How It Works

<meta_tools_layer>
### Meta-Tools Layer

Four tools handle all interactions:

**`discover` - Operation Discovery**
```python
Tool(
    name="circle_discover",
    description="Browse all available Circle operations organized by category",
    inputSchema={"type": "object", "properties": {}}
)
```
Returns hierarchical tree of all available operations.

**`get_schema` - Schema Retrieval**
```python
Tool(
    name="circle_get_schema",
    description="Get detailed schema for a specific operation",
    inputSchema={
        "type": "object",
        "properties": {
            "operation": {
                "type": "string",
                "description": "Operation identifier (e.g., 'posts.create')"
            }
        }
    }
)
```
Returns full parameter schema for one operation.

**`execute` - Operation Execution**
```python
Tool(
    name="circle_execute",
    description="Execute a Circle operation with parameters",
    inputSchema={
        "type": "object",
        "properties": {
            "operation": {"type": "string"},
            "params": {"type": "object"}
        }
    }
)
```
Routes to actual implementation based on operation string.

**`continue` - Pagination**
```python
Tool(
    name="circle_continue",
    description="Continue retrieving paginated results",
    inputSchema={
        "type": "object",
        "properties": {
            "session_id": {"type": "string"}
        }
    }
)
```
Handles chunked responses for large datasets.
</meta_tools_layer>

<operations_schema>
### Operations Schema File

All operation definitions live in `operations.json`:

```json
{
  "operations": {
    "posts": {
      "list": {
        "name": "circle_list_posts",
        "description": "List posts in Circle",
        "inputSchema": {
          "type": "object",
          "properties": {
            "space_id": {"type": "integer"},
            "page": {"type": "integer"},
            "per_page": {"type": "integer"}
          }
        }
      },
      "create": {
        "name": "circle_create_post",
        "description": "Create a new post",
        "inputSchema": { ... }
      }
    },
    "members": { ... },
    "events": { ... }
  }
}
```
</operations_schema>

<mcp_resources>
### MCP Resources API

Operations are exposed as resources with hierarchical URIs:

```python
@server.list_resources()
async def list_resources() -> list[Resource]:
    resources = []

    # Index resource (full tree)
    resources.append(Resource(
        uri="circle://operations/index",
        name="Operations Index",
        description="Complete tree of all operations"
    ))

    # Category resources
    for category in OPERATIONS.keys():
        resources.append(Resource(
            uri=f"circle://operations/{category}",
            name=f"{category} Operations"
        ))

    # Individual operations
    for category, actions in OPERATIONS.items():
        for action, schema in actions.items():
            resources.append(Resource(
                uri=f"circle://operations/{category}/{action}",
                name=schema["name"],
                description=schema["description"]
            ))

    return resources
```

**Claude can:**
- Browse `circle://operations/index` to see all operations
- Read `circle://operations/posts/create` to get schema
- Never loads operations it doesn't use in a conversation
</mcp_resources>

<operation_dispatch>
### Operation Dispatch

Map operation strings to actual implementations:

```python
def _operation_to_tool_name(operation: str) -> str:
    """Convert 'posts.create' -> 'circle_create_post'"""
    parts = operation.split(".")
    category, action = parts
    return f"circle_{action}_{category.rstrip('s')}"

def _get_tool_handlers(client):
    """Build dispatch dictionary"""
    return {
        "circle_list_posts": client.list_posts,
        "circle_create_post": client.create_post,
        "circle_get_post": client.get_post,
        # ... all other operations
    }

@server.call_tool()
async def call_tool(name: str, arguments: Any):
    if name == "circle_execute":
        operation = arguments["operation"]
        params = arguments["params"]

        # Convert operation string to handler
        tool_name = _operation_to_tool_name(operation)
        handlers = _get_tool_handlers(client)
        handler = handlers[tool_name]

        # Execute
        result = await handler(**params)
        return [TextContent(type="text", text=json.dumps(result))]
```
</operation_dispatch>

## Implementation Guide

<step_1>
### Step 1: Design Your Operation Namespace

Organize operations hierarchically:

```
posts/
  ├── list
  ├── create
  ├── get
  ├── update
  └── delete
members/
  ├── list
  ├── create
  └── search
batch/
  ├── posts/
  │   └── delete
  └── members/
      └── create
```
</step_1>

<step_2>
### Step 2: Extract Tool Definitions to JSON

Move all tool schemas from code to data:

**Before (in Python):**
```python
Tool(
    name="circle_create_post",
    description="Create a new post",
    inputSchema={
        "type": "object",
        "properties": {
            "space_id": {"type": "integer"},
            "name": {"type": "string"},
            "body": {"type": "string"}
        },
        "required": ["space_id", "name", "body"]
    }
)
```

**After (in operations.json):**
```json
{
  "operations": {
    "posts": {
      "create": {
        "name": "circle_create_post",
        "description": "Create a new post",
        "inputSchema": {
          "type": "object",
          "properties": {
            "space_id": {"type": "integer"},
            "name": {"type": "string"},
            "body": {"type": "string"}
          },
          "required": ["space_id", "name", "body"]
        }
      }
    }
  }
}
```
</step_2>

<step_3>
### Step 3: Implement Meta-Tools

Create the 4 core meta-tools (see [Meta-Tools Layer](#meta_tools_layer) above).
</step_3>

<step_4>
### Step 4: Build Operation Dispatcher

```python
def _get_tool_handlers(client):
    """Map operation names to actual implementations"""
    return {
        "your_operation_1": client.method_1,
        "your_operation_2": client.method_2,
        # ... all operations
    }

def _operation_to_tool_name(operation: str) -> str:
    """Convert 'category.action' to 'your_operation_name'"""
    # Your naming convention logic
    pass

@server.call_tool()
async def call_tool(name: str, arguments: Any):
    if name == "your_execute":
        operation = arguments["operation"]
        params = arguments["params"]

        tool_name = _operation_to_tool_name(operation)
        handlers = _get_tool_handlers(client)
        handler = handlers[tool_name]

        return await handler(**params)
```
</step_4>

<step_5>
### Step 5: Expose as MCP Resources

```python
@server.list_resources()
async def list_resources() -> list[Resource]:
    resources = []
    for category, actions in OPERATIONS.items():
        for action, schema in actions.items():
            resources.append(Resource(
                uri=f"yourapp://operations/{category}/{action}",
                name=schema["name"],
                description=schema["description"]
            ))
    return resources

@server.read_resource()
async def read_resource(uri: str) -> str:
    # Parse URI and return operation schema
    category, action = parse_uri(uri)
    schema = OPERATIONS[category][action]
    return json.dumps(schema, indent=2)
```
</step_5>

<step_6>
### Step 6: Add Pagination (Optional)

For large responses (>20k tokens), implement chunking:

```python
def chunk_by_tokens(data: dict, chunk_size: int = 15000) -> list[dict]:
    """Split large responses into chunks"""
    if 'data' not in data:
        return [data]

    items = data['data']
    chunks = []
    current_chunk = []
    current_tokens = 0

    for item in items:
        item_tokens = estimate_tokens(item)
        if current_tokens + item_tokens > chunk_size:
            chunks.append({'data': current_chunk})
            current_chunk = [item]
            current_tokens = item_tokens
        else:
            current_chunk.append(item)
            current_tokens += item_tokens

    if current_chunk:
        chunks.append({'data': current_chunk})

    return chunks
```
</step_6>

## Trade-offs

<advantages>
### Advantages

✅ **Massive context savings** (90-98% reduction)
✅ **Scales to any number of operations** (100, 200, 500+ operations)
✅ **Cleaner code** (schemas in data, not code)
✅ **Easy to maintain** (add operations by editing JSON)
✅ **Better for LLMs** (only loads relevant operations per conversation)
</advantages>

<disadvantages>
### Disadvantages

❌ **Extra discovery step** (Claude must call `discover` or `get_schema` first)
❌ **More complex implementation** (dispatch layer, resources API)
❌ **Slightly slower first call** (needs to fetch schema before executing)
❌ **Not ideal for < 20 operations** (overhead not worth it)
</disadvantages>

<performance_characteristics>
### Performance Characteristics

**First operation in conversation:**
1. Claude calls `discover` to browse operations (~300 tokens response)
2. Claude calls `get_schema` for specific operation (~200 tokens response)
3. Claude calls `execute` with parameters
4. Total: 3 tool calls vs 1 in traditional approach

**Subsequent operations:**
1. Claude already knows operations, just calls `execute`
2. Total: 1 tool call (same as traditional)

**Net result:** Small overhead on first operation, massive context savings overall.
</performance_characteristics>

## When to Use This Pattern

<use_when>
### ✅ Use resources-based architecture when:

- **You have 3+ operations** - Context is precious at every scale, not just large APIs
- **Operations are grouped logically** - Natural hierarchy exists (CRUD, categories)
- **Not all operations used per conversation** - Most conversations only use 2-5 operations
- **Context window is precious** - You need maximum space for actual conversation
- **Operations change frequently** - Easier to maintain in JSON than code

**Updated threshold: Use on-demand discovery for ANY MCP server with 3+ operations.**

Traditional wisdom says "only for 20+ operations," but context efficiency matters at every scale. Even 40% savings (200-500 tokens) compounds across conversations when:
- Conversations span many turns
- Multiple MCP servers are loaded
- Working with large codebases
- Every token counts toward the 200k context window
</use_when>

<dont_use_when>
### ❌ Stick with traditional tools when:

- **You have 1-2 operations only** - Overhead not worth the complexity
- **All operations used in most conversations** - No benefit to on-demand loading
- **Simplicity is priority** - Traditional approach is easier to understand
</dont_use_when>

## Context Savings by Operation Count

| Operations | Traditional | On-Demand | Savings | % Saved |
|------------|-------------|-----------|---------|---------|
| 1-2        | ~200        | ~300      | -100    | -50%    |
| 3          | ~300        | ~300      | 0       | 0%      |
| 5          | ~500        | ~300      | 200     | 40%     |
| 10         | ~1,000      | ~300      | 700     | 70%     |
| 15         | ~1,500      | ~300      | 1,200   | 80%     |
| 50         | ~5,000      | ~300      | 4,700   | 94%     |
| 100        | ~10,000     | ~300      | 9,700   | 97%     |

**Threshold: 3+ operations → use on-demand discovery pattern**

## Real-World Results

<circle_mcp_metrics>
### Circle MCP Server Metrics

**Before (tools-based v1):**
- 81 tool definitions loaded upfront
- ~15,000 tokens consumed
- Context available: 185,000 tokens
- Overhead: 7.5%

**After (resources-based v2):**
- 4 meta-tools loaded upfront
- ~300 tokens consumed
- Context available: 199,700 tokens
- Overhead: 0.15%
- **Savings: 98% context reduction**
</circle_mcp_metrics>

<typical_conversation>
### Typical Conversation Pattern

**Conversation using 3 operations:**

Traditional approach:
- Load 81 tools: 15,000 tokens
- Use 3 operations: 0 tokens (already loaded)
- **Total overhead: 15,000 tokens**

Resources-based approach:
- Load 4 meta-tools: 300 tokens
- Discover operations: 300 tokens (first time only)
- Get 3 schemas: 600 tokens (200 each, first time only)
- Execute 3 operations: 0 tokens (dispatch only)
- **Total overhead: 1,200 tokens**

**Savings: 92% even with discovery overhead**
</typical_conversation>

## Example: Building a GitHub MCP Server

<github_example>
Let's apply this pattern to a hypothetical GitHub API server with 50+ operations:

**1. Design Namespace**

```
repos/
  ├── list
  ├── create
  ├── get
  └── delete
issues/
  ├── list
  ├── create
  ├── update
  └── close
pulls/
  ├── list
  ├── create
  ├── merge
  └── review
actions/
  ├── list_workflows
  ├── trigger_workflow
  └── get_run
```

**2. Create operations.json**

```json
{
  "operations": {
    "repos": {
      "list": {
        "name": "github_list_repos",
        "description": "List repositories for authenticated user",
        "inputSchema": {
          "type": "object",
          "properties": {
            "type": {
              "type": "string",
              "enum": ["all", "owner", "member"]
            },
            "sort": {
              "type": "string",
              "enum": ["created", "updated", "pushed", "full_name"]
            }
          }
        }
      },
      "create": {
        "name": "github_create_repo",
        "description": "Create a new repository",
        "inputSchema": {
          "type": "object",
          "properties": {
            "name": {"type": "string"},
            "description": {"type": "string"},
            "private": {"type": "boolean"}
          },
          "required": ["name"]
        }
      }
    },
    "issues": { ... },
    "pulls": { ... }
  }
}
```

**3. Implement Meta-Tools**

```python
@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="github_discover",
            description="Browse all GitHub operations",
            inputSchema={"type": "object", "properties": {}}
        ),
        Tool(
            name="github_get_schema",
            description="Get schema for a GitHub operation",
            inputSchema={
                "type": "object",
                "properties": {
                    "operation": {
                        "type": "string",
                        "description": "e.g., 'repos.create', 'issues.list'"
                    }
                },
                "required": ["operation"]
            }
        ),
        Tool(
            name="github_execute",
            description="Execute a GitHub operation",
            inputSchema={
                "type": "object",
                "properties": {
                    "operation": {"type": "string"},
                    "params": {"type": "object"}
                },
                "required": ["operation", "params"]
            }
        )
    ]
```

**4. Build Dispatcher**

```python
def _operation_to_method(operation: str) -> str:
    """Convert 'repos.create' to 'github_create_repo'"""
    category, action = operation.split(".")
    return f"github_{action}_{category.rstrip('s')}"

def _get_handlers(client):
    return {
        "github_list_repos": client.list_repos,
        "github_create_repo": client.create_repo,
        "github_list_issues": client.list_issues,
        # ... all operations
    }

@server.call_tool()
async def call_tool(name: str, arguments: Any):
    if name == "github_execute":
        operation = arguments["operation"]
        params = arguments["params"]

        method = _operation_to_method(operation)
        handlers = _get_handlers(github_client)
        handler = handlers[method]

        result = await handler(**params)
        return [TextContent(type="text", text=json.dumps(result))]
```

**Results**

**50 operations:**
- Traditional: ~8,500 tokens overhead
- Resources-based: ~300 tokens overhead
- **Savings: 96.5%**
</github_example>

## Summary

<conclusion>
The resources-based MCP pattern achieves dramatic context reduction by:

1. **Lazy loading** - Only fetch operation schemas when needed
2. **Meta-tools** - Minimal upfront tool definitions for discovery/execution
3. **MCP resources** - Leverage MCP's resource API for on-demand schema retrieval
4. **Smart dispatch** - Route operation strings to implementations

**When you have 20+ operations, this pattern can save 90-98% of context overhead while maintaining full functionality.**

Use this pattern to build efficient, scalable MCP servers that preserve precious context window for actual conversation.
</conclusion>

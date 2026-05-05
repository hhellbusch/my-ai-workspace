# Response Optimization - Truncation & Pagination

<critical_pattern>
**Why this matters:** API responses exhaust Claude's context window after just 5-10 operations. Response optimization achieves 85% token reduction and enables 100+ operations per conversation.

**This pattern is MANDATORY for any MCP server returning lists, search results, or nested objects.**
</critical_pattern>

## The Problem

APIs return verbose responses with nested objects and metadata that Claude doesn't need.

**Example - typical API search response:**

```json
{
  "items": [
    {
      "id": "abc123",
      "name": "Item Name",
      "description": "...",
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z",
      "owner": {
        "id": "user123",
        "name": "John Doe",
        "email": "john@example.com",
        "avatar_url": "https://...",
        "profile_url": "https://...",
        "created_at": "2023-01-01T00:00:00Z",
        "followers_count": 1234,
        "following_count": 567
      },
      "metadata": {
        "view_count": 5432,
        "like_count": 123,
        "comment_count": 45
      },
      "urls": {
        "self": "https://api.example.com/items/abc123",
        "html": "https://example.com/items/abc123",
        "api": "https://api.example.com/v1/items/abc123"
      },
      "tags": ["tag1", "tag2", "tag3"],
      "is_public": true,
      "is_featured": false,
      "external_ids": {"platform1": "xyz", "platform2": "789"}
    }
    // ... 19 more items with FULL nested objects
  ],
  "pagination": {
    "total": 1247,
    "page": 1,
    "per_page": 20,
    "total_pages": 63
  },
  "links": {
    "next": "https://...",
    "prev": null,
    "first": "https://...",
    "last": "https://..."
  }
}
```

**Token cost:** ~10,000-15,000 tokens for one search

**After 5 searches:** Context exhausted

## The Solution: Two-Part Optimization

### Part 1: Field Truncation (85% token reduction)

**Define essential fields per resource type:**

```python
# What Claude ACTUALLY needs vs what API returns
FIELD_CONFIGS = {
    "items": ["id", "name", "uri", "owner.name", "created_at"],
    # NOT: description, metadata, urls, external_ids, timestamps, etc.

    "users": ["id", "name", "email"],
    # NOT: avatar_url, profile_url, followers_count, created_at, etc.

    "posts": ["id", "title", "author.name", "content_preview"],
    # NOT: full_content, metadata, view_counts, related_posts, etc.
}
```

**Key principle:** Include only what Claude needs to:
1. Uniquely identify the resource (id, uri)
2. Display to user (name, title)
3. Make decisions about next action (status, type, essential relationships)

**Exclude:**
- ✗ Full URLs (API endpoints, profile links)
- ✗ Counters/metrics (views, likes, followers)
- ✗ Timestamps (unless essential for filtering)
- ✗ External IDs and platform-specific metadata
- ✗ Nested objects beyond 1-2 essential fields

**Implementation:**

```python
def _extract_fields(obj: dict, fields: list[str]) -> dict:
    """Extract only specified fields, supporting dot notation for nested fields."""
    result = {}

    for field in fields:
        if "." in field:
            # Handle nested fields like "owner.name"
            parts = field.split(".")
            value = obj
            for part in parts:
                value = value.get(part) if isinstance(value, dict) else None
                if value is None:
                    break

            if value is not None:
                # Flatten nested field
                result[field.replace(".", "_")] = value
        else:
            # Direct field
            if field in obj:
                result[field] = obj[field]

    return result


def _truncate_response(result: dict, operation: str) -> dict:
    """Strip unnecessary fields from API responses."""

    # Handle list responses
    if "items" in result and isinstance(result["items"], list):
        result["items"] = [
            _extract_fields(item, FIELD_CONFIGS["items"])
            for item in result["items"]
        ]

    # Handle single object responses
    elif "data" in result and isinstance(result["data"], dict):
        result["data"] = _extract_fields(result["data"], FIELD_CONFIGS.get(operation, []))

    # Handle nested result types (like Spotify search with tracks/artists/albums)
    elif "tracks" in result and "items" in result["tracks"]:
        result["tracks"]["items"] = [
            _extract_fields(track, FIELD_CONFIGS["tracks"])
            for track in result["tracks"]["items"]
        ]

    return result
```

**Result - optimized response:**

```json
{
  "items": [
    {
      "id": "abc123",
      "name": "Item Name",
      "uri": "app:item:abc123",
      "owner_name": "John Doe",
      "created_at": "2024-01-15"
    }
    // ... 19 more items (minimal data)
  ],
  "total": 1247
}
```

**Token cost:** ~1,500-2,000 tokens (85% reduction)

### Part 2: Adaptive Pagination (20k token threshold)

**For responses that STILL exceed 15-20k tokens after truncation:**

```python
# Constants
CHUNK_SIZE_TOKENS = 15000        # Target chunk size
MAX_TOKENS_BEFORE_CHUNK = 20000  # Threshold to trigger chunking
RESULTS_CACHE = {}               # Session cache

def estimate_tokens(obj: Any) -> int:
    """Estimate token count for an object.

    Rough approximation: 1 token ≈ 4 characters
    """
    try:
        json_str = json.dumps(obj, ensure_ascii=False)
        return len(json_str) // 4
    except:
        return 0


def chunk_by_tokens(data: dict, chunk_size: int = CHUNK_SIZE_TOKENS) -> list[dict]:
    """Split a dict with 'items' or 'data' array into chunks by token count.

    Preserves metadata in first chunk only.
    """
    if not isinstance(data, dict):
        return [data]

    # Try 'items' or 'data' array
    items_key = "items" if "items" in data else "data" if "data" in data else None

    if not items_key or not isinstance(data[items_key], list):
        return [data]

    items = data[items_key]
    if not items:
        return [data]

    chunks = []
    current_chunk_items = []
    current_chunk_tokens = 0

    # Preserve metadata fields in first chunk
    metadata = {k: v for k, v in data.items() if k != items_key}
    metadata_tokens = estimate_tokens(metadata)

    for item in items:
        item_tokens = estimate_tokens(item)

        # Check if adding this item would exceed chunk size
        if current_chunk_items and (current_chunk_tokens + item_tokens > chunk_size):
            # Save current chunk
            chunk_data = {items_key: current_chunk_items}
            if not chunks:
                # Include metadata in first chunk only
                chunk_data.update(metadata)
            chunks.append(chunk_data)

            # Start new chunk
            current_chunk_items = [item]
            current_chunk_tokens = item_tokens
        else:
            current_chunk_items.append(item)
            current_chunk_tokens += item_tokens

    # Add final chunk
    if current_chunk_items:
        chunk_data = {items_key: current_chunk_items}
        if not chunks:
            chunk_data.update(metadata)
        chunks.append(chunk_data)

    return chunks


def format_chunked_response(chunk: dict, chunk_index: int, total_chunks: int, session_id: str = None) -> str:
    """Format a chunk with pagination footer."""
    chunk_json = json.dumps(chunk, indent=2, ensure_ascii=False)

    if total_chunks <= 1:
        return chunk_json

    footer = f"\n\n--- Page {chunk_index + 1}/{total_chunks} ---"
    if chunk_index < total_chunks - 1:
        footer += f"\nCall the 'continue' tool to see more results."
        if session_id:
            footer += f" (session: {session_id})"

    return chunk_json + footer
```

**Apply in execute handler:**

```python
@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "yourapp_execute":
        operation = arguments["operation"]
        params = arguments.get("params", {})

        # Execute operation
        result = _execute_operation(operation, params)

        # STEP 1: Apply field truncation (ALWAYS)
        result = _truncate_response(result, operation)

        # STEP 2: Check if pagination needed
        estimated_tokens = estimate_tokens(result)

        if estimated_tokens > MAX_TOKENS_BEFORE_CHUNK:
            # Split into chunks
            chunks = chunk_by_tokens(result, CHUNK_SIZE_TOKENS)

            if len(chunks) > 1:
                # Generate session ID
                import time
                session_id = f"sess_{int(time.time())}_{id(result) % 10000}"

                # Cache remaining chunks
                RESULTS_CACHE[session_id] = {
                    "chunks": chunks,
                    "current_index": 1,  # Next chunk to return
                    "timestamp": time.time()
                }

                # Return only first chunk
                response_text = format_chunked_response(
                    chunks[0],
                    0,
                    len(chunks),
                    session_id
                )
                return [TextContent(type="text", text=response_text)]

        # Normal response (fits in one chunk)
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
```

### Part 3: Continue Tool

**Add to meta-tools:**

```python
Tool(
    name="yourapp_continue",
    description="Continue retrieving paginated results from a previous operation. Use when a response shows 'Page X/Y' footer.",
    inputSchema={
        "type": "object",
        "properties": {
            "session_id": {
                "type": "string",
                "description": "Session ID from previous paginated response (optional if continuing last session)"
            }
        }
    }
)
```

**Implementation:**

```python
LAST_SESSION_ID = None  # Track most recent session

if name == "yourapp_continue":
    session_id = arguments.get("session_id", LAST_SESSION_ID)

    if not session_id or session_id not in RESULTS_CACHE:
        return [TextContent(
            type="text",
            text="No active pagination session found."
        )]

    # Get cached session
    session = RESULTS_CACHE[session_id]
    chunks = session["chunks"]
    current_index = session["current_index"]

    if current_index >= len(chunks):
        return [TextContent(
            type="text",
            text="No more results available."
        )]

    # Return next chunk
    chunk = chunks[current_index]
    session["current_index"] += 1

    response_text = format_chunked_response(
        chunk,
        current_index,
        len(chunks),
        session_id
    )

    return [TextContent(type="text", text=response_text)]
```

### Part 4: On-Demand Fields (Optional Parameter)

**Pattern:** Allow caller to specify which fields to fetch in GET operations.

**When to use:**
- GET operations where different use cases need different field subsets
- Resources with 10+ available fields but most calls only need 3-4
- Copying/cloning workflows that need configuration fields
- Complementary to field truncation for lists

**Implementation:**

```python
def execute_campaigns_get(
    campaign_id: str,
    fields: list = None,  # Optional field selection
    profile: str = None
) -> dict:
    """Get campaign details with optional field selection."""

    if fields is None:
        # Minimal default for common case
        fields = ["id", "name", "status"]

    # Fetch requested fields from API
    campaign = Campaign(campaign_id)
    result = campaign.api_get(fields=fields)

    return {"data": result.export_all_data()}
```

**Schema definition:**

```json
{
  "name": "yourapp_get_campaign",
  "inputSchema": {
    "type": "object",
    "properties": {
      "campaign_id": {"type": "string"},
      "fields": {
        "type": "array",
        "items": {"type": "string"},
        "description": "Optional fields to fetch. Defaults to [id, name, status]. Available: id, name, status, objective, daily_budget, bid_strategy, created_time, etc."
      }
    },
    "required": ["campaign_id"]
  }
}
```

**Usage examples:**

```
# Minimal fetch (default)
campaigns.get(id="123")
→ {"id": "123", "name": "Test", "status": "ACTIVE"}

# Fetch specific fields for cloning
campaigns.get(id="123", fields=["objective", "daily_budget", "bid_strategy"])
→ {"objective": "SALES", "daily_budget": 5000, "bid_strategy": "LOWEST_COST"}

# Fetch all fields when needed
campaigns.get(id="123", fields=["*"])  # or comprehensive list
```

**Design principle:**

This mirrors the on-demand operations pattern at the response data level:
- On-demand operations: Don't load tool schemas until needed (98% context reduction)
- On-demand fields: Don't load field data until needed (variable context savings)

Both implement: "Pay only for what you use"

**Field discovery:**

Document available fields in operation schema description or point to API docs. Claude can learn which fields exist through:
1. Schema descriptions listing common fields
2. API documentation references
3. Error messages when requesting invalid fields

## When to Apply

<decision_tree>
**ALWAYS apply field truncation if:**
- ✓ Returns lists of items (search, list, browse, query)
- ✓ Returns nested objects (items with embedded related data)
- ✓ API responses regularly > 1,000 tokens
- ✓ Designed for multiple operations per conversation

**ALWAYS apply pagination if:**
- ✓ API can return 100+ items
- ✓ Single responses can exceed 20,000 tokens
- ✓ List operations are common use case

**MAYBE skip if:**
- Single-object CRUD only (get one user, update one record)
- API already returns minimal responses
- Server designed for one-shot operations only
- Responses consistently < 500 tokens
</decision_tree>

## Implementation Checklist

Before declaring optimization complete:

- [ ] **Field configs** defined for each resource type
- [ ] **Token estimation** function implemented
- [ ] **Response truncation** applied in execute handler (BEFORE pagination)
- [ ] **Chunking logic** for responses > 20k tokens
- [ ] **Continue tool** implemented for pagination
- [ ] **Session cache** with cleanup (TTL)
- [ ] **Metadata preservation** in first chunk only
- [ ] **Tested** with large result sets (100+ items)

## Cache Cleanup

**Add TTL to prevent memory leaks:**

```python
import time

def clean_expired_sessions():
    """Remove sessions older than 5 minutes."""
    cutoff = time.time() - 300  # 5 minutes
    expired = [
        sid for sid, session in RESULTS_CACHE.items()
        if session.get("timestamp", 0) < cutoff
    ]
    for sid in expired:
        del RESULTS_CACHE[sid]

# Call before adding new session
clean_expired_sessions()
```

## Real-World Impact

**Without optimization:**
```
Search operation: 10,000 tokens
× 5 searches = 50,000 tokens
Context remaining: 150,000 / 200,000 (25% exhausted)
```

**With optimization:**
```
Search operation: 1,500 tokens (truncated)
× 5 searches = 7,500 tokens
Context remaining: 192,500 / 200,000 (3.75% used)
```

**Result:** 42,500 tokens saved = 28+ more operations possible

## User Experience

**Traditional (unoptimized):**
```
User: "Search for Queen"
Claude: [receives 10,000 token response]
User: "Search for Beatles"
Claude: [receives 10,000 tokens]
... after 5-10 searches, context exhausted
Claude: "I've run out of context"
```

**Optimized:**
```
User: "Search for Queen"
Claude: [receives 1,500 token response]
User: "Search for Beatles"
Claude: [receives 1,500 tokens]
User: "List all my playlists"
Claude: [receives first 15k token chunk]
Claude: "Page 1/3 - call continue for more"
User: "continue"
Claude: [receives second chunk from cache]
... can perform 50+ operations before context issues
```

## Key Takeaways

1. **API responses are designed for breadth, not efficiency**
2. **Field truncation is MANDATORY for production MCP servers**
3. **Pagination is REQUIRED for list operations**
4. **85% token reduction is achievable with minimal code**
5. **Context efficiency enables longer, more productive conversations**
6. **Apply optimization BEFORE declaring server "complete"**

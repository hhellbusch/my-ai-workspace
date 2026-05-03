# OAuth Implementation for MCP Servers

<critical_pattern>
**Why this matters:** OAuth libraries write to stdout/stderr, which corrupts MCP's JSON-RPC protocol. MCP servers also run headless (no terminal/browser access) making standard OAuth flows impossible.

**Both patterns below are MANDATORY for any MCP server using OAuth.**
</critical_pattern>

## Pattern 1: stdout/stderr Isolation

<the_problem>
MCP uses JSON-RPC over stdio. OAuth libraries print authorization prompts to stdout/stderr:

```
User authentication requires interaction with your web browser...
Go to the following URL: https://accounts.spotify.com/authorize?...
```

This text corrupts the JSON-RPC protocol, causing errors like:
```
Unexpected token 'G', "Go to the "... is not valid JSON
```
</the_problem>

<the_solution>
Wrap ALL OAuth operations with stdout/stderr redirection:

```python
import sys
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO

def get_api_client():
    """Initialize OAuth client with stdio isolation."""
    stderr_capture = StringIO()
    stdout_capture = StringIO()

    with redirect_stderr(stderr_capture), redirect_stdout(stdout_capture):
        # OAuth initialization happens in isolation
        auth_manager = OAuthProvider(
            client_id=os.environ.get("CLIENT_ID"),
            client_secret=os.environ.get("CLIENT_SECRET"),
            redirect_uri=os.environ.get("REDIRECT_URI"),
            scope=SCOPE,
            open_browser=False  # Never open browser in MCP server
        )
        client = APIClient(auth_manager=auth_manager)

    # Log captured output to logger (not stdout)
    if stderr_capture.getvalue():
        logger.info(f"OAuth stderr: {stderr_capture.getvalue()}")
    if stdout_capture.getvalue():
        logger.info(f"OAuth stdout: {stdout_capture.getvalue()}")

    return client
```

**Apply to EVERY operation that might trigger token refresh:**

```python
def _execute_operation(operation: str, params: dict) -> Any:
    """Execute API operation with stdio isolation."""
    global client

    stderr_capture = StringIO()
    stdout_capture = StringIO()

    with redirect_stderr(stderr_capture), redirect_stdout(stdout_capture):
        if client is None:
            client = get_api_client()

        # API call may trigger token refresh (which writes to stderr)
        result = client.execute(operation, **params)

    # Log any captured output
    if stderr_capture.getvalue():
        logger.info(f"Execution stderr: {stderr_capture.getvalue()}")

    return result
```
</the_solution>

## Pattern 2: Pre-Authorization Script

<the_problem>
MCP servers run as background processes with NO terminal or browser access:

1. User opens Claude Desktop
2. MCP server starts in background
3. OAuth library needs user to authorize in browser
4. **No way to show URL or open browser**
5. Server hangs waiting for authorization that never comes
</the_problem>

<the_solution>
Create a standalone script users run ONCE to authorize and cache the token:

**`authorize.py` (in server root directory):**

```python
#!/usr/bin/env python3
"""
OAuth authorization helper.
Run this once to authorize the app and cache your token.
"""

import os
from your_oauth_library import OAuthProvider

SCOPE = " ".join([
    "scope1",
    "scope2",
    "scope3"
])

def authorize():
    """Perform OAuth authorization and cache token."""
    print("MCP Server - OAuth Authorization")
    print("=" * 50)

    auth_manager = OAuthProvider(
        client_id=os.environ.get("CLIENT_ID"),
        client_secret=os.environ.get("CLIENT_SECRET"),
        redirect_uri=os.environ.get("REDIRECT_URI"),
        scope=SCOPE,
        open_browser=True  # ✓ Opens browser ONLY during manual setup
    )

    # Trigger authorization flow
    token_info = auth_manager.get_access_token()

    if token_info:
        print("✓ Authorization successful!")
        print("✓ Token cached for future use")
        print()
        print("You can now use the MCP server.")
    else:
        print("✗ Authorization failed.")

if __name__ == "__main__":
    authorize()
```

**User setup flow (document in README):**

```markdown
## Setup

1. Install dependencies: `uv sync`
2. Set environment variables in ~/.zshrc
3. **Authorize the app (one-time):**
   ```bash
   cd ~/Developer/mcp/{server-name}
   uv run python authorize.py
   ```
4. Restart Claude Desktop
```

**Server uses cached token:**

```python
def get_api_client():
    """Initialize client using CACHED token."""
    stderr_capture = StringIO()
    stdout_capture = StringIO()

    with redirect_stderr(stderr_capture), redirect_stdout(stdout_capture):
        auth_manager = OAuthProvider(
            client_id=os.environ.get("CLIENT_ID"),
            client_secret=os.environ.get("CLIENT_SECRET"),
            redirect_uri=os.environ.get("REDIRECT_URI"),
            scope=SCOPE,
            open_browser=False  # ✓ Never open browser in server
        )
        # If .cache file exists, uses cached token
        # If token expired, auto-refreshes silently
        client = APIClient(auth_manager=auth_manager)

    return client
```

**Token storage:**

Most OAuth libraries cache tokens in files like `.cache-{username}`.

**Add to `.gitignore`:**
```gitignore
.cache-*
*.token
.credentials
```
</the_solution>

## When to Apply

<apply_when>
**Use both patterns for:**
- ✓ Any OAuth flow (Spotify, Google, GitHub, Facebook, etc.)
- ✓ Any library that writes to stdout/stderr
- ✓ Background services requiring user authorization
- ✓ Any headless environment with OAuth

**Pattern 1 (stdio isolation) is CRITICAL:**
- Skip it → JSON-RPC protocol breaks → server fails

**Pattern 2 (pre-authorization) is REQUIRED:**
- Skip it → Users can't authorize → server unusable
</apply_when>

<dont_apply_when>
**Don't use for:**
- ✗ API key authentication (no authorization flow needed)
- ✗ Client Credentials OAuth (server-to-server, no user interaction)
- ✗ JWT/Bearer tokens (no interactive flow)
- ✗ Web apps with interactive UI
</dont_apply_when>

## Implementation Checklist

Before declaring OAuth integration complete:

- [ ] **stdio isolation** wraps OAuth client initialization
- [ ] **stdio isolation** wraps every API call (token refresh can write to stderr)
- [ ] **`authorize.py`** script created for one-time setup
- [ ] **README** documents authorization step clearly
- [ ] **`.gitignore`** excludes token cache files
- [ ] **Environment variables** documented (CLIENT_ID, CLIENT_SECRET, REDIRECT_URI)
- [ ] **Tested** authorization flow manually before MCP installation
- [ ] **Verified** server works with cached token (no browser prompts)

## Code Template

**Minimal OAuth MCP server implementation:**

```python
import os
import logging
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from mcp.server import Server
from your_oauth_library import OAuthProvider, APIClient

logger = logging.getLogger(__name__)

SCOPE = "scope1 scope2 scope3"
client = None

def get_api_client():
    """Initialize OAuth client with stdio isolation."""
    stderr_capture = StringIO()
    stdout_capture = StringIO()

    with redirect_stderr(stderr_capture), redirect_stdout(stdout_capture):
        auth_manager = OAuthProvider(
            client_id=os.environ.get("CLIENT_ID"),
            client_secret=os.environ.get("CLIENT_SECRET"),
            redirect_uri=os.environ.get("REDIRECT_URI"),
            scope=SCOPE,
            open_browser=False
        )
        client = APIClient(auth_manager=auth_manager)

    if stderr_capture.getvalue():
        logger.info(f"OAuth stderr: {stderr_capture.getvalue()}")

    return client

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    global client

    # Isolate ALL API calls
    stderr_capture = StringIO()
    stdout_capture = StringIO()

    with redirect_stderr(stderr_capture), redirect_stdout(stdout_capture):
        if client is None:
            client = get_api_client()

        result = client.execute(name, **arguments)

    return [TextContent(type="text", text=json.dumps(result))]
```

## Common OAuth Libraries

**Python:**
- `spotipy` (Spotify) - writes to stderr, needs both patterns
- `google-auth-oauthlib` (Google) - writes to stdout, needs both patterns
- `requests-oauthlib` (generic) - usually silent, still wrap for safety
- `PyGithub` with OAuth - needs both patterns

**TypeScript/Node:**
- Most Node OAuth libraries write to console.log
- Use similar pattern: capture console output during auth

## Key Takeaways

1. **Any library that writes to stdout/stderr will break MCP's JSON-RPC protocol**
2. **MCP servers run headless - separate authorization from runtime**
3. **Token refresh can write to stderr even if initialization doesn't**
4. **Always isolate, always pre-authorize, always test manually first**

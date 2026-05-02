# TypeScript MCP Server Implementation

<overview>
TypeScript implementation using @modelcontextprotocol/sdk provides full type safety, excellent IDE support, and robust async patterns. This guide covers TypeScript-specific features and best practices.
</overview>

## Project Setup

<package_json>
```json
{
  "name": "my-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.22.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.3.0"
  }
}
```
</package_json>

<tsconfig>
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```
</tsconfig>

## Server Structure

<full_example>
```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
  TextContent,
  ImageContent,
  EmbeddedResource,
} from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";

// Define server metadata
const SERVER_NAME = "my-mcp-server";
const SERVER_VERSION = "1.0.0";

// Type-safe tool definitions
interface ToolHandler {
  name: string;
  description: string;
  schema: z.ZodSchema;
  handler: (args: any) => Promise<TextContent | ImageContent | EmbeddedResource>;
}

// Create server instance
const server = new Server(
  {
    name: SERVER_NAME,
    version: SERVER_VERSION,
  },
  {
    capabilities: {
      tools: {},
      resources: {},
      prompts: {},
    },
  }
);

// Tool registry
const tools: Map<string, ToolHandler> = new Map();

// Register a tool
function registerTool(tool: ToolHandler) {
  tools.set(tool.name, tool);
}

// Example: Register a calculation tool
registerTool({
  name: "add_numbers",
  description: "Add two numbers together",
  schema: z.object({
    a: z.number().describe("First number"),
    b: z.number().describe("Second number"),
  }),
  handler: async (args) => {
    const { a, b } = args;
    return {
      type: "text",
      text: `${a} + ${b} = ${a + b}`,
    };
  },
});

// List tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  const toolsList: Tool[] = Array.from(tools.values()).map((tool) => ({
    name: tool.name,
    description: tool.description,
    inputSchema: zodToJsonSchema(tool.schema),
  }));

  return { tools: toolsList };
});

// Call tool handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const toolName = request.params.name;
  const tool = tools.get(toolName);

  if (!tool) {
    throw new Error(`Unknown tool: ${toolName}`);
  }

  // Validate input with Zod
  const validatedArgs = tool.schema.parse(request.params.arguments);

  // Execute tool handler
  const result = await tool.handler(validatedArgs);

  return {
    content: [result],
  };
});

// Helper: Convert Zod schema to JSON Schema
function zodToJsonSchema(schema: z.ZodSchema): any {
  // Simplified conversion - use zod-to-json-schema package for production
  if (schema instanceof z.ZodObject) {
    const shape = schema.shape;
    const properties: any = {};
    const required: string[] = [];

    for (const [key, value] of Object.entries(shape)) {
      properties[key] = { type: getZodType(value as z.ZodTypeAny) };

      // Add description if available
      const description = (value as any)._def?.description;
      if (description) {
        properties[key].description = description;
      }

      // Track required fields
      if (!(value as z.ZodTypeAny).isOptional()) {
        required.push(key);
      }
    }

    return {
      type: "object",
      properties,
      required,
    };
  }

  return { type: "object" };
}

function getZodType(schema: z.ZodTypeAny): string {
  if (schema instanceof z.ZodString) return "string";
  if (schema instanceof z.ZodNumber) return "number";
  if (schema instanceof z.ZodBoolean) return "boolean";
  if (schema instanceof z.ZodArray) return "array";
  if (schema instanceof z.ZodObject) return "object";
  return "string";
}

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);

  // Log to stderr (stdout is reserved for MCP protocol)
  console.error(`${SERVER_NAME} v${SERVER_VERSION} running on stdio`);
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
```
</full_example>

## Type-Safe Patterns

<zod_validation>
**Input Validation with Zod**:

```typescript
import { z } from "zod";

// Define schema with validation rules
const SearchSchema = z.object({
  query: z.string().min(1).max(500),
  limit: z.number().int().min(1).max(100).optional().default(10),
  filters: z.array(z.string()).optional(),
});

type SearchArgs = z.infer<typeof SearchSchema>;

// Use in handler
registerTool({
  name: "search",
  description: "Search for items",
  schema: SearchSchema,
  handler: async (args: SearchArgs) => {
    // args is fully typed: { query: string, limit: number, filters?: string[] }
    const results = await performSearch(args.query, args.limit);
    return {
      type: "text",
      text: JSON.stringify(results, null, 2),
    };
  },
});
```
</zod_validation>

<resource_handlers>
**Resource Handlers**:

```typescript
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  Resource,
} from "@modelcontextprotocol/sdk/types.js";

// List resources
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  const resources: Resource[] = [
    {
      uri: "file:///config.json",
      name: "Configuration",
      description: "Server configuration file",
      mimeType: "application/json",
    },
    {
      uri: "file:///{path}",
      name: "File system",
      description: "Read files from the filesystem",
      mimeType: "text/plain",
    },
  ];

  return { resources };
});

// Read resource
server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const uri = request.params.uri;

  if (uri === "file:///config.json") {
    const config = await readConfig();
    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify(config, null, 2),
        },
      ],
    };
  }

  if (uri.startsWith("file:///")) {
    const path = uri.slice(8); // Remove "file:///"
    const content = await fs.readFile(path, "utf-8");
    return {
      contents: [
        {
          uri,
          mimeType: "text/plain",
          text: content,
        },
      ],
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});
```
</resource_handlers>

<prompt_handlers>
**Prompt Templates**:

```typescript
import {
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
  Prompt,
  PromptMessage,
} from "@modelcontextprotocol/sdk/types.js";

// List prompts
server.setRequestHandler(ListPromptsRequestSchema, async () => {
  const prompts: Prompt[] = [
    {
      name: "code_review",
      description: "Review code for best practices",
      arguments: [
        {
          name: "language",
          description: "Programming language",
          required: true,
        },
        {
          name: "code",
          description: "Code to review",
          required: true,
        },
      ],
    },
  ];

  return { prompts };
});

// Get prompt
server.setRequestHandler(GetPromptRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "code_review") {
    const language = args?.language;
    const code = args?.code;

    const messages: PromptMessage[] = [
      {
        role: "user",
        content: {
          type: "text",
          text: `Review this ${language} code for best practices:\n\n${code}`,
        },
      },
    ];

    return {
      description: `Code review for ${language}`,
      messages,
    };
  }

  throw new Error(`Unknown prompt: ${name}`);
});
```
</prompt_handlers>

## Error Handling

<error_patterns>
```typescript
import { McpError, ErrorCode } from "@modelcontextprotocol/sdk/types.js";

// Custom error handling
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  try {
    const tool = tools.get(request.params.name);

    if (!tool) {
      throw new McpError(
        ErrorCode.MethodNotFound,
        `Tool not found: ${request.params.name}`
      );
    }

    // Validate arguments
    let validatedArgs;
    try {
      validatedArgs = tool.schema.parse(request.params.arguments);
    } catch (error) {
      if (error instanceof z.ZodError) {
        throw new McpError(
          ErrorCode.InvalidParams,
          `Invalid arguments: ${error.message}`
        );
      }
      throw error;
    }

    // Execute handler with timeout
    const result = await Promise.race([
      tool.handler(validatedArgs),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Tool execution timeout")), 30000)
      ),
    ]);

    return { content: [result] };
  } catch (error) {
    // Log to stderr
    console.error(`Tool execution error:`, error);

    // Re-throw MCP errors
    if (error instanceof McpError) {
      throw error;
    }

    // Wrap other errors
    throw new McpError(
      ErrorCode.InternalError,
      error instanceof Error ? error.message : "Unknown error"
    );
  }
});
```
</error_patterns>

## Advanced Features

<streaming>
**Streaming Responses** (for long-running operations):

```typescript
// Note: Basic MCP doesn't support streaming yet, but you can chunk responses
async function handleLargeDataTool(args: any): Promise<TextContent> {
  const data = await fetchLargeDataset(args.query);

  // Split into manageable chunks
  const chunks = chunkData(data, 1000);

  return {
    type: "text",
    text: chunks.map((chunk, i) =>
      `Chunk ${i + 1}/${chunks.length}:\n${chunk}`
    ).join("\n\n"),
  };
}
```
</streaming>

<state_management>
**State Management**:

```typescript
// Maintain server state
class ServerState {
  private cache: Map<string, any> = new Map();
  private connections: Set<string> = new Set();

  setCache(key: string, value: any, ttl: number = 60000) {
    this.cache.set(key, value);
    setTimeout(() => this.cache.delete(key), ttl);
  }

  getCache(key: string): any | undefined {
    return this.cache.get(key);
  }

  addConnection(id: string) {
    this.connections.add(id);
    console.error(`Connection added: ${id} (total: ${this.connections.size})`);
  }

  removeConnection(id: string) {
    this.connections.delete(id);
    console.error(`Connection removed: ${id} (total: ${this.connections.size})`);
  }
}

const state = new ServerState();

// Use state in tools
registerTool({
  name: "cached_fetch",
  description: "Fetch with caching",
  schema: z.object({ url: z.string().url() }),
  handler: async (args) => {
    const cached = state.getCache(args.url);
    if (cached) {
      return { type: "text", text: cached };
    }

    const response = await fetch(args.url);
    const data = await response.text();
    state.setCache(args.url, data);

    return { type: "text", text: data };
  },
});
```
</state_management>

## Environment Configuration

<env_config>
```typescript
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

interface Config {
  apiKey: string;
  apiEndpoint: string;
  maxRetries: number;
  debug: boolean;
}

function loadConfig(): Config {
  const apiKey = process.env.API_KEY;
  if (!apiKey) {
    throw new Error("API_KEY environment variable is required");
  }

  return {
    apiKey,
    apiEndpoint: process.env.API_ENDPOINT || "https://api.example.com",
    maxRetries: parseInt(process.env.MAX_RETRIES || "3"),
    debug: process.env.DEBUG === "true",
  };
}

const config = loadConfig();

// Use in tools
registerTool({
  name: "api_call",
  description: "Call external API",
  schema: z.object({ endpoint: z.string() }),
  handler: async (args) => {
    const response = await fetch(`${config.apiEndpoint}${args.endpoint}`, {
      headers: {
        Authorization: `Bearer ${config.apiKey}`,
      },
    });

    const data = await response.json();
    return { type: "text", text: JSON.stringify(data, null, 2) };
  },
});
```

**.env file**:
```
API_KEY=your_api_key_here
API_ENDPOINT=https://api.example.com
MAX_RETRIES=3
DEBUG=false
```
</env_config>

## Build and Distribution

<build_script>
```json
{
  "scripts": {
    "build": "tsc && chmod +x dist/index.js",
    "prepublishOnly": "npm run build",
    "start": "node dist/index.js"
  },
  "bin": {
    "my-mcp-server": "./dist/index.js"
  }
}
```

Add shebang to src/index.ts:
```typescript
#!/usr/bin/env node

// ... rest of server code
```
</build_script>

<publishing>
**Publish to npm**:

```bash
npm login
npm publish
```

Users install with:
```bash
npm install -g my-mcp-server
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
</publishing>

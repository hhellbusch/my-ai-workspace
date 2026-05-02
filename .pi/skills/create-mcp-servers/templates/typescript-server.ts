/**
 * MCP Server Template - TypeScript (Traditional Pattern)
 *
 * Use this template for servers with 1-2 operations.
 * For 3+ operations, use the on-demand discovery pattern instead.
 *
 * Replace:
 * - {SERVER_NAME}: Your server name (e.g., "my-api")
 * - {TOOL_NAME}: Tool name (e.g., "search_items")
 * - {TOOL_DESCRIPTION}: What the tool does
 * - {API_KEY_VAR}: Environment variable name for API key
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import * as fs from "fs";
import * as path from "path";

// =============================================================================
// Logging Setup (never use console.log/error for MCP)
// =============================================================================

const logFile = path.join(
  process.env.HOME || "",
  "Library/Logs/Claude/mcp-server-{SERVER_NAME}.log"
);

function log(level: string, message: string): void {
  const timestamp = new Date().toISOString();
  const logMessage = `${timestamp} - {SERVER_NAME} - ${level} - ${message}\n`;
  fs.appendFileSync(logFile, logMessage);
}

const logger = {
  info: (msg: string) => log("INFO", msg),
  error: (msg: string) => log("ERROR", msg),
  debug: (msg: string) => log("DEBUG", msg),
};

// =============================================================================
// API Client Setup
// =============================================================================

function getClient(): any {
  const apiKey = process.env.{API_KEY_VAR};
  if (!apiKey) {
    throw new Error("{API_KEY_VAR} environment variable not set");
  }

  // Initialize your client here
  // return new YourAPIClient(apiKey);
  return null;
}

// =============================================================================
// Tool Definitions
// =============================================================================

const TOOLS: Tool[] = [
  {
    name: "{tool_name}",
    description: "{TOOL_DESCRIPTION}",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query",
        },
      },
      required: ["query"],
    },
  },
  // Add more tools here for 1-2 operation servers
];

// =============================================================================
// Tool Handlers
// =============================================================================

async function handle{ToolName}(args: Record<string, any>): Promise<any> {
  const query = args.query as string;

  // Implement your logic here
  // const client = getClient();
  // const result = await client.search(query);

  return { status: "success", query };
}

// =============================================================================
// Server Setup
// =============================================================================

const server = new Server(
  {
    name: "{SERVER_NAME}",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List tools handler
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

// Call tool handler
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  logger.info(`Tool called: ${name} with args: ${JSON.stringify(args)}`);

  try {
    let result: any;

    switch (name) {
      case "{tool_name}":
        result = await handle{ToolName}(args || {});
        break;
      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    logger.error(`Error in ${name}: ${errorMessage}`);
    return {
      content: [
        {
          type: "text",
          text: `Error: ${errorMessage}`,
        },
      ],
      isError: true,
    };
  }
});

// =============================================================================
// Main Entry Point
// =============================================================================

async function main(): Promise<void> {
  logger.info("Starting {SERVER_NAME} MCP server");
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  logger.error(`Fatal error: ${error}`);
  process.exit(1);
});

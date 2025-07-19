import { McpServer, ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// Create an MCP server
const server = new McpServer({
  name: "mcp-demo",
  version: "1.0.0"
});

// Add an addition tool
server.registerTool("calculate_sum",
  {
    title: "Addition Tool",
    description: "Calculate the sum of two numbers",
    inputSchema: { a: z.number(), b: z.number() }
  },
  async ({ a, b }) => ({
    content: [{ type: "text", text: `The Sum of ${a} + ${b} is ${String(a + b)}` }]
  })
);

// Add a say_hello tool
server.registerTool("say_hello",
  {
    title: "Say Hello Tool",
    description: "Say hello to a person",
    inputSchema: { name: z.string() }
  },
  async ({ name }) => ({
    content: [{ type: "text", text: `👋 Hello, ${name}! 🙂` }]
  })
);


// Start receiving messages on stdin and sending messages on stdout
const transport = new StdioServerTransport();
await server.connect(transport);
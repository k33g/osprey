# Function Calling With MCP STDIO server

This example demonstrates how to use the Osprey library with a custom MCP server that communicates via standard input/output. It showcases how to define tools, call them, and handle responses in a structured way.

## First, build the MCP server Docker image
```bash
cd mcp-server
docker build -t osprey-mcp-server:demo .
```

## Then, run the example    
```bash
./main.sh
```


# Function Calling With MCP Streamable HTTP server

This example demonstrates how to use the Osprey library with a custom MCP server with Streamable HTTP transport. It showcases how to define tools, call them, and handle responses in a structured way.

## First, build the MCP server Docker image
```bash
cd mcp-server
docker build --platform linux/arm64 -t osprey-mcp-http-server:demo .
```

## Run the MCP Server
```bash
docker run --rm -p 9090:9090 osprey-mcp-http-server:demo
```

## Then, run the example    
```bash
./main.sh
```


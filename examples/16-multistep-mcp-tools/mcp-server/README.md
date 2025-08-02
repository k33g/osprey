# Osprey MCP Multistep Streamable HTTP Server Example

## Build the MCP Server Docker Image
```bash
docker build --platform linux/arm64 -t osprey-mcp-http-server:demo .
```

## Run the MCP Server
```bash
docker run --rm -p 9090:9090 osprey-mcp-http-server:demo
```

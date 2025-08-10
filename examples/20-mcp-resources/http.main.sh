#!/bin/bash

# Load the osprey library
. "../../lib/osprey.sh"

# HTTP MCP server URL
MCP_SERVER_URL="http://localhost:9090"

echo "=== MCP HTTP Resources Example ==="
echo "Server URL: $MCP_SERVER_URL"
echo

# Example 1: List all available resources
echo "1. Listing all available resources:"
echo "   Command: get_mcp_http_resources \"$MCP_SERVER_URL\""
echo "   ---"

resources=$(get_mcp_http_resources "$MCP_SERVER_URL")
echo "$resources" | jq '.'
echo

# Example 2: Read a specific resource
echo "2. Reading a specific resource (snippets://golang):"
echo "   Command: read_mcp_http_resource \"$MCP_SERVER_URL\" \"snippets://golang\""
echo "   ---"

resource_content=$(read_mcp_http_resource "$MCP_SERVER_URL" "snippets://golang")
echo "$resource_content" | jq '.'
echo

# Example 3: Extract the content from the resource response
echo "3. Extracting just the resource content:"
echo "   Command: read_mcp_http_resource \"$MCP_SERVER_URL\" \"snippets://golang\" | jq -r '.result.contents[0].text'"
echo "   ---"

content_text=$(echo "$resource_content" | jq -r '.result.contents[0].text')
echo "$content_text"
echo

# Example 4: List resource URIs only
echo "4. Listing just the resource URIs:"
echo "   Command: get_mcp_http_resources \"$MCP_SERVER_URL\" | jq -r '.[].uri'"
echo "   ---"

echo "$resources" | jq -r '.[].uri'
echo

# Example 5: Read another resource (rust snippets)
echo "5. Reading rust snippets resource:"
echo "   Command: read_mcp_http_resource \"$MCP_SERVER_URL\" \"snippets://rust\""
echo "   ---"

rust_content=$(read_mcp_http_resource "$MCP_SERVER_URL" "snippets://rust")
echo "$rust_content" | jq -r '.result.contents[0].text' | head -20
echo "   ... (showing first 20 lines)"
echo

# Example 6: Show resource metadata
echo "6. Showing resource metadata:"
echo "   Command: get_mcp_http_resources \"$MCP_SERVER_URL\" | jq '.[] | {uri, name, description, mimeType}'"
echo "   ---"

echo "$resources" | jq '.[] | {uri, name, description, mimeType}'
echo

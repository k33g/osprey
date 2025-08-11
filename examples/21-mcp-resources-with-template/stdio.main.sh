#!/bin/bash

# Load the osprey library
. "../../lib/osprey.sh"

# Server command to run the MCP server (we need to be in the correct directory)
SERVER_COMMAND="cd mcp-stdio-server && go run main.go"

echo "=== MCP Resources Example ==="
echo

# Example 1: List all available resources
echo "1. Listing all available resources:"
echo "   Command: get_mcp_resources_templates \"$SERVER_COMMAND\""
echo "   ---"

resources=$(get_mcp_resources_templates "$SERVER_COMMAND")
echo "$resources" | jq '.'
echo

# Example 2: Read a specific resource
echo "2. Reading a specific resource (users://121268/profile):"
echo "   Command: read_mcp_resource \"$SERVER_COMMAND\" \"users://121268/profile\""
echo "   ---"

resource_content=$(read_mcp_resource "$SERVER_COMMAND" "users://121268/profile")
echo "$resource_content" | jq '.'
echo

# Example 3: Extract the content from the resource response
echo "3. Extracting just the resource content:"
echo "   Command: read_mcp_resource \"$SERVER_COMMAND\" \"users://121268/profile\" | jq -r '.[1].result.contents[0].text'"
echo "   ---"

content_text=$(echo "$resource_content" | jq -r '.[1].result.contents[0].text')
echo "$content_text"
echo


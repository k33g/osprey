#!/bin/bash
. "../../lib/osprey.sh"


SERVER_CMD="docker mcp gateway run"
# SERVER_CMD="node ./mcp-server/index.js"

MCP_TOOLS=$(get_mcp_tools "$SERVER_CMD")
TOOLS=$(transform_to_openai_format "$MCP_TOOLS")

echo "---------------------------------------------------------"
echo "Available tools:"
echo "${TOOLS}" 
echo "---------------------------------------------------------"

FILTERED_TOOLS=$(transform_to_openai_format_with_filter "${MCP_TOOLS}" "search" "fetch")

echo "========================================================="
echo "Filtered tools:"
echo "${FILTERED_TOOLS}" 
echo "========================================================="

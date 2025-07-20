#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.

✋✋✋ To run this example running on linux, you need to install the mcp-gateway plugin.
👀 https://github.com/docker/mcp-gateway?tab=readme-ov-file#install-as-docker-cli-plugin
COMMENT

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

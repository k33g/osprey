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

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
#MODEL=${MODEL_RUNNER_TOOL_MODEL:-"hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s"}
MODEL=${MODEL_RUNNER_TOOL_MODEL:-"hf.co/salesforce/llama-xlam-2-8b-fc-r-gguf:q4_k_m"}

docker model pull ${MODEL}

SERVER_CMD="docker mcp gateway run"
# SERVER_CMD="node ./mcp-server/index.js"

MCP_TOOLS=$(get_mcp_tools "$SERVER_CMD")

# echo "---------------------------------------------------------"
# echo "Available tools:"
# echo "${MCP_TOOLS}"
# echo "---------------------------------------------------------"

# Transform tools to OpenAI format with filtering
# This will only include tools that match the filter criteria
# For example, if you want to filter tools that contain "search" or "fetch"
TOOLS=$(transform_to_openai_format "$MCP_TOOLS")
#TOOLS=$(transform_to_openai_format_with_filter "${MCP_TOOLS}" "search" "fetch")

read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "fetch https://raw.githubusercontent.com/k33g/osprey/refs/heads/main/README.md"
    }
  ],
  "tools": ${TOOLS},
  "parallel_tool_calls": true,
  "tool_choice": "auto"
}
EOM

echo "⏳ Making function call request..."
RESULT=$(osprey_tool_calls ${DMR_BASE_URL} "${DATA}")

echo "📝 Raw JSON response:"
print_raw_response "${RESULT}"

echo ""
echo "🛠️ Tool calls detected:"
print_tool_calls "${RESULT}"

# Get tool calls for further processing
TOOL_CALLS=$(get_tool_calls "${RESULT}")

if [[ -n "$TOOL_CALLS" ]]; then
    echo ""
    echo "🚀 Processing tool calls..."
    
    for tool_call in $TOOL_CALLS; do
        FUNCTION_NAME=$(get_function_name "$tool_call")
        FUNCTION_ARGS=$(get_function_args "$tool_call")
        CALL_ID=$(get_call_id "$tool_call")
        
        echo "Executing function: $FUNCTION_NAME with args: $FUNCTION_ARGS"
        
        # Execute function via MCP
        MCP_RESPONSE=$(call_mcp_tool "$SERVER_CMD" "$FUNCTION_NAME" "$FUNCTION_ARGS")
        RESULT_CONTENT=$(get_tool_content "$MCP_RESPONSE")
        
        echo "Function result: $RESULT_CONTENT"
    done
else
    echo "No tool calls found in response"
fi
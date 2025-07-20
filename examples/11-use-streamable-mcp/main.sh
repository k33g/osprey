#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.
COMMENT

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
#MODEL=${MODEL_RUNNER_TOOL_MODEL:-"hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_m"}
MODEL=${MODEL_RUNNER_TOOL_MODEL:-"hf.co/salesforce/llama-xlam-2-8b-fc-r-gguf:q4_k_m"}

docker model pull ${MODEL}

MCP_SERVER=${MCP_SERVER:-"http://localhost:9090"}


MCP_TOOLS=$(get_mcp_http_tools "$MCP_SERVER")
TOOLS=$(transform_to_openai_format "$MCP_TOOLS")

# echo "---------------------------------------------------------"
# echo "Available tools:"
# echo "${TOOLS}" 
# echo "---------------------------------------------------------"

: <<'COMMENT'
Examples of request with function calling:
Say Hello to Bob
Calculate the sum of 5 and 10
COMMENT


read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "Say hello to Bob and to Sam, make the sum of 5 and 37"
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
        MCP_RESPONSE=$(call_mcp_http_tool "$MCP_SERVER" "$FUNCTION_NAME" "$FUNCTION_ARGS")
        RESULT_CONTENT=$(get_tool_content_http "$MCP_RESPONSE")
        
        echo "Function result: $RESULT_CONTENT"
    done
else
    echo "No tool calls found in response"
fi
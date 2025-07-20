#!/bin/bash
. "./osprey.sh"

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL}
TOOLS_MODEL=${MODEL_RUNNER_TOOLS_MODEL}

#MCP_SERVER=${MCP_SERVER:-"http://localhost:9090"}

# === Get the list of tools from the MCP server ===
MCP_TOOLS=$(get_mcp_http_tools "$MCP_SERVER")
TOOLS=$(transform_to_openai_format "$MCP_TOOLS")

echo "---------------------------------------------------------"
echo "Available tools:"
echo "${TOOLS}" 
echo "---------------------------------------------------------"
echo "Using tools model: ${TOOLS_MODEL}"
echo "Using model runner: ${DMR_BASE_URL}"
echo "Using MCP server: ${MCP_SERVER}"
osprey_version
jq --version
echo "---------------------------------------------------------"

read -r -d '' USER_CONTENT <<- EOM
Say hello to Bob and to Sam, make the sum of 5 and 37
EOM

# === First, detect tool calls in the user input ===
read -r -d '' DATA <<- EOM
{
  "model": "${TOOLS_MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "${USER_CONTENT}"
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

# Execute tool calls if any
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


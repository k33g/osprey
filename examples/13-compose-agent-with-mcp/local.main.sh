#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.
COMMENT

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
CHAT_MODEL=${MODEL_RUNNER_CHAT_MODEL:-"ai/qwen2.5:latest"}
TOOLS_MODEL=${MODEL_RUNNER_TOOLS_MODEL:-"hf.co/salesforce/llama-xlam-2-8b-fc-r-gguf:q4_k_m"}

MCP_SERVER=${MCP_SERVER:-"http://localhost:9090"}

# === Get the list of tools from the MCP server ===
MCP_TOOLS=$(get_mcp_http_tools "$MCP_SERVER")
TOOLS=$(transform_to_openai_format "$MCP_TOOLS")

# echo "---------------------------------------------------------"
# echo "Available tools:"
# echo "${TOOLS}" 
# echo "---------------------------------------------------------"

# Initialize conversation history array
CONVERSATION_HISTORY=()

function callback() {
  echo -n "$1"
  # Accumulate assistant response to a temporary file
  echo -n "$1" >> /tmp/assistant_response.tmp
}

while true; do
  USER_CONTENT=$(gum write --placeholder "🤖 What can I do for you [/bye to exit]?")
  
  if [[ "$USER_CONTENT" == "/bye" ]]; then
    echo "Goodbye!"
    break
  fi

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
  "tools": ${TOOLS}

}
EOM

  echo "⏳ Making function call request..."
  RESULT=$(osprey_tool_calls ${DMR_BASE_URL} "${DATA}")
  # Get tool calls for further processing
  TOOL_CALLS=$(get_tool_calls "${RESULT}")

  TOOL_CALLS_RESULTS=""
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
          TOOL_CALLS_RESULTS+="- $RESULT_CONTENT"$'\n'
      done
  else
      echo "No tool calls found in response"
  fi

  # Add tool calls results to system message
  add_system_message CONVERSATION_HISTORY "${TOOL_CALLS_RESULTS}"

  # Add user message to conversation history
  add_user_message CONVERSATION_HISTORY "${USER_CONTENT}"

  # Build messages array with system message and conversation history
  MESSAGES=$(build_messages_array CONVERSATION_HISTORY)


  read -r -d '' DATA <<- EOM
{
  "model":"${CHAT_MODEL}",
  "options": {
    "temperature": 0.5,
    "repeat_last_n": 2
  },
  "messages": [${MESSAGES}],
  "stream": true
}
EOM

  # Clear assistant response for this turn
  rm -f /tmp/assistant_response.tmp
  
  osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
  
  # Read the accumulated response from the temp file
  ASSISTANT_RESPONSE=$(cat /tmp/assistant_response.tmp 2>/dev/null || echo "")

  # Add assistant response to conversation history (from callback)
  add_assistant_message CONVERSATION_HISTORY "${ASSISTANT_RESPONSE}"
  
  # For debugging purposes, print the conversation history
  echo -e "\n\n🟢 CONVERSATION_HISTORY: ${CONVERSATION_HISTORY[@]}\n"
  echo -e "\n\n🟣 ASSISTANT_RESPONSE: ${ASSISTANT_RESPONSE}\n"

  echo ""
  echo ""
done


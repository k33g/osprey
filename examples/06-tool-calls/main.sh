#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.
COMMENT

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
#MODEL=${MODEL_RUNNER_TOOLS_MODEL:-"hf.co/salesforce/xlam-2-3b-fc-r-gguf:q4_k_s"}
MODEL=${MODEL_RUNNER_TOOLS_MODEL:-"hf.co/salesforce/llama-xlam-2-8b-fc-r-gguf:q4_k_m"}

docker model pull ${MODEL}

# Example tools catalog in JSON format
read -r -d '' TOOLS <<- EOM
[
  {
    "type": "function",
    "function": {
      "name": "calculate_sum",
      "description": "Calculate the sum of two numbers",
      "parameters": {
        "type": "object",
        "properties": {
          "a": {
            "type": "number",
            "description": "The first number"
          },
          "b": {
            "type": "number",
            "description": "The second number"
          }
        },
        "required": ["a", "b"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "say_hello",
      "description": "Say hello to the given name",
      "parameters": {
        "type": "object",
        "properties": {
          "name": {
            "type": "string",
            "description": "The name to greet"
          }
        },
        "required": ["name"]
      }
    }
  }
]
EOM


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
        
        # Simulate function execution
        case "$FUNCTION_NAME" in
            "say_hello")
                NAME=$(echo "$FUNCTION_ARGS" | jq -r '.name')
                HELLO="👋 Hello, $NAME!🙂"
                RESULT_CONTENT="{\"message\": $HELLO}"
                ;;
            "calculate_sum")
                A=$(echo "$FUNCTION_ARGS" | jq -r '.a')
                B=$(echo "$FUNCTION_ARGS" | jq -r '.b')
                SUM=$((A + B))
                RESULT_CONTENT="{\"result\": $SUM}"
                ;;
            *)
                RESULT_CONTENT="{\"error\": \"Unknown function\"}"
                ;;
        esac
        
        echo "Function result: $RESULT_CONTENT"
    done
else
    echo "No tool calls found in response"
fi
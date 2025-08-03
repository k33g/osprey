#!/bin/bash
. "../../lib/osprey.sh"

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
#MODEL=${MODEL_RUNNER_TOOLS_MODEL:-"ai/gemma3:latest"}
MODEL=${MODEL_RUNNER_TOOL_MODEL:-"ai/qwen2.5:latest"}
#MODEL=${MODEL_RUNNER_TOOL_MODEL:-"hf.co/menlo/lucy-128k-gguf:q4_k_m"}

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


#USER_MESSAGE="Make the sum of 40 and 2, then say hello to Bob and to Sam, make the sum of 5 and 37"

read -r -d '' USER_MESSAGE <<- EOM
Make the sum of 40 and 2, 
then say hello to Bob and to Sam, 
make the sum of 5 and 37
Say hello to Alice
EOM

#USER_MESSAGE=$(echo "${USER_MESSAGE}" | tr '\n' ' ')


STOPPED="false"
SET_OF_MESSAGES=()

add_user_message SET_OF_MESSAGES "${USER_MESSAGE}"

while [ "$STOPPED" != "true" ]; do
  # Build messages array conversation history
  MESSAGES=$(build_messages_array SET_OF_MESSAGES)

  # Build request data
  read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [${MESSAGES}],
  "tools": ${TOOLS}
}
EOM

  echo "⏳ Making function call request..."
  RESULT=$(osprey_tool_calls ${DMR_BASE_URL} "${DATA}")

  #echo "📝 Raw JSON response:"
  #print_raw_response "${RESULT}"

  echo ""
  echo "🛠️💡 Tool call detected in user message:"
  print_tool_calls "${RESULT}"

  # Get tool calls for further processing
  TOOL_CALLS=$(get_tool_calls "${RESULT}")

  FINISH_REASON=$(get_finish_reason "${RESULT}")
  case $FINISH_REASON in
    tool_calls)
      if [[ -n "$TOOL_CALLS" ]]; then
        add_tool_calls_message SET_OF_MESSAGES "${TOOL_CALLS}"
        echo ""
        echo "🚀 Processing tool calls..."
  
        for tool_call in $TOOL_CALLS; do
          FUNCTION_NAME=$(get_function_name "$tool_call")
          FUNCTION_ARGS=$(get_function_args "$tool_call")
          CALL_ID=$(get_call_id "$tool_call")
          
          echo "▶️ Executing function: $FUNCTION_NAME with args: $FUNCTION_ARGS"
          
          RESULT_CONTENT=""
          # Function execution
          case "$FUNCTION_NAME" in
            "say_hello")
                NAME=$(echo "$FUNCTION_ARGS" | jq -r '.name')
                HELLO="👋 Hello, $NAME!🙂"
                RESULT_CONTENT="{\"message\": \"$HELLO\"}"
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
          
          echo -e "Function result: $RESULT_CONTENT\n\n"
          add_tool_message SET_OF_MESSAGES "${CALL_ID}" "${RESULT_CONTENT}"
        done
      else
          echo "No tool calls found in response"
      fi
      ;;
    stop)
      STOPPED="true"
      ASSISTANT_MESSAGE=$(echo "${RESULT}" | jq -r '.choices[0].message.content')

      echo "🤖 ${ASSISTANT_MESSAGE}"

      # Add assistant response to conversation history
      add_assistant_message SET_OF_MESSAGES "${ASSISTANT_MESSAGE}"
      ;;
    *)
      echo "🔴 unexpected response: $FINISH_REASON"
      ;;
  esac

done

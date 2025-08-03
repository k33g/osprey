#!/bin/bash
DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
MODEL=${MODEL_RUNNER_TOOL_MODEL:-"ai/qwen2.5:latest"}

# Tools index in JSON format
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

#USER_MESSAGE="Say hello to Bob and to Sam, make the sum of 5 and 37"
USER_MESSAGE="Make the sum of 5 and 37, then say hello to Bob and to Sam"

read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "${USER_MESSAGE}"
    }
  ],
  "tools": ${TOOLS}
}
EOM

# Remove newlines from DATA 
DATA=$(echo ${DATA} | tr -d '\n')

JSON_RESULT=$(curl --silent ${DMR_BASE_URL}/chat/completions \
    -H "Content-Type: application/json" \
    -d "${DATA}"
)

echo -e "\n📝 Raw JSON response:\n"
echo "${JSON_RESULT}" | jq '.'

echo -e "\n🔍 Extracted function calls:\n"
echo "${JSON_RESULT}" | jq -r '.choices[0].message.tool_calls[]? | "Function: \(.function.name), Args: \(.function.arguments)"'
echo -e "\n"

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
#MODEL=${MODEL_RUNNER_TOOLS_MODEL:-"hf.co/menlo/lucy-128k-gguf:q8_0"}
#MODEL=${MODEL_RUNNER_TOOLS_MODEL:-"hf.co/menlo/lucy-128k-gguf:q3_k_s"}
MODEL=${MODEL_RUNNER_TOOLS_MODEL:-"hf.co/menlo/lucy-gguf:q8_0"}


docker model pull ${MODEL}

# Example tools catalog in JSON format
read -r -d '' TOOLS <<- EOM
[
  {
    "type": "function",
    "function": {
      "name": "search",
      "description": "find relevant information based on a query",
      "parameters": {
        "type": "object",
        "properties": {
          "query": {
            "type": "string",
            "description": "The search query to find relevant information"
          }
        },
        "required": ["query"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "find",
      "description": "find relevant information based on a query",
      "parameters": {
        "type": "object",
        "properties": {
          "query": {
            "type": "string",
            "description": "The search query to find relevant information"
          }
        },
        "required": ["query"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "web_search",
      "description": "find relevant information on the web based on a query",
      "parameters": {
        "type": "object",
        "properties": {
          "q": {
            "type": "string",
            "description": "The search query to find relevant information"
          }
        },
        "required": ["q"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "visit_tool",
      "description": "fetch information from a URL",
      "parameters": {
        "type": "object",
        "properties": {
          "url": {
            "type": "string",
            "description": "The URL to visit for fetching information"
          },
          "includeMarkdown": {
            "type": "boolean",
            "description": "Whether to include markdown content in the response"
          }          
        },
        "required": ["url"]
      }
    }
  },
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
  }    
]
EOM


: <<'COMMENT'
Examples of request with function calling:
COMMENT

read -r -d '' USER_MESSAGE_1 <<- EOM
search information about the latest advancements in AI and machine learning
then find the best practices for implementing AI solutions in business
and finally, search for the top AI conferences in 2024
Research on the web the latest AI trends
and visit https://example.com for more details
EOM

read -r -d '' USER_MESSAGE_2 <<- EOM
Research on the web the latest AI trends
EOM

read -r -d '' USER_MESSAGE_3 <<- EOM
visit https://example.com for more details
EOM

read -r -d '' USER_MESSAGE_4 <<- EOM
Calculate the sum of 5 and 10
EOM

read -r -d '' DATA <<- EOM
{
  "model": "${MODEL}",
  "options": {
    "temperature": 0.0
  },
  "messages": [
    {
      "role": "user",
      "content": "${USER_MESSAGE_1}"
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
            "search")
                QUERY=$(echo "$FUNCTION_ARGS" | jq -r '.query')
                MESSAGE="🟢 Search for: $QUERY!"
                RESULT_CONTENT="{\"message\": $MESSAGE}"
                ;;
            "find")
                QUERY=$(echo "$FUNCTION_ARGS" | jq -r '.query')
                MESSAGE="🟣 Find: $QUERY!"
                RESULT_CONTENT="{\"message\": $MESSAGE}"
                ;;
            "web_search")
                QUERY=$(echo "$FUNCTION_ARGS" | jq -r '.q')
                MESSAGE="🌍 web_search: $QUERY!"
                RESULT_CONTENT="{\"message\": $MESSAGE}"
                ;;
            "visit_tool")
                QUERY=$(echo "$FUNCTION_ARGS" | jq -r '.url')
                MESSAGE="🛠️ visit_tool: $URL!"
                RESULT_CONTENT="{\"message\": $MESSAGE}"
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
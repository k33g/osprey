#!/bin/bash
: <<'COMMENT'
=== Osprey - A Bash library for interacting with the DMR API ===

This script provides functions to interact with the DMR API for chat completions.
COMMENT

function osprey_version() {
    echo "Osprey - A Bash library for interacting with the DMR API"
    echo "Version: v0.0.6"
    echo "Author: k33g"
    echo "License: unlicense"
}

: <<'COMMENT'
remove_new_lines - removes newline characters from input text. 
It takes a string as input, strips all newline characters (\n) using tr -d '\n', 
and returns the "sanitized" content. 

 Args:
    CONTENT (str): The content to be "sanitized".

 Returns:
    str: The "sanitized" content.
COMMENT
function remove_new_lines() {
    CONTENT="${1}"
    CONTENT=$(echo ${CONTENT} | tr -d '\n')
    echo "${CONTENT}"
}

: <<'COMMENT'
osprey_chat - Generates a response using the DMR API.

 Args:
    DMR_BASE_URL (str): The URL of the DMR API.
    DATA (str): The JSON data to be sent to the API.

 Returns:
    str: The JSON response from the API, containing the generated response and context.
COMMENT
function osprey_chat() {
    DMR_BASE_URL="${1}"
    DATA="${2}"

    DATA=$(remove_new_lines "${DATA}")

    JSON_RESULT=$(curl --silent ${DMR_BASE_URL}/chat/completions \
        -H "Content-Type: application/json" \
        -d "${DATA}"
    )

    MESSAGE_CONTENT=$(echo "${JSON_RESULT}" | jq -r '.choices[0].message.content')

    echo "${MESSAGE_CONTENT}"
}

: <<'COMMENT'
remove_quotes - Removes leading and trailing quotes from a string.

 Args:
    str (str): The string to remove quotes from.

 Returns:
    str: The string without leading and trailing quotes.

COMMENT
remove_quotes() {
    local str="$1"
    str="${str%\"}"   # remove " at the end
    str="${str#\"}"   # remove " at start
    echo "$str"
}

: <<'COMMENT'
unescape_quotes - Unescapes quotes in a string by replacing \" with ".

 Args:
    str (str): The string to unescape quotes in.

 Returns:
    str: The string with unescaped quotes.
COMMENT
unescape_quotes() {
    local str="$1"
    str="${str//\\\"/\"}"  # Replace \" by "
    echo "$str"
}

: <<'COMMENT'
osprey_chat_stream - Generates a response using the DMR API in a streaming manner.

 Args:
   - DMR_BASE_URL (str): The URL of the DMR API.
   - DATA (str): The JSON data to be sent to the API.
   - CALL_BACK (function): The callback function to handle each line of the response.
   - REASONING_CONTENT (str): if =="display_reasoning" include reasoning content in the response.

 Returns:
   None
COMMENT
function osprey_chat_stream() {
    DMR_BASE_URL="${1}"
    DATA="${2}"
    CALL_BACK=${3}
    REASONING_CONTENT=${4}

    DATA=$(remove_new_lines "${DATA}")

    curl --no-buffer --silent ${DMR_BASE_URL}/chat/completions \
        -H "Content-Type: application/json" \
        -d "${DATA}" \
        | while IFS= read -r line; do
            #echo "📝 $line"
            if [[ $line == data:* ]]; then
            
                json_data="${line#data: }"
                if [[ $json_data != "[DONE]" ]]; then

                    # prettyprint
                    #echo "$json_data" | jq .

                    # Extract content if it exists, else return "null"
                    content_chunk=$(echo "$json_data" | jq '.choices[0].delta.content // "null"' 2>/dev/null)

                    if [[ "$REASONING_CONTENT" == "display_reasoning" ]]; then
                        # Extract reasoning_content if it exists, else return "null"
                        reasoning_chunk=$(echo "$json_data" | jq '.choices[0].delta.reasoning_content // "null"' 2>/dev/null)
                        if [[ "$reasoning_chunk" != "\"null\"" ]]; then
                            #echo "🧠 Reasoning: $reasoning_chunk"
                            result=$(remove_quotes "$reasoning_chunk")
                            clean_result=$(unescape_quotes "$result")
                            #echo -ne "$clean_result"
                            $CALL_BACK "$clean_result"
                        fi
                    fi

                    if [[ "$content_chunk" != "\"null\"" ]]; then
                        #echo "📝 Content: $content_chunk" 
                        result=$(remove_quotes "$content_chunk")
                        clean_result=$(unescape_quotes "$result")
                        #echo -ne "$clean_result"
                        $CALL_BACK "$clean_result"
                    fi

                fi
            fi
        done        
        
}

: <<'COMMENT'
Conversation memory management functions for handling chat history.
COMMENT

function add_user_message() {
  local conversation_history_var="$1"
  local user_content="$2"
  eval "${conversation_history_var}+=(\"{\\\"role\\\":\\\"user\\\", \\\"content\\\": \\\"${user_content//\"/\\\\\\\"}\\\"}\")"
}

function add_assistant_message() {
  local conversation_history_var="$1"
  local assistant_content="$2"
  eval "${conversation_history_var}+=(\"{\\\"role\\\":\\\"assistant\\\", \\\"content\\\": \\\"${assistant_content//\"/\\\\\\\"}\\\"}\")"
}

function add_system_message() {
  local conversation_history_var="$1"
  local system_content="$2"
  eval "${conversation_history_var}+=(\"{\\\"role\\\":\\\"system\\\", \\\"content\\\": \\\"${system_content//\"/\\\\\\\"}\\\"}\")"
}

function build_messages_array() {
  local conversation_history_var="$1"
  local messages="{\"role\":\"system\", \"content\": \"${SYSTEM_INSTRUCTION}\"}"
  eval "local conversation_history_array=(\"\${${conversation_history_var}[@]}\")"
  for msg in "${conversation_history_array[@]}"; do
    messages="${messages}, ${msg}"
  done
  echo "${messages}"
}

function clear_conversation_history() {
  CONVERSATION_HISTORY=()
}

: <<'COMMENT'
osprey_tool_calls - Generates a response using the DMR API with function calling support.

 Args:
    DMR_BASE_URL (str): The URL of the DMR API.
    DATA (str): The JSON data to be sent to the API, including tools catalog.

 Returns:
    str: The JSON response from the API as a string.
COMMENT
function osprey_tool_calls() {
    DMR_BASE_URL="${1}"
    DATA="${2}"

    DATA=$(remove_new_lines "${DATA}")

    JSON_RESULT=$(curl --silent ${DMR_BASE_URL}/chat/completions \
        -H "Content-Type: application/json" \
        -d "${DATA}"
    )

    echo "${JSON_RESULT}"
}

: <<'COMMENT'
print_raw_response - Prints the raw JSON response with formatting.

Args:
    result (str): The JSON response to print.

Returns:
    None
COMMENT
function print_raw_response() {
    local result="$1"
    #echo "Raw JSON response:"
    echo "${result}" | jq '.'
}

: <<'COMMENT'
print_tool_calls - Prints detected tool calls from the response.

Args:
    result (str): The JSON response containing tool calls.

Returns:
    None
COMMENT
function print_tool_calls() {
    local result="$1"
    #echo "Tool calls detected:"
    echo "${result}" | jq -r '.choices[0].message.tool_calls[]? | "Function: \(.function.name), Args: \(.function.arguments)"'
}

: <<'COMMENT'
get_tool_calls - Extracts tool calls from the response and returns them as base64-encoded strings.

Args:
    result (str): The JSON response containing tool calls.

Returns:
    str: Base64-encoded tool calls, one per line.
COMMENT
function get_tool_calls() {
    local result="$1"
    # Check if there are tool calls to process
    echo "${result}" | jq -r '.choices[0].message.tool_calls[]? | @base64'
}

: <<'COMMENT'
decode_tool_call - Decodes a base64-encoded tool call.

Args:
    tool_call (str): Base64-encoded tool call.

Returns:
    str: Decoded JSON tool call.
COMMENT
function decode_tool_call() {
    local tool_call="$1"
    echo "$tool_call" | base64 -d
}

: <<'COMMENT'
get_function_name - Extracts the function name from a base64-encoded tool call.

Args:
    tool_call (str): Base64-encoded tool call.

Returns:
    str: The function name.
COMMENT
function get_function_name() {
    local tool_call="$1"
    local decoded=$(decode_tool_call "$tool_call")
    echo "$decoded" | jq -r '.function.name'
}

: <<'COMMENT'
get_function_args - Extracts the function arguments from a base64-encoded tool call.

Args:
    tool_call (str): Base64-encoded tool call.

Returns:
    str: The function arguments as JSON string.
COMMENT
function get_function_args() {
    local tool_call="$1"
    local decoded=$(decode_tool_call "$tool_call")
    echo "$decoded" | jq -r '.function.arguments'
}

: <<'COMMENT'
get_call_id - Extracts the call ID from a base64-encoded tool call.

Args:
    tool_call (str): Base64-encoded tool call.

Returns:
    str: The call ID.
COMMENT
function get_call_id() {
    local tool_call="$1"
    local decoded=$(decode_tool_call "$tool_call")
    echo "$decoded" | jq -r '.id'
}

: <<'COMMENT'
get_mcp_tools - Gets the tools list from an MCP server by sending the proper initialization sequence.

Args:
    server_command (str): The command to run the MCP server (e.g., "node index.js").

Returns:
    str: JSON array of tools from the MCP server.
COMMENT
function get_mcp_tools() {
    local server_command="$1"
    
    if [ -z "$server_command" ]; then
        echo "Error: Server command is required" >&2
        return 1
    fi
    
    # Create a temporary input file with the MCP initialization sequence
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << 'EOF'
{"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "osprey", "version": "0.0.2"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}
EOF
    
    # Run the server with the input and extract tools list
    local result=$(cat "$temp_file" | $server_command 2>/dev/null | jq -r 'select(.id == 2) | .result.tools')
    
    # Clean up
    rm "$temp_file"
    
    # Return the tools list
    echo "$result"
}

: <<'COMMENT'
transform_to_openai_format - Transforms MCP tools format to OpenAI API format for function calling.

Args:
    mcp_tools (str): JSON array of tools in MCP format.

Returns:
    str: JSON array of tools in OpenAI API format.
COMMENT
function transform_to_openai_format() {
    local mcp_tools="$1"
    
    if [ -z "$mcp_tools" ] || [ "$mcp_tools" = "null" ]; then
        echo "[]"
        return
    fi
    
    echo "$mcp_tools" | jq '[
        .[] | {
            "type": "function",
            "function": {
                "name": .name,
                "description": .description,
                "parameters": (
                    .inputSchema | 
                    del(."$schema") | 
                    del(.additionalProperties) |
                    if .properties then
                        .properties |= with_entries(
                            if .value.description then . 
                            else .value += {"description": ("The " + .key + " parameter")}
                            end
                        )
                    else . end
                )
            }
        }
    ]'
}

: <<'COMMENT'
transform_to_openai_format_with_filter - Transforms MCP tools format to OpenAI API format for function calling with filtering.

Args:
    mcp_tools (str): JSON array of tools in MCP format.
    filters (array): Array of tool names to include (e.g., ("tool1" "tool2" "tool3")).

Returns:
    str: JSON array of filtered tools in OpenAI API format.
COMMENT
function transform_to_openai_format_with_filter() {
    local mcp_tools="$1"
    shift
    local filters=("$@")
    
    if [ -z "$mcp_tools" ] || [ "$mcp_tools" = "null" ]; then
        echo "[]"
        return
    fi
    
    if [ ${#filters[@]} -eq 0 ]; then
        echo "[]"
        return
    fi
    
    # Create a JQ filter expression for the tool names
    local filter_expression=""
    for tool in "${filters[@]}"; do
        if [ -z "$filter_expression" ]; then
            filter_expression=".name == \"$tool\""
        else
            filter_expression="$filter_expression or .name == \"$tool\""
        fi
    done
    
    echo "$mcp_tools" | jq '[
        .[] | select('"$filter_expression"') | {
            "type": "function",
            "function": {
                "name": .name,
                "description": .description,
                "parameters": (
                    .inputSchema | 
                    del(."$schema") | 
                    del(.additionalProperties) |
                    if .properties then
                        .properties |= with_entries(
                            if .value.description then . 
                            else .value += {"description": ("The " + .key + " parameter")}
                            end
                        )
                    else . end
                )
            }
        }
    ]'
}

: <<'COMMENT'
call_mcp_tool - Calls an MCP tool by sending the proper initialization sequence and tool call request.

Args:
    server_command (str): The command to run the MCP server (e.g., "node index.js").
    tool_name (str): The name of the tool to call.
    tool_arguments (str): JSON string of arguments to pass to the tool.

Returns:
    str: Complete JSON response from the MCP server including the tool call result.
COMMENT
function call_mcp_tool() {
    local server_command="$1"
    local tool_name="$2"
    local tool_arguments="$3"
    
    if [ -z "$server_command" ]; then
        echo "Error: Server command is required" >&2
        return 1
    fi
    
    if [ -z "$tool_name" ]; then
        echo "Error: Tool name is required" >&2
        return 1
    fi
    
    if [ -z "$tool_arguments" ]; then
        tool_arguments="{}"
    fi
    
    # Create a temporary input file with the MCP initialization sequence and tool call
    local temp_file=$(mktemp)
    
    cat > "$temp_file" << EOF
{"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {"protocolVersion": "2025-03-26", "capabilities": {}, "clientInfo": {"name": "osprey", "version": "0.0.2"}}}
{"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}
{"jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": {"name": "$tool_name", "arguments": $tool_arguments}}
EOF
    
    # Run the server with the input and extract the tool call response
    local result=$(cat "$temp_file" | $server_command 2>/dev/null | jq -c '.' | jq -s '.')
    
    # Clean up
    rm "$temp_file"
    
    # Return the response
    echo "$result"
}

: <<'COMMENT'
get_tool_content - Extracts the text content from an MCP tool call response.

Args:
    response (str): The JSON response from call_mcp_tool function.

Returns:
    str: The text content from the tool call result.
COMMENT
function get_tool_content() {
    local response="$1"
    
    if [ -z "$response" ]; then
        echo "Error: Response is required" >&2
        return 1
    fi
    
    # Extract the content text from the tool call response
    echo "$response" | jq -r '.[] | select(.id == 2) | .result.content[0].text'
}

: <<'COMMENT'
get_tool_content_http - Extracts the text content from an MCP HTTP tool call response.

Args:
    response (str): The JSON response from call_mcp_http_tool function.

Returns:
    str: The text content from the tool call result.
COMMENT
function get_tool_content_http() {
    local response="$1"
    
    if [ -z "$response" ]; then
        echo "Error: Response is required" >&2
        return 1
    fi
    
    # Extract the content text from the HTTP tool call response
    echo "$response" | jq -r '.result.content[0].text'
}

: <<'COMMENT'
get_mcp_http_tools - Gets the tools list from an MCP HTTP server by sending the proper initialization sequence.

Args:
    mcp_server_url (str): The URL of the MCP HTTP server (e.g., "http://localhost:9090").

Returns:
    str: JSON array of tools from the MCP HTTP server.
COMMENT
function get_mcp_http_tools() {
    local mcp_server_url="$1"
    
    if [ -z "$mcp_server_url" ]; then
        echo "Error: MCP server URL is required" >&2
        return 1
    fi
    
    # STEP 1: Initialize the server and get session ID
    local init_data='{
        "jsonrpc": "2.0",
        "method": "initialize",
        "id": "init-uuid",
        "params": {
            "protocolVersion": "2024-11-05"
        }
    }'
    
    # Get the session ID from headers
    local session_id=$(curl -i -s -X POST \
        -H "Content-Type: application/json" \
        -d "$init_data" \
        "$mcp_server_url/mcp" | grep -i "mcp-session-id:" | cut -d' ' -f2 | tr -d '\r\n')
    
    if [ -z "$session_id" ]; then
        echo "Error: Failed to get session ID from MCP server" >&2
        return 1
    fi
    
    # STEP 2: Get tools list using the session ID
    local tools_data='{
        "jsonrpc": "2.0",
        "id": "tools-list",
        "method": "tools/list",
        "params": {}
    }'
    
    # Get tools list
    local result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Mcp-Session-Id: $session_id" \
        -d "$tools_data" \
        "$mcp_server_url/mcp" | jq -r '.result.tools')
    
    # Return the tools list
    echo "$result"
}

: <<'COMMENT'
call_mcp_http_tool - Calls an MCP tool on an HTTP server by sending the proper initialization sequence and tool call request.

Args:
    mcp_server_url (str): The URL of the MCP HTTP server (e.g., "http://localhost:9090").
    tool_name (str): The name of the tool to call.
    tool_arguments (str): JSON string of arguments to pass to the tool.

Returns:
    str: Complete JSON response from the MCP HTTP server including the tool call result.
COMMENT
function call_mcp_http_tool() {
    local mcp_server_url="$1"
    local tool_name="$2"
    local tool_arguments="$3"
    
    if [ -z "$mcp_server_url" ]; then
        echo "Error: MCP server URL is required" >&2
        return 1
    fi
    
    if [ -z "$tool_name" ]; then
        echo "Error: Tool name is required" >&2
        return 1
    fi
    
    if [ -z "$tool_arguments" ]; then
        tool_arguments="{}"
    fi
    
    # STEP 1: Initialize the server and get session ID
    local init_data='{
        "jsonrpc": "2.0",
        "method": "initialize",
        "id": "init-uuid",
        "params": {
            "protocolVersion": "2024-11-05"
        }
    }'
    
    # Get the session ID from headers
    local session_id=$(curl -i -s -X POST \
        -H "Content-Type: application/json" \
        -d "$init_data" \
        "$mcp_server_url/mcp" | grep -i "mcp-session-id:" | cut -d' ' -f2 | tr -d '\r\n')
    
    if [ -z "$session_id" ]; then
        echo "Error: Failed to get session ID from MCP server" >&2
        return 1
    fi
    
    # STEP 2: Call the tool using the session ID
    local call_data=$(cat << EOF
{
    "jsonrpc": "2.0",
    "id": "tool-call",
    "method": "tools/call",
    "params": {
        "name": "$tool_name",
        "arguments": $tool_arguments
    }
}
EOF
)
    
    # Call the tool and return the complete response
    local result=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Mcp-Session-Id: $session_id" \
        -d "$call_data" \
        "$mcp_server_url/mcp")
    
    # Return the response
    echo "$result"
}

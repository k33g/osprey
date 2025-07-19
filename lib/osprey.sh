#!/bin/bash
: <<'COMMENT'
=== Osprey - A Bash library for interacting with the DMR API ===

This script provides functions to interact with the DMR API for chat completions.
COMMENT

function osprey_version() {
    echo "Osprey - A Bash library for interacting with the DMR API"
    echo "Version: 0.0.2"
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
on_stream - Processes each line of the streaming response from the DMR API.
 It checks if the line starts with "data:", extracts the content, and calls the callback function.

 Args:
    linestream (str): The line of data from the stream.
    CALL_BACK (function): The callback function to handle the processed data.

 Returns:
    None
COMMENT
function on_stream() {
  [[ -z "$1" || "$1" != data:* ]] && return
  
  json_data="${1#data: }"
  [[ "$json_data" == "[DONE]" ]] && return
  
  data=$(echo "$json_data" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
  [[ -n "$data" ]] && echo -n "$data"
}

: <<'COMMENT'
osprey_chat_stream - Generates a response using the DMR API in a streaming manner.

 Args:
   - DMR_BASE_URL (str): The URL of the DMR API.
   - DATA (str): The JSON data to be sent to the API.
   - CALL_BACK (function): The callback function to handle each line of the response.

 Returns:
   None
COMMENT
function osprey_chat_stream() {
    DMR_BASE_URL="${1}"
    DATA="${2}"
    CALL_BACK=${3}

    DATA=$(remove_new_lines "${DATA}")

    curl --no-buffer --silent ${DMR_BASE_URL}/chat/completions \
        -H "Content-Type: application/json" \
        -d "${DATA}" | while read linestream
        do
            on_stream "${linestream}" ${CALL_BACK}
        done 
}

: <<'COMMENT'
Conversation memory management functions for handling chat history.
COMMENT

function add_user_message() {
  local user_content="$1"
  CONVERSATION_HISTORY+=("{\"role\":\"user\", \"content\": \"${user_content//\"/\\\"}\"}")
}

function add_assistant_message() {
  local assistant_content="$1"
  CONVERSATION_HISTORY+=("{\"role\":\"assistant\", \"content\": \"${assistant_content//\"/\\\"}\"}")
}

function add_system_message() {
  local system_content="$1"
  CONVERSATION_HISTORY+=("{\"role\":\"system\", \"content\": \"${system_content//\"/\\\"}\"}")
}

function build_messages_array() {
  MESSAGES="{\"role\":\"system\", \"content\": \"${SYSTEM_INSTRUCTION}\"}"
  for msg in "${CONVERSATION_HISTORY[@]}"; do
    MESSAGES="${MESSAGES}, ${msg}"
  done
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
    echo "Raw JSON response:"
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
    echo "Tool calls detected:"
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

#!/bin/bash
: <<'COMMENT'
=== Osprey - A Bash library for interacting with the DMR API ===

This script provides functions to interact with the DMR API for chat completions.
COMMENT

function osprey_version() {
    echo "Osprey - A Bash library for interacting with the DMR API"
    echo "Version: 0.0.0"
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

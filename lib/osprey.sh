#!/bin/bash


: <<'COMMENT'
Chat - Generates a response using the OLLAMA API.

 Args:
    OLLAMA_URL (str): The URL of the OLLAMA API.
    DATA (str): The JSON data to be sent to the API.

 Returns:
    str: The JSON response from the API, containing the generated response and context.
COMMENT
function Chat() {
    DMR_BASE_URL="${1}"
    DATA="${2}"

    JSON_RESULT=$(curl --silent ${DMR_BASE_URL}/chat/completions \
        -H "Content-Type: application/json" \
        -d "${DATA}"
    )
    echo "${JSON_RESULT}"
}

: <<'COMMENT'
ChatStream - Generates a response using the OLLAMA API in a streaming manner.

 Args:
   - OLLAMA_URL (str): The URL of the OLLAMA API.
   - DATA (str): The JSON data to be sent to the API.
   - CALL_BACK (function): The callback function to handle each line of the response.

 Returns:
   None
COMMENT
function ChatStream() {
    DMR_BASE_URL="${1}"
    DATA="${2}"
    CALL_BACK=${3}

    curl --no-buffer --silent ${DMR_BASE_URL}/chat/completions \
        -H "Content-Type: application/json" \
        -d "${DATA}" | while read linestream
        do
            ${CALL_BACK} "${linestream}"
        done 
}

: <<'COMMENT'
RemoveNewlines - removes newline characters from input text. 
It takes a string as input, strips all newline characters (\n) using tr -d '\n', 
and returns the "sanitized" content. 

 Args:
    CONTENT (str): The content to be "sanitized".

 Returns:
    str: The "sanitized" content.
COMMENT
function RemoveNewlines() {
    CONTENT="${1}"
    CONTENT=$(echo ${CONTENT} | tr -d '\n')
    echo "${CONTENT}"
}


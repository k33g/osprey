#!/bin/bash

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
#MODEL=${MODEL_RUNNER_CHAT_MODEL:-"ai/qwen2.5:0.5B-F16"}
MODEL=${MODEL_RUNNER_CHAT_MODEL:-"ai/qwen2.5:latest"}
docker model pull ${MODEL}
#DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:11434/v1}
#MODEL=${MODEL_RUNNER_CHAT_MODEL:-"qwen2.5:latest"}


read -r -d '' SYSTEM_INSTRUCTION <<- EOM
You are a Golang expert.
EOM

read -r -d '' USER_CONTENT <<- EOM
Generate a Golang Hello World program.
EOM

read -r -d '' DATA <<- EOM
{
  "model":"${MODEL}",
  "options": {
    "temperature": 0.5
  },
  "messages": [
    {"role":"system", "content": "${SYSTEM_INSTRUCTION}"},
    {"role":"user", "content": "${USER_CONTENT}"}
  ],
  "stream": true
}
EOM

function remove_new_lines() {
    CONTENT="${1}"
    CONTENT=$(echo ${CONTENT} | tr -d '\n')
    echo "${CONTENT}"
}

function on_stream() {
  [[ -z "$1" || "$1" != data:* ]] && return
  
  json_data="${1#data: }"
  [[ "$json_data" == "[DONE]" ]] && return
  
  data=$(echo "$json_data" | jq -r '.choices[0].delta.content // empty' 2>/dev/null)
  [[ -n "$data" && -n "$2" ]] && $2 "$data"
}


function osprey_chat_stream() {
    DMR_BASE_URL="${1}"
    DATA="${2}"
    CALL_BACK=${3}

    DATA=$(remove_new_lines "${DATA}")

    curl --no-buffer --silent ${DMR_BASE_URL}/chat/completions \
        -H "Content-Type: application/json" \
        -d "${DATA}" | while read linestream
        do
            #on_stream "${linestream}" "${CALL_BACK}"
            ${CALL_BACK} "${linestream}"
        done 
}

function callback() {
  echo -n "$1" 
}

osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback

echo ""
echo ""
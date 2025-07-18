#!/bin/bash
. "../../lib/osprey.sh"

DMR_BASE_URL=${DMR_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}

MODEL="ai/qwen2.5:latest"


read -r -d '' SYSTEM_CONTENT <<- EOM
You are an expert of the StarTrek universe. 
Your name is Seven of Nine.
Speak like a Borg.
EOM

read -r -d '' USER_CONTENT <<- EOM
Who is Jean-Luc Picard?
EOM

SYSTEM_CONTENT=$(RemoveNewlines "${SYSTEM_CONTENT}")
USER_CONTENT=$(RemoveNewlines "${USER_CONTENT}")


read -r -d '' DATA <<- EOM
{
  "model":"${MODEL}",
  "options": {
    "temperature": 0.5,
    "repeat_last_n": 2
  },
  "messages": [
    {"role":"system", "content": "${SYSTEM_CONTENT}"},
    {"role":"user", "content": "${USER_CONTENT}"}
  ],
  "stream": true
}
EOM

function onChunk() {
  [[ -z "$1" || "$1" != data:* ]] && return
  
  data=$(echo "${1#data: }" | jq -r '.choices[0].delta.content // empty')
  [[ -n "$data" ]] && echo -n "$data"
}

ChatStream "${DMR_BASE_URL}" "${DATA}" onChunk

echo ""



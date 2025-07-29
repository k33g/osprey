#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
Use it with Ollama
COMMENT

BASE_URL=${OLLAMA_BASE_URL:-http://localhost:11434/v1}
MODEL=${OLLAMA_CHAT_MODEL:-"qwen2.5:latest"}


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
    "temperature": 0.5,
    "repeat_last_n": 2
  },
  "messages": [
    {"role":"system", "content": "${SYSTEM_INSTRUCTION}"},
    {"role":"user", "content": "${USER_CONTENT}"}
  ],
  "stream": true
}
EOM

function callback() {
  echo -ne "$1" 
}

osprey_chat_stream ${BASE_URL} "${DATA}" callback display_reasoning

echo ""
echo ""

#!/bin/bash
. "../../lib/osprey.sh"

DMR_BASE_URL=${DMR_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}

MODEL="ai/qwen2.5:latest"


read -r -d '' SYSTEM_INSTRUCTION <<- EOM
You are an expert of the StarTrek universe. 
Your name is Seven of Nine.
Speak like a Borg.
EOM

read -r -d '' USER_CONTENT <<- EOM
Who is Jean-Luc Picard?
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
  "stream": false,
  "raw": false
}
EOM

completion=$(osprey_chat ${DMR_BASE_URL} "${DATA}")
echo "${completion}" 



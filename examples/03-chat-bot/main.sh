#!/bin/bash
. "../../lib/osprey.sh"

DMR_BASE_URL=${DMR_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}

MODEL="ai/qwen2.5:latest"

read -r -d '' SYSTEM_CONTENT <<- EOM
You are an expert of the StarTrek universe. 
Your name is Seven of Nine.
Speak like a Borg.
EOM

function callback() {
  echo -n "$1" 
}

while true; do
  USER_CONTENT=$(gum write --placeholder "🤖 What can I do for you?")
  
  if [[ "$USER_CONTENT" == "/bye" ]]; then
    echo "Goodbye!"
    break
  fi

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

  osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
  echo ""
  echo ""
done


#!/bin/bash
. "../../lib/osprey.sh"

DMR_BASE_URL=${DMR_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}

MODEL="ai/qwen2.5:latest"

read -r -d '' SYSTEM_CONTENT <<- EOM
You are an expert of the StarTrek universe. 
Your name is Seven of Nine.
Speak like a Borg.
EOM

# Initialize conversation history array
CONVERSATION_HISTORY=()

function callback() {
  echo -n "$1"
  # Accumulate assistant response
  ASSISTANT_RESPONSE+="$1"
}

while true; do
  USER_CONTENT=$(gum write --placeholder "🤖 What can I do for you [/bye to exit]?")
  
  if [[ "$USER_CONTENT" == "/bye" ]]; then
    echo "Goodbye!"
    break
  fi

  # Add user message to conversation history
  CONVERSATION_HISTORY+=("{\"role\":\"user\", \"content\": \"${USER_CONTENT//\"/\\\"}\"}")
  
  # Build messages array with system message and conversation history
  MESSAGES="{\"role\":\"system\", \"content\": \"${SYSTEM_CONTENT}\"}"
  for msg in "${CONVERSATION_HISTORY[@]}"; do
    MESSAGES="${MESSAGES}, ${msg}"
  done

  read -r -d '' DATA <<- EOM
{
  "model":"${MODEL}",
  "options": {
    "temperature": 0.5,
    "repeat_last_n": 2
  },
  "messages": [${MESSAGES}],
  "stream": true
}
EOM

  # Clear assistant response for this turn
  ASSISTANT_RESPONSE=""
  
  osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
  
  # Add assistant response to conversation history
  CONVERSATION_HISTORY+=("{\"role\":\"assistant\", \"content\": \"${ASSISTANT_RESPONSE//\"/\\\"}\"}")
  
  echo ""
  echo ""
done


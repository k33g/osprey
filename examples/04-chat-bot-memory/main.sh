#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.
COMMENT

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
MODEL=${MODEL_RUNNER_CHAT_MODEL:-"ai/qwen2.5:latest"}

docker model pull ${MODEL}  

read -r -d '' SYSTEM_INSTRUCTION <<- EOM
You are an expert of the StarTrek universe. 
Your name is Seven of Nine.
Speak like a Borg.
EOM

# Initialize conversation history array
CONVERSATION_HISTORY=()

function callback() {
  echo -ne "$1"
  # Accumulate assistant response to a temporary file
  echo -n "$1" >> /tmp/assistant_response.tmp
}

add_system_message CONVERSATION_HISTORY "${SYSTEM_INSTRUCTION}"
add_system_message CONVERSATION_HISTORY "and with humour and sarcasm"


while true; do
  USER_CONTENT=$(gum write --placeholder "🤖 What can I do for you [/bye to exit]?")
  
  if [[ "$USER_CONTENT" == "/bye" ]]; then
    echo "Goodbye!"
    break
  fi


  # Add a user message - pass the array name and the message content
  add_user_message CONVERSATION_HISTORY "${USER_CONTENT}"

  # Build and capture the messages array
  MESSAGES=$(build_messages_array CONVERSATION_HISTORY)


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
  rm -f /tmp/assistant_response.tmp
  
  osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
  
  # Read the accumulated response from the temp file
  ASSISTANT_RESPONSE=$(cat /tmp/assistant_response.tmp 2>/dev/null || echo "")

  # Add assistant response to conversation history (from callback)
  add_assistant_message CONVERSATION_HISTORY "${ASSISTANT_RESPONSE}"
  
  # For debugging purposes, print the conversation history
  echo -e "\n\n🟢 CONVERSATION_HISTORY: ${CONVERSATION_HISTORY[@]}\n"

  echo ""
  echo ""
done


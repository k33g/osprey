#!/bin/bash
. "./osprey.sh"

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL}
MODEL=${MODEL_RUNNER_CHAT_MODEL}

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
  add_user_message CONVERSATION_HISTORY "${USER_CONTENT}"
  
  # Build messages array with system message and conversation history
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
  ASSISTANT_RESPONSE=""
  
  osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback
  
  # Add assistant response to conversation history
  add_assistant_message CONVERSATION_HISTORY "${ASSISTANT_RESPONSE}"
  
  echo ""
  echo ""
done


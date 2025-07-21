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

echo "DMR_BASE_URL: ${DMR_BASE_URL}"
echo "MODEL: ${MODEL}"

SYSTEM_INSTRUCTIONS=$(< config.system.instructions.md)
#echo "SYSTEM_INSTRUCTIONS: ${SYSTEM_INSTRUCTIONS}"
USER_CONTENT=$(< config.user.message.md)
#echo ""
#echo "USER_CONTENT: ${USER_CONTENT}"

SOURCE_CODE=$(< $1)

# Function to escape JSON strings
escape_json() {
  printf '%s' "$1" | jq -Rs .
}

# Escape the content for JSON
SYSTEM_INSTRUCTIONS_ESCAPED=$(escape_json "$SYSTEM_INSTRUCTIONS")
USER_CONTENT_ESCAPED=$(escape_json "$USER_CONTENT")
SOURCE_CODE_ESCAPED=$(escape_json "$SOURCE_CODE")

if [[ -z "${SOURCE_CODE}" ]]; then
  echo "Error: No source code provided. Please provide a file path as an argument."
  exit 1
fi
#echo ""
#echo "SOURCE_CODE: ${SOURCE_CODE}"


read -r -d '' DATA <<- EOM
{
  "model":"${MODEL}",
  "options": {
    "temperature": 0.5,
    "repeat_last_n": 2
  },
  "messages": [
    {"role":"system", "content": ${SYSTEM_INSTRUCTIONS_ESCAPED}},
    {"role":"system", "content": ${SOURCE_CODE_ESCAPED}},
    {"role":"user", "content": ${USER_CONTENT_ESCAPED}}
  ],
  "stream": true
}
EOM

function callback() {
  echo -n "$1" 
}

osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback

echo ""
echo ""



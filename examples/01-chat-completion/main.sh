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

echo "Using DATA: ${DATA}"
echo "Using DMR_BASE_URL: ${DMR_BASE_URL}"

osprey_version

completion=$(osprey_chat ${DMR_BASE_URL} "${DATA}")
echo "${completion}" 



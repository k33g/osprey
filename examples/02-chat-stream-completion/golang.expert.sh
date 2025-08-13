#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.
COMMENT

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
MODEL=${MODEL_RUNNER_CHAT_MODEL:-"hf.co/menlo/lucy-128k-gguf:q4_k_m"}

#MODEL=${MODEL_RUNNER_CHAT_MODEL:-"ai/gpt-oss:latest"}


docker model pull ${MODEL}  

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

osprey_chat_stream ${DMR_BASE_URL} "${DATA}" callback display_reasoning

echo ""
echo ""

#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.
COMMENT

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
MODEL=${MODEL_RUNNER_EMBEDDINGS_MODEL:-"ai/mxbai-embed-large"}

docker model pull ${MODEL}  

read -r -d '' DOCUMENT <<- EOM
Michael Burnham is the main character on the Star Trek series, Discovery.  
She's a human raised on the logical planet Vulcan by Spock's father.  
Burnham is intelligent and struggles to balance her human emotions with Vulcan logic.  
She's become a Starfleet captain known for her determination and problem-solving skills.
Originally played by actress Sonequa Martin-Green
EOM

read -r -d '' SENTENCE <<- EOM
Michael Burnham is the main character on the Star Trek series, Discovery.
EOM

read -r -d '' DATA <<- EOM
{
  "model":"${MODEL}",
  "encoding_format": "float",
  "input": "${DOCUMENT}"
}
EOM

embedding_1=$(osprey_create_embedding ${DMR_BASE_URL} "${DATA}")
#echo "${embedding_1}" 

read -r -d '' DATA <<- EOM
{
  "model":"${MODEL}",
  "encoding_format": "float",
  "input": "${SENTENCE}"
}
EOM

embedding_2=$(osprey_create_embedding ${DMR_BASE_URL} "${DATA}")
#echo "${embedding_2}" 

similarity=$(cosine_similarity "${embedding_1}" "${embedding_2}")
echo "Cosine similarity between the 2 vectors: $similarity"




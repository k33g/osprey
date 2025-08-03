#!/bin/bash
. "../../lib/osprey.sh"

: <<'COMMENT'
✋ if you are running this script in a Docker container, 
you need to export the MODEL_RUNNER_BASE_URL environment variable to point to the model runner service.
export MODEL_RUNNER_BASE_URL=http://model-runner.docker.internal/engines/llama.cpp/v1

✋ if you are working with devcontainer, it's already set.
COMMENT

DMR_BASE_URL=${MODEL_RUNNER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}
EMBEDDINGS_MODEL=${MODEL_RUNNER_EMBEDDINGS_MODEL:-"ai/mxbai-embed-large"}
#CHAT_MODEL=${MODEL_RUNNER_CHAT_MODEL:-"ai/qwen2.5:latest"}

docker model pull ${EMBEDDINGS_MODEL}  
#docker model pull ${CHAT_MODEL}  


read -r -d '' DOCS[001] <<- EOM
Michael Burnham is the main character on the Star Trek series, Discovery.  
She's a human raised on the logical planet Vulcan by Spock's father.  
Burnham is intelligent and struggles to balance her human emotions with Vulcan logic.  
She's become a Starfleet captain known for her determination and problem-solving skills.
Originally played by actress Sonequa Martin-Green
EOM

read -r -d '' DOCS[002] <<- EOM
James T. Kirk, also known as Captain Kirk, is a fictional character from the Star Trek franchise.  
He's the iconic captain of the starship USS Enterprise, 
boldly exploring the galaxy with his crew.  
Originally played by actor William Shatner, 
Kirk has appeared in TV series, movies, and other media.
EOM

read -r -d '' DOCS[003] <<- EOM
Jean-Luc Picard is a fictional character in the Star Trek franchise.
He's most famous for being the captain of the USS Enterprise-D,
a starship exploring the galaxy in the 24th century.
Picard is known for his diplomacy, intelligence, and strong moral compass.
He's been portrayed by actor Patrick Stewart.
EOM

read -r -d '' DOCS[004] <<- EOM
Lieutenant Philippe Charriere, known as the **Silent Sentinel** of the USS Discovery, 
is the enigmatic programming genius whose codes safeguard the ship's secrets and operations. 
His swift problem-solving skills are as legendary as the mysterious aura that surrounds him. 
Charrière, a man of few words, speaks the language of machines with unrivaled fluency, 
making him the crew's unsung guardian in the cosmos. His best friend is Spiderman from the Marvel Cinematic Universe.
EOM

function create_vector_record() {
read -r -d '' DATA <<- EOM
{
"prompt": "${1}",
"embedding": "${2}"
}
EOM
  echo "${DATA}"
}

# -------------------------------------
# Create a in memory vector store
# -------------------------------------
echo "📦 Creating a in memory vector store"
for key in "${!DOCS[@]}"; do

read -r -d '' DATA <<- EOM
{
  "model":"${EMBEDDINGS_MODEL}",
  "encoding_format": "float",
  "input": "${DOCS[$key]}"
}
EOM

  embedding=$(osprey_create_embedding ${DMR_BASE_URL} "${DATA}")

  VECTOR_STORE[$key]=$(create_vector_record "${DOCS[$key]}" "${embedding}")

  echo "- 📝 doc key: ${key} ok"
done

echo "📦 Vector store created with ${#VECTOR_STORE[@]} records"

# -------------------------------------
# Create embeddings for the user query
# -------------------------------------
read -r -d '' USER_QUESTIOM <<- EOM
Tell me something about Jean-Luc Picard.
EOM

read -r -d '' DATA <<- EOM
{
  "model":"${EMBEDDINGS_MODEL}",
  "encoding_format": "float",
  "input": "${USER_QUESTIOM}"
}
EOM

# -------------------------------------
# Similarity search
# -------------------------------------

embedding_from_question=$(osprey_create_embedding ${DMR_BASE_URL} "${DATA}")

echo "🔎 Find the best similarity in the docs..."
max_distance=-1.0
selected_doc_key=""
for key in "${!VECTOR_STORE[@]}"; do
  embedding_from_doc=$(echo ${VECTOR_STORE[$key]} | jq -r '.embedding' | jq -r 'tostring')
  
  similarity=$(cosine_similarity "${embedding_from_question}" "${embedding_from_doc}")
  
  echo "- 📐 similarity: ${similarity}"
  if (($(echo "$similarity > $max_distance" |bc -l) )); then
    max_distance=$similarity
    selected_doc_key=$key
  fi
done

echo "🔑 Selected doc key: ${selected_doc_key} with distance: ${max_distance}"
echo ""
echo "📝 Selected doc:"
echo "${DOCS[${selected_doc_key}]}"

echo ""
echo "📝 Prompt from the selected vector:"
prompt=$(echo ${VECTOR_STORE[$selected_doc_key]} | jq -r '.prompt')
echo "${prompt}"

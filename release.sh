#!/bin/bash
set -o allexport; source release.env; set +o allexport

echo "Generating release: ${TAG} ${ABOUT}"

find . -name '.DS_Store' -type f -delete


echo "📝 Replacing ${PREVIOUS_TAG} by ${TAG} in files..."

go run main.go -old="${PREVIOUS_TAG}" -new="${TAG}" -file="./examples/05-compose-agent/compose.yml"
go run main.go -old="${PREVIOUS_TAG}" -new="${TAG}" -file="./examples/07-compose-tool-calls/compose.yml"
go run main.go -old="${PREVIOUS_TAG}" -new="${TAG}" -file="./examples/12-compose-tools-with-mcp/compose.yml"
go run main.go -old="${PREVIOUS_TAG}" -new="${TAG}" -file="./examples/13-compose-agent-with-mcp/compose.yml"

go run main.go -old="${PREVIOUS_TAG}" -new="${TAG}" -file="./lib/osprey.sh"


git add .
git commit -m "📦 ${ABOUT}"
#git push
git push origin main


git tag -a ${TAG} -m "${ABOUT}"
git push origin ${TAG}


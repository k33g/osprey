#!/bin/bash
set -o allexport; source release.env; set +o allexport

echo "Generating release: ${TAG} ${ABOUT}"

find . -name '.DS_Store' -type f -delete

git add .
git commit -m "📦 ${ABOUT}"
#git push
git push origin main


git tag -a ${TAG} -m "${ABOUT}"
git push origin ${TAG}


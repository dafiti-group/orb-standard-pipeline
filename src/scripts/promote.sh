#!/bin/bash

cd ${PARAMETER_START_FOLDER} || exit 1
ORIGIN_FILE="<<parameters.origin>>/${CIRCLE_PROJECT_REPONAME}.yaml"
DESTINY_FILE="<<parameters.destiny>>/${CIRCLE_PROJECT_REPONAME}.yaml"
IMAGE=$(grep -E "tag\: \"[a-z0-9]+\"" ${ORIGIN_FILE})
sed -Ei "s|\s+tag: \"[a-z0-9]+\"|${IMAGE}|" ${DESTINY_FILE}
if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "promoting ${CIRCLE_PROJECT_REPONAME} image to <<parameters.target>>"
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

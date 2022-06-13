#!/bin/bash

cd ${PARAMETER_DEPLOYMENT_PATH} || exit 1
IMAGE="tag: \"${CIRCLE_SHA1:0:7}\""
if [ "${PARAMETER_ROLLBACK}" = true ]; then
  IMAGE='tag: "${PARAMETER_VERSION}"'
fi
CONFIG_FILE="${CIRCLE_PROJECT_REPONAME}.yaml"
sed -Ei "s|tag: \"[a-z0-9]+\"|${IMAGE}|" ${CONFIG_FILE}
if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} change image tag in: ${PARAMETER_DEPLOYMENT_PATH}/${CONFIG_FILE}"
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

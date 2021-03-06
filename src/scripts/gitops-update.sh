#!/bin/bash

cd ${PARAMETER_DEPLOYMENT_PATH} || exit 1
IMAGE="tag: \"${CIRCLE_SHA1:0:7}\""
if [ "${PARAMETER_ROLLBACK}" -eq "1" ]; then
  IMAGE="tag: \"${PARAMETER_VERSION}\""
fi
CONFIG_FILE="${CIRCLE_PROJECT_REPONAME}.yaml"
if [ ! -f "${CONFIG_FILE}" ]; then
  echo "file ${PARAMETER_DEPLOYMENT_PATH}/${CONFIG_FILE} not found!"
  exit 1
fi
sed -Ei "s|tag: \".*\"|${IMAGE}|" ${CONFIG_FILE}
if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} change image tag in: ${PARAMETER_DEPLOYMENT_PATH}/${CONFIG_FILE}"
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

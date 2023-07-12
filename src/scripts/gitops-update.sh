#!/bin/bash

LOCAL_DEPLOYMENT_PATH=$(eval echo "${PARAMETER_DEPLOYMENT_PATH:-$PARAMETER_COMPOSITE_PATH}")
if [[ ! -d "${LOCAL_DEPLOYMENT_PATH}" ]]; then
  echo "The path ${LOCAL_DEPLOYMENT_PATH} does not exists"
  exit 1
fi
cd ${LOCAL_DEPLOYMENT_PATH} || exit 1
IMAGE=${CIRCLE_SHA1:0:7}
if [ "${PARAMETER_ROLLBACK}" -eq "1" ]; then
  IMAGE=${PARAMETER_VERSION}
fi
CONFIG_FILE=$(eval echo "${PARAMETER_FILE_NAME}.yaml")
if [ ! -f "${CONFIG_FILE}" ]; then
  echo "file ${LOCAL_DEPLOYMENT_PATH}/${CONFIG_FILE} not found!"
  exit 1
fi

if [ "${PARAMETER_USE_YQ}" -eq "1" ]; then
  yq -i ".helmCharts[0].valuesInline.image.tag = \"${IMAGE}\"" $CONFIG_FILE
else
  IMAGE="tag: \"${IMAGE}\""
  sed -Ei "s|tag: \".*\"|${IMAGE}|" ${CONFIG_FILE}
fi


if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} change image tag in: ${LOCAL_DEPLOYMENT_PATH}/${CONFIG_FILE}"
  git push
else
  echo "Nothing to commit, deployment already done!"
fi

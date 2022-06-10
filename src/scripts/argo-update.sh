#!/bin/bash

cd ${PARAMETER_ARGO_PATH}
IMAGE="tag: \"$(echo ${CIRCLE_SHA1:0:7})\""
if [ "${PARAMETER_ROLLBACK}" = true ]; then
  IMAGE='tag: "${PARAMETER_VERSION}"'
fi
CONFIG_FILE=$(echo "${CIRCLE_PROJECT_REPONAME}.yaml")
sed -Ei "s|tag: \"[a-z0-9]+\"|${IMAGE}|" ${CONFIG_FILE}
if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "changing ${CIRCLE_PROJECT_REPONAME} image tag value for ${PARAMETER_TARGET_ENV}"
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

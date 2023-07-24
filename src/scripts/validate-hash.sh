#!/bin/bash

if [[ -z "${PARAMETER_VERSION}" ]]; then
  echo "Missing parameter PARAMETER_VERSION"
  exit 1
fi

echo "VALIDATING IF THE TAG:${PARAMETER_VERSION} EXISTIS IN AWS ECR"

LOCAL_IMAGE_TAGS=$(aws ecr list-images --repository-name "${CIRCLE_PROJECT_REPONAME}" | jq -r '.imageIds[].imageTag')
if echo $LOCAL_IMAGE_TAGS | grep -oq "${PARAMETER_VERSION}"; then
  echo "Registry found, OK-2-GO"
  exit 0
else
  echo "Registry not found. Available tags is:"
  echo ${LOCAL_IMAGE_TAGS}
  exit 1
fi

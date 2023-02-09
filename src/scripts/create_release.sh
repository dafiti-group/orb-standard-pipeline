#!/bin/bash

echo "Validating envs!"
if [[ -z "$LOCAL_SERVICE_NAME" ]]; then
  echo "Missing LOCAL_SERVICE_NAME environment used in pipeline-feedback/create_release command"
  exit 1
fi
if [[ -z "$LOCAL_RELEASE_SCOPE" ]]; then
  echo "Missing LOCAL_RELEASE_SCOPE environment used in pipeline-feedback/create_release command"
  exit 1
fi

INTERNAL_JSON_STRING_FULL=$(echo $LOCAL_RELEASE_SCOPE | jq -c | jq -R)
INTERNAL_INTERPOLATED_JSON=$(echo $INTERNAL_JSON_STRING_FULL | envsubst)

echo "${INTERNAL_INTERPOLATED_JSON}" >internal_scope.json
echo "Validation JSON"
if ! INTERNAL_OUTPUT=$(jq empty internal_scope.json 2>&1); then
  echo "Scope JSON is valid: ${INTERNAL_OUTPUT}"
  exit 1
fi

echo "Exporting context env to next steps"
# EXPORTING ENVS TO BE USED IN THE pipeline-feedback/create_release command ============================================
{
  echo "export INTERNAL_INTERPOLATED_JSON=${INTERNAL_INTERPOLATED_JSON}"
} >>"${BASH_ENV}"

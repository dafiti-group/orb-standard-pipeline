#!/bin/bash

if [[ -z "${GRAFANA_URL}" ]]; then
  echo "ENV GRAFANA_URL not present, please verify if the context GRAFANA is present"
fi
if [[ -z "${GRAFANA_TOKEN}" ]]; then
  echo "ENV GRAFANA_TOKEN not present, please verify if the context GRAFANA is present"
fi
if [[ -z "${PARAMETER_ENV}" ]]; then
  echo "ENV PARAMETER_ENV could not be empty"
fi
export TZ="America/Sao_Paulo"
LOCAL_GITHUB_URL="https://github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/commit/${CIRCLE_SHA1}"
TIMESTAMP=$(date +%s)
TIMENOW=$(date -R)
MESSAGE="{ \"what\": \"App:${CIRCLE_PROJECT_REPONAME}\", \"tags\": [ \"pipeline-notifications-${PARAMETER_ENV}\" ], \"when\": ${TIMESTAMP}, \"data\": \"Time: ${TIMENOW} Circleci link: ${CIRCLE_BUILD_URL} commit: ${LOCAL_GITHUB_URL}\" }"
GRAFANA_API="${GRAFANA_URL}/api/annotations/graphite"
AUTH_TOKEN="Authorization: Bearer ${GRAFANA_TOKEN}"
REQ_TYPE='Content-Type: application/json'
echo "validation message"
echo ""
echo $MESSAGE | jq
RESPONSE=$(curl --location --request POST "${GRAFANA_API}" -H "${AUTH_TOKEN}" -H "${REQ_TYPE}" --data "$MESSAGE")
RESPONSE_MESSAGE=$(echo ${RESPONSE} | jq -r '.message')
if [ "${RESPONSE_MESSAGE}" != "Graphite annotation added" ]; then
  echo "Request fail: ${RESPONSE}"
  exit 1
else
  echo "Notification added ${RESPONSE}"
fi

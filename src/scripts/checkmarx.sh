#!/bin/bash

# Validation encironments
if [[ -z "$CHECKMARX_URL" ]]; then
  echo "Missing CHECKMARX_URL environment"
  exit 1
fi
if [[ -z "$CHECKMARX_USERNAME" ]]; then
  echo "Missing CHECKMARX_USERNAME environment"
  exit 1
fi
if [[ -z "$CHECKMARX_PASSWORD" ]]; then
  echo "Missing CHECKMARX_PASSWORD environment"
  exit 1
fi
if [[ -z "$CHECKMARX_CLIENT_SECRET" ]]; then
  echo "Missing CHECKMARX_CLIENT_SECRET environment"
  exit 1
fi

# Regex to accept patterns in Checkmarx API
TEMP_BRANCH_NAME=$(echo ${CIRCLE_BRANCH} | sed 's|\/|-|g' | tr '[:upper:]' '[:lower:]')
PROJECT_BRANH_NAME="${CIRCLE_PROJECT_REPONAME}.${TEMP_BRANCH_NAME}"

# Checkmarx API - create_branch method
function create_branch() {

  RESULT=$(
    curl \
      --location \
      --request POST "${CHECKMARX_URL}/cxrestapi/projects/${PROJECT_ID}/branch" \
      --silent \
      --fail \
      --show-error \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer ${BEARE_TOKEN}" \
      --data-raw "{\"name\": \"${PROJECT_BRANH_NAME}\"}"
  )

  if [[ $(echo ${RESULT} | jq '.id') == null ]]; then
    echo "Branch could not be created: ${RESULT}"
    exit 1
  fi

}

# Checkmarx API - Auth method
RESULT=$(
  curl \
    --location \
    --request POST "${CHECKMARX_URL}/cxrestapi/auth/identity/connect/token" \
    --silent \
    --fail \
    --show-error \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "username=${CHECKMARX_USERNAME}" \
    --data-urlencode "password=${CHECKMARX_PASSWORD}" \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'scope=access_control_api sast_api' \
    --data-urlencode 'client_id=resource_owner_sast_client' \
    --data-urlencode "client_secret=${CHECKMARX_CLIENT_SECRET}"
)

BEARE_TOKEN=$(echo ${RESULT} | jq -r '.access_token')

if [[ "${BEARE_TOKEN}" == null ]]; then
  echo "Auth failed: ${RESULT}"
  exit 1
fi

# Checkmarx API - project_exists method
RESULT=$(curl \
  --location \
  --request GET "${CHECKMARX_URL}/cxrestapi/projects" \
  --silent \
  --fail \
  --show-error \
  --header "Authorization: Bearer ${BEARE_TOKEN}")

PROJECT=$(echo ${RESULT} | jq -r '.[] as $response | [$response.id,$response.name] | join(" ")' | grep -E "*${CIRCLE_PROJECT_REPONAME}$")
BRANCH=$(echo ${RESULT} | jq -r '.[] as $response | [$response.id,$response.name] | join(" ")' | grep -E "*${PROJECT_BRANH_NAME}$")

if [[ ${PROJECT} == '' ]]; then
  echo "Project not found: ${RESULT}"
  exit 1
else
  echo "Project Found ${PROJECT}"
fi

if [[ ${BRANCH} == '' ]]; then
  PROJECT_ID=$(echo ${PROJECT} | awk '{print$1}')
  create_branch
else
  echo "Branch already exists ${BRANCH}"
fi

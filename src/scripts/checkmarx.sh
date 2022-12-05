# set -x
# the cx-flow/executor does not have jq and curl, installing
apk add curl jq || exit 1

# Validating environments
echo "Validating envs!"
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

echo "Set up the initials envs of the context"
# Regex to accept patterns in Checkmarx API
TEMP_BRANCH_NAME=$(echo ${CIRCLE_BRANCH} | sed 's|\/|-|g' | tr '[:upper:]' '[:lower:]')
PROJECT_BRANCH_NAME="${CIRCLE_PROJECT_REPONAME}.${TEMP_BRANCH_NAME}"

# Checkmarx API - create_branch method
function create_branch() {

  CREATE_BRANCH_RESPONSE=$(
    curl \
      --location \
      --request POST "${CHECKMARX_URL}/cxrestapi/projects/${PROJECT_ID}/branch" \
      --silent \
      --fail \
      --show-error \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer ${BEARE_TOKEN}" \
      --data-raw "{\"name\": \"${PROJECT_BRANCH_NAME}\"}"
  )
  echo "Request create branch executed with success, validating response."
  if [[ $(echo ${CREATE_BRANCH_RESPONSE} | jq '.id') == null ]]; then
    echo "Branch could not be created: ${CREATE_BRANCH_RESPONSE}"
    exit 1
  fi
  echo "Branch created with success! ${CREATE_BRANCH_RESPONSE}"
}

echo "auth to get token..."
# Checkmarx API - Auth method
AUTH_RESPONSE=$(
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

BEARE_TOKEN=$(echo ${AUTH_RESPONSE} | jq -r '.access_token')

if [[ "${BEARE_TOKEN}" == null ]]; then
  echo "Auth failed: ${RESULT}"
  exit 1
fi
echo "Auth success, listing projects..."
# Checkmarx API - project_exists method
PROJECT_LIST_RESPONSE=$(curl \
  --location \
  --request GET "${CHECKMARX_URL}/cxrestapi/projects" \
  --silent \
  --fail \
  --show-error \
  --header "Authorization: Bearer ${BEARE_TOKEN}")
echo "Projects list request executed with success, searching for project and branch in the list...."
PROJECT_LIST=$(echo ${PROJECT_LIST_RESPONSE} | jq -r '.[] as $response | [$response.id,$response.name] | join(" ")')

if echo "${PROJECT_LIST}" | grep -Eq "^[0-9]+ ${CIRCLE_PROJECT_REPONAME}$"; then
  PROJECT=$(echo "${PROJECT_LIST}" | grep -Eo "^[0-9]+ ${CIRCLE_PROJECT_REPONAME}$")
  PROJECT_ID=$(echo ${PROJECT} | awk '{print$1}')
  echo "Project Found ${PROJECT}"
  echo "export PARAMETER_CHECKMARX_PROJECT_NAME=${PROJECT_BRANCH_NAME}" >>$BASH_ENV

  if echo "${PROJECT_LIST}" | grep -Eq "^[0-9]+ ${PROJECT_BRANCH_NAME}$"; then
    BRANCH=$(echo "${PROJECT_LIST}" | grep -Eo "^[0-9]+ ${PROJECT_BRANCH_NAME}$")
    echo "Bransh already exists: ${BRANCH}"
  else
    echo "Branch not found, trying to create one!"
    create_branch
  fi
else
  echo "Project not found: \n ${PROJECT_LIST}"
  echo "export PARAMETER_CHECKMARX_PROJECT_NAME=${CIRCLE_PROJECT_REPONAME}" >>$BASH_ENV
  exit 0
fi

echo "
=================================================
   ___         ___ _  __   _   ____
  / _ \ ___ _ / _/(_)/ /_ (_) / __/___  _  __
 / // // _ \`// _// // __// / / _/ / _ \| |/ /
/____/ \_,_//_/ /_/ \__//_/ /___//_//_/|___/
                               for monsters
=================================================
"
echo "Validating envs!"
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Missing GITHUB_TOKEN environment used in cxflow/scan command"
  exit 1
fi
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
if [[ -z "$CHECKMARX_PRESET" ]]; then
  echo "Missing CHECKMARX_PRESET environment used in cxflow/scan command"
  exit 1
fi
if [[ -z "$CHECKMARX_TEAM" ]]; then
  echo "Missing CHECKMARX_TEAM environment used in cxflow/scan command"
  exit 1
fi

echo "Set up the initials envs of the context"
# Sanitizing the branch name to be in compliance with checkmarx branch name roles
PARAMETER_BRANCH_NAME_SANITIZED=$(echo ${CIRCLE_BRANCH} | sed 's|\/|-|g' | sed 's|_|-|g' | tr '[:upper:]' '[:lower:]')
PARAMETER_PROJECT_BRANCH_NAME="${CIRCLE_PROJECT_REPONAME}.${PARAMETER_BRANCH_NAME_SANITIZED}"
# CREATING THE ENV TO HANDLE SYMBOLIC LINKS IN THE NEXT STEP
PARAMETER_ADITIONAL_CHECKMARX_ARGS=""
PARAM_THRESHOLDS_HIGH_CHECKMARX=""
PARAM_THRESHOLDS_MEDIUM_CHECKMARX=""

#Init local envs
PROJECT_LIST=""
PROJECT=""
PROJECT_ID=""
BRANCH=""

PARAMETER_SYMBOLIC_FILES=""
if [[ $(find . -type l) ]]; then
  PARAMETER_SYMBOLIC_FILES=$(find . -type l | cut -c 3- | paste -sd ",")
fi

# =================================================================================================

# Checkmarx API - Auth method
function auth_identity() {
  echo "Auth method to get the access token..."
  AUTH_RESPONSE=$(
    curl \
      --location \
      --request POST "${CHECKMARX_URL}/cxrestapi/auth/identity/connect/token" \
      --silent \
      --show-error \
      --header 'Content-Type: application/x-www-form-urlencoded' \
      --data-urlencode "username=${CHECKMARX_USERNAME}" \
      --data-urlencode "password=${CHECKMARX_PASSWORD}" \
      --data-urlencode 'grant_type=password' \
      --data-urlencode 'scope=access_control_api sast_api' \
      --data-urlencode 'client_id=resource_owner_sast_client' \
      --data-urlencode "client_secret=${CHECKMARX_CLIENT_SECRET}"
  )

  BEARER_TOKEN=$(echo ${AUTH_RESPONSE} | jq -r '.access_token')

  if [[ "${BEARER_TOKEN}" == null ]]; then
    echo "Auth failed: ${RESULT}"
    exit 1
  fi
  echo "Auth success!"
}

# Checkmarx API - create_branch method
function create_branch() {
  echo "Creating project branch: ${PARAMETER_PROJECT_BRANCH_NAME} for project ID: ${PROJECT_ID}"

  CREATE_BRANCH_RESPONSE=$(
    curl \
      --location \
      --request POST "${CHECKMARX_URL}/cxrestapi/projects/${PROJECT_ID}/branch" \
      --silent \
      --show-error \
      --header 'Content-Type: application/json' \
      --header "Authorization: Bearer ${BEARER_TOKEN}" \
      --data-raw "{\"name\": \"${PARAMETER_PROJECT_BRANCH_NAME}\"}"
  )
  echo "Request create branch executed with success, validating response."
  if [[ $(echo ${CREATE_BRANCH_RESPONSE} | jq '.id') == null ]]; then
    echo "Branch could not be created: ${CREATE_BRANCH_RESPONSE}"
    exit 1
  fi
  echo "Branch created with success! ${CREATE_BRANCH_RESPONSE}"
}
# Checkmarx API - delete_branch method
function delete_branch() {
  echo "deleting project ID: ${*}"
  DELETE_BRANCH_RESPONSE=$(
    curl \
      --location \
      --request DELETE "${CHECKMARX_URL}/cxrestapi/help/projects/${*}" \
      --silent \
      --show-error \
      --header 'Content-Type: application/json;v=1.0' \
      --header "Authorization: Bearer ${BEARER_TOKEN}" \
      --data-raw "{\"deleteRunningScans\": \"true\"}"
  )
  echo "Branch deleted with success! ${DELETE_BRANCH_RESPONSE}"
}
# Local helper function to compare branch list to be excluded from Checkmarx
function search_branchs_to_delete_in_checkmarx() {
  echo "Validating HEAD_BRANCH_NAME env!"
  if [[ -z "$HEAD_BRANCH_NAME" ]]; then
    echo "Missing HEAD_BRANCH_NAME environment"
    exit 1
  fi

  echo "Searching for branchs to delete in checkmarx"
  git config --global --add safe.directory "*"
  ALL_BRANCHS=$(git branch --list --remotes | sed -E 's|^\s+||g')
  BRANCH_LIST=$(echo "${ALL_BRANCHS}" | grep -v ${HEAD_BRANCH_NAME} | sed 's|origin\/||g' | sed 's|\/|-|g' | sed 's|_|-|g' | tr '[:upper:]' '[:lower:]')
  CHECKMARX_LOCAL_PROJECTS=$(echo "${PROJECT_LIST}" | grep -Eo "^[0-9]+ ${CIRCLE_PROJECT_REPONAME}\..*" | grep -v ${HEAD_BRANCH_NAME})
  if [[ -n "${BRANCH_LIST}" && -n "${CHECKMARX_LOCAL_PROJECTS}" ]]; then
    echo "
  =============================================
  github branch names sanitized:
  ${BRANCH_LIST}
  =============================================
  checkmarx projects
  ${CHECKMARX_LOCAL_PROJECTS}
  =============================================
  LOOPING TO FIND BRANCHS TO DELETE IN CHECKMARX....
  "
    echo "${CHECKMARX_LOCAL_PROJECTS}" | while read -r line; do
      TMP=$(echo $line | rev | cut -d\. -f1 | rev)
      ID=$(echo "$line" | awk '{print$1}')

      if [[ ! "${BRANCH_LIST[*]}" =~ ${TMP} ]]; then
        echo "Branch: ${TMP} not found. Deleting checkmarx project ID:${ID}"
        delete_branch $ID
      else
        echo "Branch ${TMP} present in the list, all clear!"
      fi
    done
  else
    echo "No branchs to validate, skiping..."
  fi

}
# Checkmarx API - project_exists method
function get_projects() {
  echo "Get project list ..."
  PROJECT_LIST_RESPONSE=$(
    curl \
      --location \
      --request GET "${CHECKMARX_URL}/cxrestapi/projects" \
      --silent \
      --show-error \
      --header "Authorization: Bearer ${BEARER_TOKEN}"
  )

  echo "Projects list request executed with success, Searching for project: ${CIRCLE_PROJECT_REPONAME}"
  echo "with Branch: ${PARAMETER_PROJECT_BRANCH_NAME}"

  PROJECT_LIST=$(echo ${PROJECT_LIST_RESPONSE} | jq -r '.[] as $response | [$response.id,$response.name] | join(" ")')

  if echo "${PROJECT_LIST}" | grep -Eq "^[0-9]+ ${CIRCLE_PROJECT_REPONAME}$"; then
    PROJECT=$(echo "${PROJECT_LIST}" | grep -Eo "^[0-9]+ ${CIRCLE_PROJECT_REPONAME}$")
    PROJECT_ID=$(echo ${PROJECT} | awk '{print$1}')
  fi
  if echo "${PROJECT_LIST}" | grep -Eq "^[0-9]+ ${PARAMETER_PROJECT_BRANCH_NAME}$"; then
    BRANCH=$(echo "${PROJECT_LIST}" | grep -Eo "^[0-9]+ ${PARAMETER_PROJECT_BRANCH_NAME}$")
    PROJECT_ID=$(echo ${BRANCH} | awk '{print$1}')
  fi
}

# Checkmarx API - project_exists method
function project_exists() {
  # Get project list
  get_projects

  echo "Project Type: " ${PROJECT_TYPE}
  echo "Initial THRESHOLDS_HIGH: ${PARAM_THRESHOLDS_HIGH_CHECKMARX}"
  echo "Initial THRESHOLDS_MEDIUM: ${PARAM_THRESHOLDS_MEDIUM_CHECKMARX}"
  echo "ARGS_PARAMETER_ADITIONAL: ${PARAMETER_ADITIONAL_CHECKMARX_ARGS}"
  echo "####################################"

  if [[ ${PROJECT} != "" ]]; then
    # Projeto Legado ou Novo + Existente
    echo "Project Found: ${PROJECT} . Verifing if branch: ${PARAMETER_BRANCH_NAME_SANITIZED} exists."
    if [[ ${PROJECT_TYPE} != "legacy" ]]; then
      echo "Project new, setting thresholds ..."
      set_thresholds
    fi

    if [[ ${BRANCH} == "" ]]; then
      echo "Branch not found, trying to create one!"
      create_branch
    else
      echo "Branch already exists: ${BRANCH}"
    fi
    if echo "${PROJECT_LIST}" | grep -Eq "^[0-9]+ ${CIRCLE_PROJECT_REPONAME}\..*$"; then
      search_branchs_to_delete_in_checkmarx
    fi
  else
    PARAMETER_PROJECT_BRANCH_NAME="${CIRCLE_PROJECT_REPONAME}"
    if [[ ${PROJECT_TYPE} != "legacy" ]]; then
      echo "Project new, setting thresholds ..."
      set_thresholds
    fi
    echo "Project not found, ready to execute next step. The project listed is: "
    echo "${PROJECT_LIST}"
  fi
}
# Checkmarx API - Get Last Scan ID
function get_last_scan_id() {
  echo "deleting last scan ID - Sleep 5s"
  sleep 5
  # Get project list
  get_projects
  echo "Get last scan ID for Project: ${PROJECT_ID}"
  LAST_SCAN_ID=""
  SCAN_LIST_RESPONSE=$(
    curl \
      --location \
      --request GET "${CHECKMARX_URL}/Cxwebinterface/odata/v1/Projects/${PROJECT_ID}" \
      --silent \
      --show-error \
      --header "Authorization: Bearer ${BEARER_TOKEN}"
  )
  echo "Request last scan ID executed with success, validating response."
  if [[ $(echo ${SCAN_LIST_RESPONSE} | jq '.value' | jq '.[0].LastScanId') == null ]]; then
    echo "Last scan ID not found: ${SCAN_LIST_RESPONSE}"
    exit 1
  fi
  LAST_SCAN_ID=$(echo ${SCAN_LIST_RESPONSE} | jq '.value' | jq '.[0].LastScanId')
  echo "Last scan ID identified! ${LAST_SCAN_ID}"

  echo "Calling delete last scan ID method!"
  delete_last_scan_id

}
# Checkmarx API - delete_last scan ID method
function delete_last_scan_id() {

  echo "deleting last scan ID project ID: ${PROJECT_ID}"
  DELETE_LAST_SCAN_ID_RESPONSE=$(
    curl \
      --location \
      --request DELETE "${CHECKMARX_URL}/cxrestapi/sast/scans/${LAST_SCAN_ID}" \
      --silent \
      --show-error \
      --header 'Content-Type: application/json;v=1.0' \
      --header "Authorization: Bearer ${BEARER_TOKEN}" \
      --data-raw "{\"deleteRunningScans\": \"true\"}"
  )
  echo "Last scan ID deleted with success! ${DELETE_LAST_SCAN_ID_RESPONSE}"
}

function set_thresholds() {

  echo "======================================================"
  echo "Set Thresholds"
  # Projeto Legado ou Novo + Existente
  PARAM_THRESHOLDS_HIGH_CHECKMARX="${CHECKMARX_THRESHOLDS_HIGH}"
  PARAM_THRESHOLDS_MEDIUM_CHECKMARX="${CHECKMARX_THRESHOLDS_MEDIUM}"
  echo "THRESHOLDS_HIGH: ${PARAM_THRESHOLDS_HIGH_CHECKMARX}"
  echo "THRESHOLDS_MEDIUM: ${PARAM_THRESHOLDS_MEDIUM_CHECKMARX}"
  echo "======================================================"

}

###### Main ######

# Call autentication function
auth_identity

# Function that execute
$PARAMETER_METHODE

echo "Exporting context env to next steps"
# EXPORTING ENVS TO BE USED IN THE cxflow/scan command ============================================
{
  echo "export PARAMETER_SYMBOLIC_FILES=${PARAMETER_SYMBOLIC_FILES}"
  echo "export PARAMETER_BRANCH_NAME_SANITIZED=${PARAMETER_BRANCH_NAME_SANITIZED}"
  echo "export PARAMETER_PROJECT_BRANCH_NAME=${PARAMETER_PROJECT_BRANCH_NAME}"
  echo "export PARAMETER_ADITIONAL_CHECKMARX_ARGS=${PARAMETER_ADITIONAL_CHECKMARX_ARGS}"
  echo "export THRESHOLDS_HIGH_CHECKMARX=${PARAM_THRESHOLDS_HIGH_CHECKMARX}"
  echo "export THRESHOLDS_MEDIUM_CHECKMARX=${PARAM_THRESHOLDS_MEDIUM_CHECKMARX}"

} >>"${BASH_ENV}"

echo "Finished with success!!!"

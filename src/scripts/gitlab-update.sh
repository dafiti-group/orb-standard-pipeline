LOCAL_FULL_PATH=$(eval echo "${PARAMETER_GITOPS}/${PARAMETER_DEPLOYMENT_FILE}")
LOCAL_PARAMETER_DEPLOYMENT_FILE=$(eval echo "${PARAMETER_DEPLOYMENT_FILE}")

echo "Full path: ${LOCAL_FULL_PATH}"

if [[ ! -d "${PARAMETER_GITOPS}" ]]; then
  echo "The path ${PARAMETER_GITOPS} does not exists"
  exit 1
fi

cd ${PARAMETER_GITOPS} || exit 1

if [[ ! -f "${LOCAL_PARAMETER_DEPLOYMENT_FILE}" ]]; then
  echo "The path ${LOCAL_FULL_PATH} does not exists"
  exit 1
fi

IMAGE=${CIRCLE_SHA1:0:7}
if [ "${PARAMETER_ROLLBACK}" -eq "1" ]; then
  if [ -z "${PARAMETER_VERSION}" ]; then
    echo "Parameter version PARAMETER_VERSION must be defined in Rollback."
    exit 1
  fi
  IMAGE=${PARAMETER_VERSION}
fi

if [ "${PARAMETER_USE_YQ}" -eq "1" ]; then
  echo "Using YQ and new tag is: ${IMAGE}"
  yq -i ".app.image.tag = \"${IMAGE}\"" ${LOCAL_PARAMETER_DEPLOYMENT_FILE}
else
  IMAGE="tag: \"${IMAGE}\""
  echo "Using SED and new tag is: ${IMAGE}"
  sed -Ei "s|tag: \".*\"|${IMAGE}|" ${LOCAL_PARAMETER_DEPLOYMENT_FILE}
fi

if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} change image tag in: ${LOCAL_PARAMETER_DEPLOYMENT_FILE}"
  git push
else
  echo "Nothing to commit, deployment already done!"
fi

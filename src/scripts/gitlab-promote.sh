#!/bin/bash
LOCAL_ORIGIN_FILE=$(eval echo "${PARAMETER_ORIGIN_FILE}")
LOCAL_DESTINY_FILE=$(eval echo "${PARAMETER_DESTINY_FILE}")

echo "Source path: ${PARAMETER_START_FOLDER}/${LOCAL_ORIGIN_FILE}"
echo "Destiny path: ${PARAMETER_START_FOLDER}/${LOCAL_DESTINY_FILE}"

if [[ ! -d "${PARAMETER_START_FOLDER}" ]]; then
  echo "The folder ${PARAMETER_START_FOLDER} does not exists"
  exit 1
fi

cd ${PARAMETER_START_FOLDER} || exit 1

if [[ ! -f "${LOCAL_ORIGIN_FILE}" ]]; then
  echo "The file ${LOCAL_ORIGIN_FILE} does not exists"
  exit 1
fi

if [[ ! -f "${LOCAL_DESTINY_FILE}" ]]; then
  echo "The file ${LOCAL_DESTINY_FILE} does not exists"
  exit 1
fi

if [ "${PARAMETER_USE_YQ}" -eq "1" ]; then
  TAG=$(yq '.app.image.tag' ${LOCAL_ORIGIN_FILE})
  echo "Using YQ and new tag is:${TAG}"
  yq -i ".app.image.tag = \"${TAG}\"" ${LOCAL_DESTINY_FILE}
else
  NEW_TAG=$(grep "tag: " ${LOCAL_ORIGIN_FILE} | awk '{print$2}')
  OLD_TAG=$(grep "tag: " ${LOCAL_DESTINY_FILE} | awk '{print$2}')
  echo "Using SED, NEW_TAG: ${NEW_TAG} OLD_TAG: ${OLD_TAG}"
  if [[ -z "$NEW_TAG" || -z "$OLD_TAG" ]]; then
    echo "Error geting tags from files"
  fi
  sed -i "s|${OLD_TAG}|${NEW_TAG}|" ${LOCAL_DESTINY_FILE}
fi

if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} promoting image from ${LOCAL_ORIGIN_FILE} to ${LOCAL_DESTINY_FILE}"
  git pull --rebase
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

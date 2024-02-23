#!/bin/bash

echo "Source path: ${PARAMETER_START_FOLDER}/${PARAMETER_ORIGIN_FILE}"
echo "Destiny path: ${PARAMETER_START_FOLDER}/${PARAMETER_DESTINY_FILE}"

if [[ ! -d "${PARAMETER_START_FOLDER}" ]]; then
  echo "The folder ${PARAMETER_START_FOLDER} does not exists"
  exit 1
fi

cd ${PARAMETER_START_FOLDER} || exit 1

if [[ ! -f "${PARAMETER_ORIGIN_FILE}" ]]; then
  echo "The file ${PARAMETER_ORIGIN_FILE} does not exists"
  exit 1
fi

if [[ ! -f "${PARAMETER_DESTINY_FILE}" ]]; then
  echo "The file ${PARAMETER_DESTINY_FILE} does not exists"
  exit 1
fi

if [ "${PARAMETER_USE_YQ}" -eq "1" ]; then
  TAG=$(yq '.app.image.tag' ${PARAMETER_ORIGIN_FILE})
  echo "Using YQ and new tag is:${TAG}"
  yq -i ".app.image.tag = \"${TAG}\"" ${PARAMETER_DESTINY_FILE}
else
  NEW_TAG=$(grep "tag: " ${PARAMETER_ORIGIN_FILE} | awk '{print$2}')
  OLD_TAG=$(grep "tag: " ${PARAMETER_DESTINY_FILE} | awk '{print$2}')
  echo "Using SED, NEW_TAG: ${NEW_TAG} OLD_TAG: ${OLD_TAG}"
  if [[ -z "$NEW_TAG" || -z "$OLD_TAG" ]]; then
    echo "Error geting tags from files"
  fi
  sed -i "s|${OLD_TAG}|${NEW_TAG}|" ${PARAMETER_DESTINY_FILE}
fi

if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} promoting image from ${PARAMETER_ORIGIN_FILE} to ${PARAMETER_DESTINY_FILE}"
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

#!/bin/bash

LOCAL_ORIGIN_PATH=$(eval echo "${PARAMETER_ORIGIN_PATH:-$PARAMETER_COMPOSITE_ORIGIN_PATH}")
LOCAL_DESTINY_PATH=$(eval echo "${PARAMETER_DESTINY_PATH:-$PARAMETER_COMPOSITE_DESTINY_PATH}")

if [[ ! -d "${LOCAL_ORIGIN_PATH}" ]]; then
  echo "The path ${LOCAL_ORIGIN_PATH} does not exists"
  exit 1
fi
if [[ ! -d "${LOCAL_DESTINY_PATH}" ]]; then
  echo "The path ${LOCAL_DESTINY_PATH} does not exists"
  exit 1
fi

ORIGIN_FILE=$(eval echo "${LOCAL_ORIGIN_PATH}/${PARAMETER_ORIGIN_FILE}.yaml")
if [ ! -f "${ORIGIN_FILE}" ]; then
  echo "file ${ORIGIN_FILE} not found"
  exit 1
fi
DESTINY_FILE=$(eval echo "${LOCAL_DESTINY_PATH}/${PARAMETER_DESTINY_FILE}.yaml")
if [ ! -f "${DESTINY_FILE}" ]; then
  echo "file ${DESTINY_FILE} not found"
  exit 1
fi

echo "
===================================
Origin: ${ORIGIN_FILE}
Destiny: ${DESTINY_FILE}
===================================
"

if [ "${PARAMETER_USE_YQ}" -eq "1" ]; then
  TAG=$(yq '.helmCharts[0].valuesInline.image.tag' ${ORIGIN_FILE})
  echo "Using YQ and new tag is:${TAG}"
  yq -i ".helmCharts[0].valuesInline.image.tag = \"${TAG}\"" ${DESTINY_FILE}
else
  NEW_TAG=$(grep "tag: " ${ORIGIN_FILE} | awk '{print$2}')
  OLD_TAG=$(grep "tag: " ${DESTINY_FILE} | awk '{print$2}')
  echo "Using SED, NEW_TAG: ${NEW_TAG} OLD_TAG: ${OLD_TAG}"
  if [[ -z "$NEW_TAG" || -z "$OLD_TAG" ]]; then
    echo "Error geting tags from files"
  fi
  sed -i "s|${OLD_TAG}|${NEW_TAG}|" ${DESTINY_FILE}
fi

cd ${PARAMETER_START_FOLDER} || exit 1
if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} promoting image from ${ORIGIN_FILE} to ${DESTINY_FILE}"
  git pull --rebase
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

#!/bin/bash

if [[ -z "$PARAMETERS_ORIGIN_PATH" ]]; then
  echo "Missing PARAMETERS_ORIGIN_PATH environment"
  exit 1
fi

if [[ -z "$PARAMETERS_DESTINY_PATH" ]]; then
  echo "Missing PARAMETERS_DESTINY_PATH environment"
  exit 1
fi

ORIGIN_FILE="${PARAMETERS_ORIGIN_PATH}/${PARAMETERS_ORIGIN_FILE:-$CIRCLE_PROJECT_REPONAME}.yaml"
if [ ! -f "${ORIGIN_FILE}" ]; then
  echo "file ${ORIGIN_FILE} not found"
  exit 1
fi
DESTINY_FILE="${PARAMETERS_DESTINY_PATH}/${PARAMETERS_DESTINY_FILE:-$CIRCLE_PROJECT_REPONAME}.yaml"
if [ ! -f "${DESTINY_FILE}" ]; then
  echo "file ${DESTINY_FILE} not found"
  exit 1
fi
IMAGE=$(grep -E "tag\: \"[a-z0-9]+\"" ${ORIGIN_FILE})
sed -Ei "s|\s+tag: \"[a-z0-9]+\"|${IMAGE}|" ${DESTINY_FILE}
cd ${PARAMETER_START_FOLDER} || exit 1
if [[ $(git diff) ]]; then
  git diff
  git add .
  git commit -m "${CIRCLE_PROJECT_REPONAME} promoting image from ${ORIGIN_FILE} to ${DESTINY_FILE}"
  git push
else
  echo "Nothing to commit, promotion already done!"
fi

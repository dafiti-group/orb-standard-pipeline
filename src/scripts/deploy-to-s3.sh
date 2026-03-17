#!/bin/bash

if [[ -z "${PARAMETER_FOLDER}" ]]; then
  echo "the parameter ${PARAMETER_FOLDER} could not be empty"
  exti 1
fi
if [[ -z "${PARAMETER_BUCKET}" ]]; then
  echo "the parameter ${PARAMETER_BUCKET} could not be empty"
  exti 1
fi

RESOLVED_ARGUMENTS=$(eval echo "${PARAMETER_ARGUMENTS}")
aws s3 sync ${PARAMETER_FOLDER} ${PARAMETER_BUCKET} ${RESOLVED_ARGUMENTS}

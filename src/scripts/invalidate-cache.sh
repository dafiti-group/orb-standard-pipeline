#!/bin/bash

if [[ -z "${PARAMETER_CLOUDFRONT_ID}" ]]; then
  echo "the parameter ${PARAMETER_CLOUDFRONT_ID} could not be empty"
  exti 1
fi
if [[ -z "${PARAMETER_CLOUDFRONT_PATH}" ]]; then
  echo "the parameter ${PARAMETER_CLOUDFRONT_PATH} could not be empty"
  exti 1
fi

aws cloudfront create-invalidation --distribution-id ${PARAMETER_CLOUDFRONT_ID} --paths "${PARAMETER_CLOUDFRONT_PATH}"

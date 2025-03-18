#!/bin/bash

INTERNAL_SAM_COMMAND="sam build"

if [ "${PARAMETER_USE_CONTAINER}" -eq "1" ]; then
  INTERNAL_SAM_COMMAND="sam build --use-container"
fi

if [[ -z "${PARAMETER_S3_BUCKET}" ]]; then
  echo "ENV PARAMETER_S3_BUCKET could not be empty!"
  exit 1
fi

export CGO_ENABLED=0

$INTERNAL_SAM_COMMAND

cd .aws-sam/build || exit 1

sam package \
  --template-file template.yaml \
  --output-template-file package.yaml \
  --s3-prefix ${CIRCLE_PROJECT_REPONAME} \
  --s3-bucket ${PARAMETER_S3_BUCKET} ${PARAMETER_EXTRA_PACKAGE_ARGS}

sam deploy \
  --template-file package.yaml \
  --stack-name ${CIRCLE_PROJECT_REPONAME} \
  --capabilities CAPABILITY_IAM  ${PARAMETER_EXTRA_DEPLOY_ARGS}

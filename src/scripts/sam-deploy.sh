#!/bin/bash

if [[ -z "${PARAMETER_S3_BUCKET}" ]]; then
  echo "ENV PARAMETER_S3_BUCKET could not be empty!"
  exit 1
fi

sam build --use-container

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

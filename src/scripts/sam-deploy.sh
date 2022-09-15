#!/bin/bash

if [[ -z "${SAM_DEPLOY_PARAMETER_S3}" ]]; then
  echo "ENV SAM_DEPLOY_PARAMETER_S3 could not be empty!"
  exit 1
fi

# sam build --use-container --build-image public.ecr.aws/sam/build-nodejs16.x:1.56.1-20220907224346
sam build

cd .aws-sam/build

sam package \
  --template-file template.yaml \
  --output-template-file package.yaml \
  --s3-prefix ${CIRCLE_PROJECT_REPONAME} \
  --s3-bucket ${SAM_DEPLOY_PARAMETER_S3}

sam deploy \
  --template-file package.yaml \
  --stack-name ${CIRCLE_PROJECT_REPONAME} \
  --capabilities CAPABILITY_IAM

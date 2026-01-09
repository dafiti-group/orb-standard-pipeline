#!/bin/bash

PARAMETER_APP_NAME=${PARAMETER_APP_NAME:-${CIRCLE_PROJECT_REPONAME}}

docker manifest create ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7} \
  ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7}-amd64 \
  ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7}-arm64

docker manifest create ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest \
  ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest-amd64 \
  ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest-arm64

# Anota as arquiteturas para ambas as tags
docker manifest annotate ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7} ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7}-amd64 --arch amd64
docker manifest annotate ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7} ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7}-arm64 --arch arm64

docker manifest annotate ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest-amd64 --arch amd64
docker manifest annotate ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest-arm64 --arch arm64

# Publica ambos os manifests
docker manifest push ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:${CIRCLE_SHA1:0:7}
docker manifest push ${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}:latest

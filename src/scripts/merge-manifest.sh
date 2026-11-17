#!/bin/bash
set -eo pipefail

echo "================================================"
echo "CIRCLE_PROJECT_REPONAME: ${CIRCLE_PROJECT_REPONAME}"
echo "PARAMETER_APP_NAME (raw): ${PARAMETER_APP_NAME}"
echo "================================================"

# Se PARAMETER_APP_NAME contém a string literal não resolvida, usa CIRCLE_PROJECT_REPONAME
if echo "${PARAMETER_APP_NAME}" | grep -q 'CIRCLE_PROJECT_REPONAME'; then
  PARAMETER_APP_NAME=${CIRCLE_PROJECT_REPONAME}
fi
PARAMETER_APP_NAME=${PARAMETER_APP_NAME:-${CIRCLE_PROJECT_REPONAME}}

echo "APP_NAME (resolved): ${PARAMETER_APP_NAME}"
echo "SHA_TAG: ${CIRCLE_SHA1:0:7}"
echo "ECR_URL: ${AWS_ECR_ACCOUNT_URL}"
echo "================================================"

IMAGE="${AWS_ECR_ACCOUNT_URL}/${PARAMETER_APP_NAME}"
SHA_TAG="${CIRCLE_SHA1:0:7}"

# Usa buildx imagetools em vez de "docker manifest": suporta imagens publicadas
# como OCI index (ex.: buildx com provenance/attestations habilitado), que o
# "docker manifest create" nao trata e gera o erro "manifest blob unknown" no ECR.
# A arquitetura de cada imagem e lida da propria imagem, sem precisar de annotate.
docker buildx imagetools create \
  --tag "${IMAGE}:${SHA_TAG}" \
  --tag "${IMAGE}:latest" \
  "${IMAGE}:${SHA_TAG}-amd64" \
  "${IMAGE}:${SHA_TAG}-arm64"

docker buildx imagetools inspect "${IMAGE}:${SHA_TAG}"

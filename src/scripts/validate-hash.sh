#!/bin/bash

if [[ -z "${PARAMETER_VERSION}" ]]; then
  echo "Missing parameter PARAMETER_VERSION"
  exit 1
fi
VALIDATE_VERSION=$(git rev-parse --verify ${PARAMETER_VERSION})
if [[ -z "${VALIDATE_VERSION}" ]]; then
  echo "Invalid hash version"
  exit 1
fi

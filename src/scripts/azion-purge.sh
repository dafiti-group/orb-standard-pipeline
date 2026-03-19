#!/bin/bash

if [ -z "${PARAMETER_ARGUMENTS}" ]; then
  echo "The parameter 'arguments' is required"
  exit 1
fi

if ! command -v azion &> /dev/null; then
  echo "Azion CLI not found, missing step '- install-azion-cli'"
  exit 1
fi

azion purge ${PARAMETER_ARGUMENTS} --yes

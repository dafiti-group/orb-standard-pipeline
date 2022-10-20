#!/bin/sh

BODY_MODIFIED=$(echo "${PARAMETER_TEMPLATE}" | jq '.' | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/`/\\`/g')
CUSTOM_BODY_MODIFIED=$(eval echo \""${BODY_MODIFIED}"\" )
echo $CUSTOM_BODY_MODIFIED
exit 1

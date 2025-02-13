#!/bin/bash

# setting base variables
SHA=${CIRCLE_SHA1}
CURRENT_BRANCH=${CIRCLE_BRANCH}
DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
RUNNER_TEMP=/tmp
export REVIEWDOG_GITHUB_API_TOKEN=${GITHUB_TOKEN}

echo "================================================"
echo "Validation Envs"
echo "SHA" $SHA
echo "CURRENT_BRANCH" $CURRENT_BRANCH
echo "DEFAULT_BRANCH" $DEFAULT_BRANCH
echo ""


echo "==========================================================="
echo "installing bearer scanner"

curl -sfL https://raw.githubusercontent.com/Bearer/bearer/main/contrib/install.sh | sh -s -- -b "$RUNNER_TEMP"
echo "==========================================================="
echo "installing reviewdoc cli"
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh| sh -s -- -b "$RUNNER_TEMP"
echo "==========================================================="

if [[ "${BEARER_SEVERITY}" != "" ]]; then
  echo "Severity level is set to ${BEARER_SEVERITY}"
  BEARER_PATH=". --severity=${BEARER_SEVERITY}"
fi

$RUNNER_TEMP/bearer scan $BEARER_PATH --diff --format=rdjson --output=rd.json || export BEARER_EXIT=$?

echo "::Bearer Exit Code::$BEARER_EXIT"

echo "==========================================================="
echo "sending report to PR"
cat rd.json | $RUNNER_TEMP/reviewdog -f=rdjson -reporter=github-pr-review
echo "==========================================================="

exit $BEARER_EXIT

#!/bin/bash

# setting base variables

SHA=${CIRCLE_SHA1}
export CI_COMMIT==${CIRCLE_SHA1}
export CI_REPO_OWNER=${CIRCLE_PROJECT_USERNAME}
export CI_REPO_NAME=${CIRCLE_PROJECT_REPONAME}
CURRENT_BRANCH=${CIRCLE_BRANCH}
DEFAULT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
RUNNER_TEMP=/tmp/bearer_scanner/
GITHUB_OUTPUT=/tmp/output.json
export REVIEWDOG_GITHUB_API_TOKEN=${GITHUB_TOKEN}
# export REVIEWDOG_TOKEN=${GITHUB_TOKEN}

touch $GITHUB_OUTPUT

echo "==========================================================="
echo "installing bearer scanner"
if [[ ! -z "$VERSION" ]]; then
  VERSION="v${VERSION#v}"
fi
curl -sfL https://raw.githubusercontent.com/Bearer/bearer/main/contrib/install.sh | sh -s -- -b "$RUNNER_TEMP" "$VERSION"
echo "==========================================================="
echo "installing reviewdoc cli"
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh| sh -s -- -b ~/go/bin
echo "==========================================================="

CI_PULL_REQUEST=""
if [ ! -z "${CIRCLE_PULL_REQUEST}" ]; then
  CI_PULL_REQUEST=$(echo "${CIRCLE_PULL_REQUEST}" | awk -F'/' '{print$NF}')
fi
export CI_PULL_REQUEST

RULE_BREACHES=$($RUNNER_TEMP/bearer scan ${BEARER_PATH})
SCAN_EXIT_CODE=${BEARER_EXIT_CODE}

echo "::debug::$RULE_BREACHES"

EOF=$(dd if=/dev/urandom bs=15 count=1 status=none | base64)

echo "rule_breaches<<$EOF" >>$GITHUB_OUTPUT
echo "$RULE_BREACHES" >>$GITHUB_OUTPUT
echo "$EOF" >>$GITHUB_OUTPUT

echo "exit_code=$SCAN_EXIT_CODE" >>$GITHUB_OUTPUT

echo "==========================================================="
echo "sending report to PR"
cat ${BEARER_OUTPUT} | reviewdog -f=rdjson -reporter=github-pr-review -level=debug
echo "==========================================================="

exit $SCAN_EXIT_CODE

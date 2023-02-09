#!/bin/bash

LOCAL_HEAD_GIT_BRANCH=$(git branch --list --remote | grep "origin/HEAD ->" | awk -F"/" '{print$3}')
LOCAL_PARSED_BOT_NAME=$(eval echo $LOCAL_DFT_BOT_NAME)
if [[ $(gh pr list -B ${LOCAL_HEAD_GIT_BRANCH}) ]]; then
  echo "PR open listed. Notify to update"
  gh pr list -B ${LOCAL_HEAD_GIT_BRANCH} | awk '{print$1}' | while read -r line; do
    read -r LOCAL_AUTHOR LOCAL_BRANCH_ORIGIN <<<"$(gh pr view $line --json 'headRefName,author' --jq '[.author.login,.headRefName] | join(" ")')"
    LOCAL_STRING="PR $line of author: ${LOCAL_AUTHOR} and origin: ${LOCAL_BRANCH_ORIGIN} target;${LOCAL_HEAD_GIT_BRANCH}"
    if [[ "${LOCAL_AUTHOR}" != "${LOCAL_PARSED_BOT_NAME}" ]]; then
      if [[ "${LOCAL_BRANCH_ORIGIN}" != "${CIRCLE_BRANCH}" ]]; then
        LOCAL_ACTION="blocked"
        gh pr review $line --request-changes --body ":robot: ${LOCAL_PARSED_BOT_NAME} blocked this PR because other pipeline changed the \`image.tag\` hash of this artifact in the test environment. \
          You need to re-run the pipeline in order to set the hash of your artifact in the test environment to continue with this PR."
      else
        LOCAL_ACTION="approved"
        gh pr review $line --approve --body ":robot: This PR is ready to merge! :rocket:"
      fi
    else
      LOCAL_ACTION="rejected"
      gh pr close $line
      git push -d origin ${LOCAL_BRANCH_ORIGIN}
    fi
    echo "${LOCAL_STRING} ${LOCAL_ACTION}"
  done
fi

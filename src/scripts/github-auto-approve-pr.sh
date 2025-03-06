#!/bin/bash

LOCAL_HEAD_GIT_BRANCH=$(git branch --list --remote | grep "origin/HEAD ->" | awk -F"/" '{print$3}')
LOCAL_PARSED_BOT_NAME=$(eval echo $LOCAL_DFT_BOT_NAME)
read -r LOCAL_PR_AUTHOR LOCAL_BRANCH_ORIGIN <<<"$(gh pr view --json 'headRefName,author' --jq '[.author.login,.headRefName] | join(" ")')"
LOCAL_STRING="PR of author: ${LOCAL_PR_AUTHOR} and origin: ${LOCAL_BRANCH_ORIGIN} target;${LOCAL_HEAD_GIT_BRANCH}"
if [[ "${LOCAL_PR_AUTHOR}" == "${LOCAL_PARSED_BOT_NAME}" ]]; then
  LOCAL_ACTION="approved"
  gh pr review --approve --body ":robot: This PR is ready to merge! :rocket:"
  echo "${LOCAL_STRING} ${LOCAL_ACTION}"

  echo "Closing PR"
  gh pr merge -s -d
fi

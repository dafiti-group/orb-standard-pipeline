#!/bin/bash
if [[ $(gh pr list) ]]; then
  echo "PR open listed. Notify to update"
  gh pr list | awk '{print$1}' | while read -r line; do
    if [ "$(gh pr view $line --json author --jq '.author.login')" != "dft-deploy" ]; then
      gh pr review $line --request-changes --body "The staging env was chaged! You need to re-run this pipeline to create a new deploy to staging"
    fi
  done
fi
if [[ $(gh pr list -H ${CIRCLE_BRANCH}) ]]; then
  echo "PR open listed. APPROVE"
  gh pr list -H ${CIRCLE_BRANCH} | awk '{print$1}' | while read -r line; do
    if [ "$(gh pr view $line --json author --jq '.author.login')" != "dft-deploy" ]; then
      gh pr review $line --approve --body "Thi PR is ready to merge!"
    else
      gh pr close $line
    fi
  done
else
  echo "Noting to do, No PR found, done!"
fi

#!/bin/bash

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "${CURRENT_BRANCH}" != "main" && "${CURRENT_BRANCH}" != "master" ]]; then
  echo "This command is not allowed to run in a current branch that is not main or master"
  exit 1
fi

echo ">>>> check pr list to request changes"
if [[ $(gh pr list) ]]; then
  echo "PR open listed. Notify to update"
  gh pr list | awk '{print$1}' | while read -r line; do
    if [ "$(gh pr view $line --json author --jq '.author.login')" != "dft-deploy" ]; then
      gh pr review $line --request-changes --body "The HEAD branch was updated!!! \
        I'll merge the updates into your branch, so make sure you test and/or resolve conflicts. \
        I'm requesting a review at this very moment, and I'll approve when this branch first deploy \
        into staging!"
    done
  done
else
  echo "Noting to do, No PR found, done!"
fi

echo ">>>> force updating branches"
if git branch -a | grep -Eq "origin\/(release|hotfix)"
then
  git branch -a | grep "origin" | grep -Eo "release.*|hotfix.*" | while read -r line; do
    echo ">>>CURRENT-LINE: ${line}"
    git checkout $line
    git merge -X theirs origin/main
    git push --force
  done
else
  echo "No release and hotfix to update!"
fi

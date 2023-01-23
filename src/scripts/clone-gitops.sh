#!/bin/bash

if [[ -z "$GITOPS_REPOSITORY" ]]; then
  echo "Missing GITOPS_REPOSITORY environment"
  exit 1
fi
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Missing GITHUB_TOKEN environment"
  exit 1
fi

git clone https://${GITHUB_TOKEN}@github.com/${CIRCLE_PROJECT_USERNAME}/${GITOPS_REPOSITORY}.git

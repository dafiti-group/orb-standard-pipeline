#!/bin/bash

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Missing GITHUB_TOKEN environment"
  exit 1
fi
if [[ -z "$GITHUB_USER_NAME" ]]; then
  echo "Missing GITHUB_USER_NAME environment"
  exit 1
fi
if [[ -z "$GITHUB_USER_EMAIL" ]]; then
  echo "Missing GITHUB_USER_EMAIL environment"
  exit 1
fi

git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
git config --global user.email "${GITHUB_USER_NAME}"
git config --global user.name "${GITHUB_USER_EMAIL}"

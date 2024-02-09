#!/bin/bash

if [[ -z "$NCHARTS_REPOSITORY" ]]; then
  echo "Missing NCHARTS_REPOSITORY environment"
  exit 1
fi
if [[ -z "$GITLAB_TOKEN" ]]; then
  echo "Missing GITLAB_TOKEN environment"
  exit 1
fi
if [[ -z "$GITLAB_GROUP" ]]; then
  echo "Missing GITLAB_GROUP environment"
  exit 1
fi

git clone https://${GITLAB_TOKEN}@gitlab.com/${GITLAB_GROUP}/${NCHARTS_REPOSITORY}.git

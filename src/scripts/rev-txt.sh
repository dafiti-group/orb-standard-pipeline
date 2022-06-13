#!/bin/bash

if [[ -z "$REV_TXT_FILE" ]]; then
  echo "Missing app_path parameter"
  exit 1
fi
git show -s --format="%ai %H %s %aN" HEAD >${REV_TXT_FILE}

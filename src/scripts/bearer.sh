#!/bin/bash

#Setup Variables
CURRENT_BRANCH=$CIRCLE_BRANCH
SHA=$CIRCLE_SHA1
REVIEWDOG_GITHUB_API_TOKEN=$GITHUB_TOKEN


#Install Bearer
curl -sfL https://raw.githubusercontent.com/Bearer/bearer/main/contrib/install.sh | sh -s -- -b /tmp
#Install Reviewdog
curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /tmp

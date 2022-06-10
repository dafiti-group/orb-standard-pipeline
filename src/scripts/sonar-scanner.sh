#!/bin/bash

sonar-scanner \
  -Dsonar.host.url=${SONAR_URL} \
  -Dsonar.login=${SONAR_TOKEN} \
  -Dsonar.projectBaseDir=${PWD} \
  -Dsonar.projectKey=${CIRCLE_PROJECT_REPONAME} \
  -Dsonar.projectName=${CIRCLE_PROJECT_REPONAME} \
  -Dsonar.scm.revision="$(echo ${CIRCLE_SHA1:0:7})" \
  -Dsonar.sourceEncoding=UTF-8

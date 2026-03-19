#!/bin/bash

if [ -z "${AZION_TOKEN}" ]; then
  echo "Azion Token not found in parameter"
  exit 1
fi

cd /tmp || exit 1
wget https://github.com/aziontech/azion/releases/download/4.18.0/azion_4.18.0_linux_amd64.zip
unzip azion_4.18.0_linux_amd64.zip
mv azion $HOME/bin
azion --token "${AZION_TOKEN}" --yes

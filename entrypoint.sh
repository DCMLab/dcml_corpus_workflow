#!/bin/bash

echo "Hello $1"
time=$(date)
echo "$HOME"
echo "::set-output name=time::$time"

pyv="$(python3 -V 2>&1)"
echo "$pyv"
ls "$GITHUB_WORKSPACE"
ls "${GITHUB_WORKSPACE}/main"
ls "${GITHUB_WORKSPACE}/main/MS3/"
pip install ms3
ms3 -h

ls "${HOME}"
cd "${GITHUB_WORKSPACE}/main"

if [ "$1" == "extract" ]; then
  ms3 extract -f "${GITHUB_WORKSPACE}/files_modified.json" -M -N -X -D
  ms3 extract -f "${GITHUB_WORKSPACE}/files_added.json" -M -N -X -D
elif [ "$1" == "check"  ]; then
  ms3 check -f "${GITHUB_WORKSPACE}/files_modified.json" --assertion
elif [  "$1" == "compare" ]; then
  ms3 compare -f "${GITHUB_WORKSPACE}/files_modified.json"
fi

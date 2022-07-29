#!/bin/bash

echo "Path being passed: $1"
echo "Executing: pip install ms3==0.4.11"
pip install ms3==0.4.11
echo "Executing: ms3 -h"
ms3 -h
echo "Executing: cd ${GITHUB_WORKSPACE}/main"
cd "${GITHUB_WORKSPACE}/main"

if [ "$1" == "extract" ]; then
  echo "Executing: ms3 extract -f ${GITHUB_WORKSPACE}/files_modified.json -M -N -X -D"
  ms3 extract -f "${GITHUB_WORKSPACE}/files_modified.json" -M -N -X -D
  echo "Executing: ms3 extract -f ${GITHUB_WORKSPACE}/files_added.json -M -N -X -D"
  ms3 extract -f "${GITHUB_WORKSPACE}/files_added.json" -M -N -X -D
elif [ "$1" == "check"  ]; then
  echo "Executing: ms3 check -f ${GITHUB_WORKSPACE}/files_modified.json --assertion"
  ms3 check -f "${GITHUB_WORKSPACE}/files_modified.json" --assertion
elif [  "$1" == "compare" ]; then
  echo "Executing: ms3 compare -f ${GITHUB_WORKSPACE}/files_modified.json"
  ms3 compare -f "${GITHUB_WORKSPACE}/files_modified.json"
fi

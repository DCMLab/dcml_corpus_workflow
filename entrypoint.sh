#!/bin/sh -l

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

ls "${HOME}
cd "${GITHUB_WORKSPACE}/main"
ms3 extract -f "${HOME}/files_modified.json" -M -N -X -D
ms3 extract -f "${HOME}/files_added.json" -M -N -X -D

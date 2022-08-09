#!/bin/bash
pushing_files() {
  echo "Pushing files"
  git add -A
  git commit -m "$1"
  # git push
}

configure_git(){
  echo "Configuring git"
  git config --global user.name "ms3-bot"
  git config --global user.email dcml.annotators@epfl.ch
  git config --global user.token $Token
}

git branch
echo "Argument being passed: $1"
# echo "Executing: pip install ms3==0.4.11"
# pip install ms3==0.4.11
echo "Executing: ms3 -h"
ms3 -h
echo "Executing: cd ${GITHUB_WORKSPACE}/main"
cd "${GITHUB_WORKSPACE}/main"
ls -a
configure_git
pushing_files
git diff --name-only $commitbefore $GITHUB_SHA


if [ "$1" == "extract" ]; then
  echo "Executing: ms3 extract -f ${GITHUB_WORKSPACE}/files_modified.json -M -N -X -D"
  ms3 extract -f "${GITHUB_WORKSPACE}/files_modified.json" -M -N -X -D
  echo "Executing: ms3 extract -f ${GITHUB_WORKSPACE}/files_added.json -M -N -X -D"
  ms3 extract -f "${GITHUB_WORKSPACE}/files_added.json" -M -N -X -D

  # git add -A
  # git commit -m "Automatically added TSV files from parse with ms3"
  # git push
  pushing_files "Automatically added TSV files from parse with ms3"
elif [ "$1" == "check"  ]; then
  echo "Executing: ms3 check -f ${GITHUB_WORKSPACE}/files_modified.json --assertion"
  ms3 check -f "${GITHUB_WORKSPACE}/files_modified.json" --assertion
elif [  "$1" == "compare" ]; then
  echo "Executing: ms3 compare -f ${GITHUB_WORKSPACE}/files_modified.json"
  ms3 compare -f "${GITHUB_WORKSPACE}/files_modified.json"

  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  pushing_files "Added comparison files for review"
fi

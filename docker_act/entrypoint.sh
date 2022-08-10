#!/bin/bash
pushing_files() {

  if [[ `git status --porcelain` ]]; then
    git add -A
    git commit -m "$1"
    echo "Pushing files"
    git push
  fi
}

configure_git(){
  echo "Configuring git"
  git config --global user.name "ms3-bot"
  git config --global user.email dcml.annotators@epfl.ch
  git config --global user.token $Token
}

get_difference_between_commits(){
    if [[ "$1" == "extract" ]] || [[ "$1" == "check" ]] ; then
      diffres=$(git diff --name-only $commitFrom $GITHUB_SHA)
      # diffres=$(git diff --name-status f0e3fa26fbafa9d38e57a78e4006f2f3be5b0a8e 395fd645d3aecd327876b8bd306b3bca63286540)
    elif [[ "$1" == "compare" ]]; then
      if [[ -z $commitFrom ]]; then
        diffres=$(git diff --name-status origin/$GITHUB_BASE_REF $commitTo)
      else
        diffres=$(git diff --name-status $commitFrom $commitTo)
      fi
    fi

    echo "[" > "${GITHUB_WORKSPACE}/files_modified.txt"

    while IFS= read -r line
    do
       splitLine=($line)
       if [[ "${splitLine[0]}" == "M" ]] || [[ "${splitLine[0]}" == "A" ]] ; then
         echo "\"${splitLine[1]}\"," >> "${GITHUB_WORKSPACE}/files_modified.txt"
       fi
    done < <(printf '%s\n' "$diffres")
    echo "]" >> "${GITHUB_WORKSPACE}/files_modified.txt"

    cat "${GITHUB_WORKSPACE}/files_modified.txt"

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
git log -n 10
echo $commitTo
echo $commitFrom
# if[[ ! $commitbefore ]]; then
#   git diff --name-only $commitbefore $commitForPull
# else
#   git diff --name-only origin/$GITHUB_BASE_REF $commitForPull
# fi
# git diff --name-only $commitbefore $commitForPull
# git diff --name-only $commitbefore $commitForPull

get_difference_between_commits $1

if [ "$1" == "extract" ]; then
  echo "Executing: ms3 extract -f ${GITHUB_WORKSPACE}/files_modified.txt -M -N -X -D"
  ms3 extract -f "${GITHUB_WORKSPACE}/files_modified.txt" -M -N -X -D
  # echo "Executing: ms3 extract -f ${GITHUB_WORKSPACE}/files_added.json -M -N -X -D"
  # ms3 extract -f "${GITHUB_WORKSPACE}/files_added.json" -M -N -X -D

  # git add -A
  # git commit -m "Automatically added TSV files from parse with ms3"
  # git push
  pushing_files "Automatically added TSV files from parse with ms3"
elif [ "$1" == "check"  ]; then
  echo "Executing: ms3 check -f ${GITHUB_WORKSPACE}/files_modified.txt --assertion"
  ms3 check -f "${GITHUB_WORKSPACE}/files_modified.txt" --assertion
elif [  "$1" == "compare" ]; then
  echo "Executing: ms3 compare -f ${GITHUB_WORKSPACE}/files_modified.txt"
  ms3 compare -f "${GITHUB_WORKSPACE}/files_modified.txt"
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  pushing_files "Added comparison files for review"
fi

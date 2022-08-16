#!/bin/bash
#######################################
# Push to current branch
# Arguments:
#    $1 custom commit
#######################################
pushing_files() {
  #check if there have been changes
  if [[ `git status --porcelain` ]]; then
    git add -A
    git commit -m "$1"
    echo "Pushing files"
    git push
  fi
}

#######################################
# Configuring git
# Globals:
#   Token: developer's token of the bot ms3-bot
# Arguments:
#   None
#######################################
configure_git(){
  echo "Configuring git"
  git config --global user.name "ms3-bot"
  git config --global user.email dcml.annotators@epfl.ch
  git config --global user.token $Token
}

#######################################
# Getting a list of files changed during PR or Push
# Globals:
#   GITHUB_SHA: the last commit that triggered the action , in the case
#               of pull_request, this is the last merge commit, for push
#               this is the last commit of the branch by default
#   GITHUB_BASE_REF: The base ref or targer branch of the pull request
#   GITHUB_WORKSPACE: default path for checkout action
# Arguments:
#   $1 to choose between PR or Push
# Outputs:
#  files_added_modified.json
#######################################
get_difference_between_commits(){
    if [[ "$1" == "extract" ]] || [[ "$1" == "check" ]] ; then
      diffres=$(git diff --name-status $commitFrom $GITHUB_SHA | grep -E '*.mscx')
      # diffres=$(git diff --name-status f0e3fa26fbafa9d38e57a78e4006f2f3be5b0a8e 395fd645d3aecd327876b8bd306b3bca63286540)
    elif [[ "$1" == "compare" ]]; then
      if [[ -z $commitFrom ]]; then
        diffres=$(git diff --name-status origin/$GITHUB_BASE_REF $commitTo | grep -E '*.mscx')
      else
        diffres=$(git diff --name-status $commitFrom $commitTo | grep -E '*.mscx')
      fi
    fi


    #finish the action execution if mscx files have been changed or added
    if [[ -z $diffres ]]; then
      echo "No mscx changes were detected, finishing early"
      # exit 0
    fi

    echo "[" > "${GITHUB_WORKSPACE}/files_added_modified.json"
    while IFS= read -r line
    do
       splitLine=($line)
       if [[ "${splitLine[0]}" == "M" ]] || [[ "${splitLine[0]}" == "A" ]] ; then
         echo "\"${splitLine[1]}\"," >> "${GITHUB_WORKSPACE}/files_added_modified.json"
       fi
    done < <(printf '%s\n' "$diffres")
    truncate -s-2 "${GITHUB_WORKSPACE}/files_added_modified.json"
    echo "" >> "${GITHUB_WORKSPACE}/files_added_modified.json"
    echo "]" >> "${GITHUB_WORKSPACE}/files_added_modified.json"

    cat "${GITHUB_WORKSPACE}/files_added_modified.json"

}


main(){
  echo "Argument being passed: $1"
  echo "Executing: cd ${GITHUB_WORKSPACE}/main"
  cd "${GITHUB_WORKSPACE}/main"
  configure_git
  pushing_files
  get_difference_between_commits $1
  if [ "$1" == "extract" ]; then

    #current version of ms3 in docker image does not work with this command
    # ms3 extract -d ./MS3 -M -N -X -D
    find ./MS3 -name '*.mscx' -print >> "allMS3files.json"
    echo "[" > "allMS3files.json"
    while IFS= read -r line
    do
      echo "\"${line}\"," >> "allMS3files.json"
    done < <(find ./MS3 -name '*.mscx' -print)
    truncate -s-2 "allMS3files.json"
    echo "" >> "allMS3files.json"
    echo "]" >> "allMS3files.json"
    cat allMS3files.json
    ms3 extract -f "allMS3files.json" -M -N -X -D
    pushing_files "Automatically added TSV files from parse with ms3"

  elif [ "$1" == "pull_request"  ]; then
    echo "pull request detected"
  elif [ "$1" == "push"  ]; then
    echo "push detected"
  elif [ "$1" == "check"  ]; then
    echo "Executing: ms3 check -f ${GITHUB_WORKSPACE}/files_added_modified.json --assertion"
    ms3 check -f "${GITHUB_WORKSPACE}/files_added_modified.json" --assertion
  elif [  "$1" == "compare" ]; then
    echo "Executing: ms3 compare -f ${GITHUB_WORKSPACE}/files_added_modified.json"
    ms3 compare -f "${GITHUB_WORKSPACE}/files_added_modified.json"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "Added comparison files for review"
  fi
}

main $1

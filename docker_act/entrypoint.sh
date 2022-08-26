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
# Set a variable called skipped with the value true and exit the script
# Arguments:
#   None
#######################################
configure_output_to_cancel_this_workflow(){
  echo "::set-output name=skipped::true"
  exit 0
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
#  added_and_modified_files.json
#######################################
get_difference_between_commits(){
    if [[ "$1" == "push" ]] ; then
      diffres=$(git diff --diff-filter=AM --name-status $commitFrom $GITHUB_SHA | grep -E '*.mscx')
    elif [[ "$1" == "pull_request" ]]; then
      diffres=$(git diff --diff-filter=AM --name-status origin/$GITHUB_BASE_REF $commitTo | grep -E '*.mscx')
    fi

    #finish the action execution if mscx files have not been changed or added
    if [[ -z $diffres ]]; then
      echo "No mscx changes were detected, finishing early"
      configure_output_to_cancel_this_workflow
    fi

    echo "[" > "${GITHUB_WORKSPACE}/added_and_modified_files.json"
    while IFS= read -r line
    do
       splitLine=($line)
       echo "\"${splitLine[1]}\"," >> "${GITHUB_WORKSPACE}/added_and_modified_files.json"
    done < <(printf '%s\n' "$diffres")

    truncate -s-2 "${GITHUB_WORKSPACE}/added_and_modified_files.json"
    echo "" >> "${GITHUB_WORKSPACE}/added_and_modified_files.json"
    echo "]" >> "${GITHUB_WORKSPACE}/added_and_modified_files.json"

    cat "${GITHUB_WORKSPACE}/added_and_modified_files.json"

}
#######################################
# Executing  ms3 extract, ms3 check and ms3 compare  to mscx files commited/added
# Globals:
#   GITHUB_WORKSPACE: default path for checkout action
# Arguments:
#   $1 allows to differentiate between push and pull_request
#######################################
executing_all_ms3_commands(){
  get_difference_between_commits $1


  echo "Executing: ms3 check -f ${GITHUB_WORKSPACE}/added_and_modified_files.json --assertion"
  if ! ms3 check -f "${GITHUB_WORKSPACE}/added_and_modified_files.json" --assertion; then
    exit -1
  fi
  echo "---------------------------------------------------------------------------------------"

  echo "Executing: ms3 extract -f ${GITHUB_WORKSPACE}/added_and_modified_files.json -M -N -X -D"
  if ! ms3 extract -f "${GITHUB_WORKSPACE}/added_and_modified_files.json" -M -N -D; then
    exit -1
  fi
  pushing_files "Automatically added TSV files from parse with ms3"

  echo "---------------------------------------------------------------------------------------"

  echo "Executing: ms3 compare -f ${GITHUB_WORKSPACE}/added_and_modified_files.json"
  if ! ms3 compare -f "${GITHUB_WORKSPACE}/added_and_modified_files.json"; then
    exit -1
  fi
  echo "---------------------------------------------------------------------------------------"
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  pushing_files "Added comparison files for review"

}

#######################################
# This function will check if at least one mscx file has been added or modified
# if not it will exit the script
# Globals:
#   GITHUB_WORKSPACE: default path for checkout action
#   GITHUB_SHA: the last commit that triggered the action
#               this is the last commit of the branch by default
# Arguments:
#   None
abort_if_not_modified_file(){
  diffres=$(git diff --diff-filter=AM --name-status $commitFrom $GITHUB_SHA | grep -E '*.mscx')
  echo "$diffres"
  if [[ -z $diffres ]]; then
    echo "No mscx changes were detected, finishing early"
    configure_output_to_cancel_this_workflow
  fi
}


set_up_venv(){

  if [[ "$1" != "new" ]] && [[ "$1" != "old" ]]; then
    echo "ms3 version argument is not correct, finishing early"
    configure_output_to_cancel_this_workflow
  fi
  export VIRTUAL_ENV="/opt/$1"
  python3 -m venv $VIRTUAL_ENV
  PATH="$VIRTUAL_ENV/bin:$PATH"
  echo "-------------------------------------"
  pip show ms3
  echo "-------------------------------------"
}
main(){
  echo "Argument being passed: $1 and $2"
  set_up_venv $2
  echo "Executing: cd ${GITHUB_WORKSPACE}/main"
  cd "${GITHUB_WORKSPACE}/main"
  configure_git
  if [[ "$comment_msg" == "trigger_whole_workflow" ]]; then

    #Placeholder for ms3_workflow
    echo "[" > "${GITHUB_WORKSPACE}/allMS3files.json"
    while IFS= read -r line
    do
      echo "\"${line:2}\"," >> "${GITHUB_WORKSPACE}/allMS3files.json"
    done < <(find ./MS3 -name '*.mscx' -print)
    truncate -s-2 "${GITHUB_WORKSPACE}/allMS3files.json"
    echo "" >> "${GITHUB_WORKSPACE}/allMS3files.json"
    echo "]" >> "${GITHUB_WORKSPACE}/allMS3files.json"



    echo "Executing: ms3 check -f allMS3files.json"
    if ! ms3 check -f "${GITHUB_WORKSPACE}/allMS3files.json"; then
      exit -1
    fi


    # ms3 workflow_run
    cat "${GITHUB_WORKSPACE}/allMS3files.json"
    ms3 extract -f "${GITHUB_WORKSPACE}/allMS3files.json" -M -N -X -D
    pushing_files "Automatically added TSV files from parse with ms3"



    echo "Executing: ms3 compare -f allMS3files.json"
    ms3 compare -f "${GITHUB_WORKSPACE}/allMS3files.json"

    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "Added comparison files for review"


  elif [[ "$1" == "push_to_main" ]]; then

    abort_if_not_modified_file
    #current version of ms3 in docker image does not work with this command
    # ms3 workflow_run
    # find ./MS3 -name '*.mscx' -print >> "${GITHUB_WORKSPACE}/allMS3files.json"
    echo "[" > "${GITHUB_WORKSPACE}/allMS3files.json"
    while IFS= read -r line
    do
      echo "\"${line:2}\"," >> "${GITHUB_WORKSPACE}/allMS3files.json"
    done < <(find ./MS3 -name '*.mscx' -print)
    truncate -s-2 "${GITHUB_WORKSPACE}/allMS3files.json"
    echo "" >> "${GITHUB_WORKSPACE}/allMS3files.json"
    echo "]" >> "${GITHUB_WORKSPACE}/allMS3files.json"

    # ms3 workflow_run
    cat "${GITHUB_WORKSPACE}/allMS3files.json"
    ms3 extract -f "${GITHUB_WORKSPACE}/allMS3files.json" -M -N -X -D
    pushing_files "Automatically added TSV files from parse with ms3"


    echo "Executing: ms3 check -f allMS3files.json"
    if ! ms3 check -f "${GITHUB_WORKSPACE}/allMS3files.json"; then
      exit -1
    fi

    echo "Executing: ms3 compare -f allMS3files.json"
    ms3 compare -f "${GITHUB_WORKSPACE}/allMS3files.json"

    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "Added comparison files for review"


  elif [[ "$1" == "pull_request" ]] && [[ "$IsThereAPullRequestOpened" == "OPEN" ]]; then
    executing_all_ms3_commands $1
  elif [[ "$1" == "push" ]] && [[ "$IsThereAPullRequestOpened" != "OPEN" ]]; then
    executing_all_ms3_commands $1
  elif [[ "$1" == "push" ]] && [[ "$IsThereAPullRequestOpened" == "OPEN" ]]; then
    echo "this workflow does not need to run because a pull_request is opened"
    configure_output_to_cancel_this_workflow
  fi

}

main $1

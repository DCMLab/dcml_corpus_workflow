#!/bin/bash
#######################################
# Push to current branch, assuming CWD is $directory
# Arguments:
#    $1 custom commit
#######################################
pushing_files() {
  #check if there have been changes
  if [[ `git status --porcelain` ]]; then
    #remove  added file
    if [[ -f "${directory}/${working_dir}/added_and_modified_files.txt" ]]; then
      rm -f "${directory}/${working_dir}/added_and_modified_files.txt"
    fi
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
#              of push event this is the last commit of the branch by default
#   RUNNER_WORKSPECE: parent folder of the cloned repo for temporary files
# Arguments:
#  None
# Outputs:
#  added_and_modified_files.txt
#######################################
get_difference_between_commits(){
    echo "Changing CWD to ${directory}/${working_dir}"
    cd "${directory}/${working_dir}"
    latestHashCommitInMain=$(git log -n 1 origin/main --pretty=format:"%H")
    diffres=$(git diff --diff-filter=AMR --name-status $latestHashCommitInMain $GITHUB_SHA | grep -E '*.mscx')

    #finish the action execution if mscx files have not been changed or added
    if [[ -z $diffres ]]; then
      echo "No mscx changes were detected, finishing early"
      configure_output_to_cancel_this_workflow
    fi

    while IFS= read -r line
    do
      splitLine=($line)
      # spliting lines by separator
      # https://stackoverflow.com/questions/46660224/split-string-using-ifs-example
      IFS='/' read -ra ADDR <<< "${splitLine[1]}"
      ARRAY=()
      for i in "${ADDR[@]}"; do
        ARRAY+=($(echo $i|sed -r 's#[.]+#\\.#g'|head -c-7))
      done
      echo "${ARRAY[-1]}|" >> "${directory}/${working_dir}/added_and_modified_files.txt"
    done < <(printf '%s\n' "$diffres")

    truncate -s-2 "${directory}/${working_dir}/added_and_modified_files.txt"
    echo "" >> "${directory}/${working_dir}/added_and_modified_files.txt"

    cat "${directory}/${working_dir}/added_and_modified_files.txt"

}
#######################################
# Executing  ms3 extract, ms3 check and ms3 compare  to mscx files commited/added
# Globals:
#   RUNNER_WORKSPECE: parent folder of the cloned repo for temporary files
# Arguments:
#   None
#######################################
push_to_no_main_branch(){
  echo "Changing CWD to ${directory}/${working_dir}"
  cd "${directory}/${working_dir}"
  get_difference_between_commits
  regexFiles=""
  while IFS= read -r line; do
    regexFiles=($regexFiles$line)
  done < ${directory}/${working_dir}/added_and_modified_files.txt
  echo "Push request another branch:"
  echo "Executing: ms3 review -c -M -N -X -D -F --fail -i $regexFiles"
  if ! ms3 review -c -M -N -X -D -F --fail -i $regexFiles; then
    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "[bot] ms3 review of modified scores (tests failed)"
    exit -1
  fi
  echo "---------------------------------------------------------------------------------------"
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  pushing_files "[bot] ms3 review of modified scores (tests passed)"
}

#######################################
# This function will check if at least one mscx file has been added or modified
# if not it will exit the script. Assumes CWD is $directory
# Globals:
#   GITHUB_SHA: the last commit that triggered the action
#               this is the last commit of the branch by default
# Arguments:
#   None
abort_if_not_modified_file(){
  diffres=$(git diff --diff-filter=AMR --name-status $commitFrom $GITHUB_SHA | grep -E '*.mscx')
  if [[ -z $diffres ]]; then
    echo "No mscx changes were detected, finishing early"
    configure_output_to_cancel_this_workflow
  fi
}

#######################################
# Modify python libraries to choose different version of ms3 installed in docker
# Arguments:
#   $1 allows the user to choose the most recent version of ms3 or and old version
#######################################
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

#######################################
# This function performs a full 'ms3 review' upon push to main.
#
# Globals:
#   directory: default path for checkout action
#   IsThereAPullRequestOpened:
#
# Arguments:
#   {push_to_main, pull_request, push}
#   ?
main(){
  #### ToDo: document arguments
  #### ToDo: make $2 be a version of ms3 and provide one Docker image with every new version
  # echo "Arguments being passed: $1 and $2"
  echo "Arguments being passed: $1, \ncomment: $comment_msg,\n working dir: ${working_dir}, \ncommitFrom: ${commitFrom},\ndirectory:  ${directory}"
  # set_up_venv $2

  git config --global --add safe.directory "${directory}/${working_dir}"
  echo "Changing CWD to ${directory}//${working_dir}"
  cd "${directory}/${working_dir}"
  configure_git
  if [[ "$comment_msg" == "dcml_corpus_workflow"* ]]; then
    echo "Executing: ms3 review -c -M -N -X -D -F --fail"
    if ! ms3 review -c -M -N -X -D -F --fail; then
      echo "---------------------------------------------------------------------------------------"
      git config --global user.name "github-actions[bot]"
      git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
      pushing_files "[bot] ms3 review of all scores (tests failed)"
      exit -1
    fi

    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "[bot] ms3 review of all scores (tests passed)"

  elif [[ "$1" == "push_to_main" ]]; then
    echo "Executing: ms3 review  -M -N -X -D -F --fail"
    if ! ms3 review -M -N -X -D -F --fail; then
      echo "---------------------------------------------------------------------------------------"
      git config --global user.name "github-actions[bot]"
      git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
      pushing_files "[bot] ms3 review of all scores (tests failed)"
      exit -1
    fi
    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "[bot] ms3 review of all scores (tests passed)"

  elif [[ "$1" == "push" ]]; then
    push_to_no_main_branch
  fi

}

main $1

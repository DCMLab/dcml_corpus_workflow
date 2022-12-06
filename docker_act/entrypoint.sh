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
#               of pull_request, this is the last merge commit, for push
#               this is the last commit of the branch by default
#   GITHUB_BASE_REF: The base ref or targer branch of the pull request
#   RUNNER_WORKSPECE: parent folder of the cloned repo for temporary files
# Arguments:
#   $1 to choose between PR or Push
# Outputs:
#  added_and_modified_files.txt
#######################################
get_difference_between_commits(){
    echo "Executing: cd ${directory}/${working_dir}"
    cd "${directory}/${working_dir}"
    if [[ "$1" == "push" ]] ; then

      latestHashCommitInMain=$(git log -n 1 origin/main --pretty=format:"%H")
      diffres=$(git diff --diff-filter=AM --name-status $latestHashCommitInMain $GITHUB_SHA | grep -E '*.mscx')
    elif [[ "$1" == "pull_request" ]]; then
      # diffres=$(git diff --diff-filter=AM --name-status origin/$GITHUB_BASE_REF $commitTo | grep -E '*.mscx')
      latestHashCommitInMain=$(git log -n 1 origin/main --pretty=format:"%H")
      echo $latestHashCommitInMain
      echo $commitTo
      diffres=$(git diff --diff-filter=AM --name-status $latestHashCommitInMain $commitTo | grep -E '*.mscx')
    fi

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
        ARRAY+=($(echo $i|sed -r 's#[.]+#\\.#g'))
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
#   $1 allows to differentiate between push and pull_request
#######################################
push_to_no_main_branch(){
  echo "Executing: cd ${directory}/${working_dir}"
  cd "${directory}/${working_dir}"
  get_difference_between_commits $1

  regexFiles=""
  while IFS= read -r line; do
    regexFiles=($regexFiles$line)
  done < ${directory}/${working_dir}/added_and_modified_files.txt
  echo "Push request another branch:"
  echo "Executing: ms3 review in with regex $regexFiles"
  if ! ms3 review -M -N -X -D -F -F --fail -i $regexFiles -c; then
    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "[bot] extracts facets and metadata from changed scores; adds review reports (tests failed)"
    exit -1
  fi
  echo "---------------------------------------------------------------------------------------"
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  pushing_files "[bot] extracts facets and metadata from changed scores; adds review reports (tests passed)"


}
#######################################
# Executing  ms3 review for all mscx files commited/added
# similar to executing all ms3_commands passing the flag commit
# Globals:
#   RUNNER_WORKSPECE: parent folder of the cloned repo for temporary files
# Arguments:
#   $1 allows to differentiate between push and pull_request
#######################################
pull_request_workflow(){
  echo "Executing: cd ${directory}/${working_dir}"
  cd "${directory}/${working_dir}"
  get_difference_between_commits $1
  regexFiles=""
  while IFS= read -r line; do
    regexFiles=($regexFiles$line)
  done < ${directory}/${working_dir}/added_and_modified_files.txt
  echo "Pull request:"
  echo "Executing: ms3 review in with regex $regexFiles"

  if ! ms3 review -M -N -X -D -F --fail -i $regexFiles -c; then
    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "[bot] extracts facets and metadata from changed scores; adds review reports (tests failed)"
    exit -1
  fi
  echo "---------------------------------------------------------------------------------------"
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  pushing_files "[bot] extracts facets and metadata from changed scores; adds review reports (tests passed)"


  # if [[ ! -f "${directory}/${working_dir}/startingCommitAtPR.txt" ]]
  # then
  #   if ! ms3 review -M -N -X -D -F --fail -i $regexFiles; then
  #     echo "---------------------------------------------------------------------------------------"
  #     git config --global user.name "github-actions[bot]"
  #     git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  #     pushing_files "Added comparison files for review"
  #     hashLastCommitStartingAtPR=$(git log HEAD^..HEAD --pretty=format:"%H" --no-patch)
  #     echo "$hashLastCommitStartingAtPR" > ${directory}/${working_dir}/startingCommitAtPR.txt
  #     git config --global user.name "github-actions[bot]"
  #     git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  #     pushing_files "Adding reference to first commit in PR"
  #     exit -1
  #   fi
  #   echo "---------------------------------------------------------------------------------------"
  #   git config --global user.name "github-actions[bot]"
  #   git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  #   pushing_files "Added comparison files for review"
  #
  #   hashLastCommitStartingAtPR=$(git log HEAD^..HEAD --pretty=format:"%H" --no-patch)
  #   echo "$hashLastCommitStartingAtPR" > ${directory}/${working_dir}/startingCommitAtPR.txt
  #   git config --global user.name "github-actions[bot]"
  #   git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  #   pushing_files "Adding reference to first commit in PR"
  #
  # else
  #   firstCommitInPR=$(cat "${directory}/${working_dir}/startingCommitAtPR.txt")
  #   echo "the fist commit is: $firstCommitInPR"
  #   if ! ms3 review -M -N -X -D -F --fail -i $regexFiles -c $firstCommitInPR; then
  #     echo "---------------------------------------------------------------------------------------"
  #     git config --global user.name "github-actions[bot]"
  #     git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  #     pushing_files "Added comparison files for review"
  #     exit -1
  #   fi
  #   echo "---------------------------------------------------------------------------------------"
  #   git config --global user.name "github-actions[bot]"
  #   git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
  #   pushing_files "Added comparison files for review"
  # fi

}

removeLastPRhash(){
  echo "Removing"
  if [[ -f "${directory}/${working_dir}/startingCommitAtPR.txt" ]]
  then
    rm -f "${directory}/${working_dir}/startingCommitAtPR.txt"
  fi
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
  diffres=$(git diff --diff-filter=AM --name-status $commitFrom $GITHUB_SHA | grep -E '*.mscx')
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
  echo "Arguments being passed: $1 and $comment_msg and working dir: ${working_dir}"
  # set_up_venv $2
  echo "Executing: cd ${directory}//${working_dir}"
  ls -a
  cd "${directory}/${working_dir}"
  ls -a
  configure_git
  if [[ "$comment_msg" == "trigger_workflow" ]]; then
    echo "Executing: ms3 review"
    if ! ms3 review -M -N -X -D -F --fail; then
      echo "---------------------------------------------------------------------------------------"
      git config --global user.name "github-actions[bot]"
      git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
      pushing_files "[bot] extracts facets and metadata from all scores; adds review reports (tests failed)"
      exit -1
    fi

    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "[bot] extracts facets and metadata from all scores; adds review reports (tests passed)"

  elif [[ "$1" == "push_to_main" ]]; then
    # removeLastPRhash
    # echo "check if files have been"
    # abort_if_not_modified_file
    echo "Executing: ms3 review"
    if ! ms3 review -M -N -X -D -F --fail; then
      echo "---------------------------------------------------------------------------------------"
      git config --global user.name "github-actions[bot]"
      git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
      pushing_files "[bot] extracts facets and metadata from all scores; adds review reports (tests failed)"
      exit -1
    fi
    echo "---------------------------------------------------------------------------------------"
    git config --global user.name "github-actions[bot]"
    git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
    pushing_files "[bot] extracts facets and metadata from all scores; adds review reports (tests passed)"

  elif [[ "$1" == "pull_request" ]] && [[ "$IsThereAPullRequestOpened" == "OPEN" ]]; then
    #statements to differentiate between either PR or pull request being triggered
    pull_request_workflow $1
  elif [[ "$1" == "push" ]] && [[ "$IsThereAPullRequestOpened" != "OPEN" ]]; then
    # removeLastPRhash
    push_to_no_main_branch $1
  elif [[ "$1" == "push" ]] && [[ "$IsThereAPullRequestOpened" == "OPEN" ]]; then
    echo "this workflow does not need to run because it comes together with a pull_request event"
    configure_output_to_cancel_this_workflow
  fi

}

main $1

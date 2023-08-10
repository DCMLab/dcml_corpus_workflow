#!/bin/bash
#######################################
# From current git directory
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
# Set name, email, and credentials for pusher
# Globals:
#   Token: developer's token of the bot ms3-bot
# Arguments:
#   None
#######################################
configure_git(){
  echo "Configuring git"
  git config --global user.name "ms3-bot"
  git config --global user.email dcml.annotators@epfl.ch
  git config --global credential.https://github.com.username marcelmmc
  echo -e "#!/bin/bash\necho \"\$Token\"" > /home/token.sh
  chmod +x /home/token.sh
  export GIT_ASKPASS=/home/token.sh
}

#######################################
# Set a variable called skipped with the value true and exit the script
# Arguments:
#   None
#######################################
configure_output_to_cancel_this_workflow(){
  echo "skipped=true" >> $GITHUB_OUTPUT
  exit 0
}


#######################################
# Getting a list of files modified and added during a Push event by comparing
# with another branch, files can be filter by including a regex as argument
# Globals:
#   GITHUB_SHA:  The last commit of the branch that triggered the action.
#   CUSTOM_GITHUB_SHA:  A hash commit that will overwrite GITHUB_SHA if specified.
# Arguments:
#  $1 The target branch to compare with.
#  $2 Regular expression to the list of files.
# Outputs:
#  /home/added_and_modified_files.txt
#######################################
get_difference_between_commits(){
    if [[ -z "$CUSTOM_GITHUB_SHA" ]]; then
      SHA="$GITHUB_SHA"
    else 
      SHA="$CUSTOM_GITHUB_SHA"
    fi
    latestHashCommitInMain=$(git log -n 1 "origin/$1" --pretty=format:"%H")
    recentAncestorCommitWithMain=$(git merge-base $latestHashCommitInMain "$SHA") 
    diffres=$(git diff --diff-filter=AMR --name-status $recentAncestorCommitWithMain "$SHA" | grep -G "$2")
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
      echo "${ARRAY[-1]}|" >> "/home/added_and_modified_files.txt"
    done < <(printf '%s\n' "$diffres")

    truncate -s-2 "/home/added_and_modified_files.txt"
    echo "" >> "/home/added_and_modified_files.txt"

    cat "/home/added_and_modified_files.txt"

}
#######################################
# Executing  ms3 commands for mscx files commited/added.
# Based on the INPUT_ variables execute a custom command or 
# a default command for non main branch push events
# Globals:
#   INPUT_MS3_COMMAND: the command that is passed to ms3,
#                      it includes (check|compare|extract|review|transform)
#   INPUT_ONLY_MODIFIED: it is a boolean, if it is true it determines the hehaviour 
#                        of filtering the /home/added_and_modified_files.txt
#                        or otherwise it uses the default filtering (.mscx)
#   INPUT_INCLUDE: Regular expression to filter /home/added_and_modified_files.txt
#   INPUT_PARAMETERS: Argument string appended to the ms3 command
# Arguments:
#   None
#######################################
on_non_main_branch_push(){
  if [[ "$INPUT_MS3_COMMAND" == "review" ]] &&\
     [[ "$INPUT_ONLY_MODIFIED" == "false" ]] &&\
     [[ -z "$INPUT_INCLUDE" ]] &&\
     [[ -z "$INPUT_PARAMETERS" ]]; then
    gen_regex_i_flag "default"
    echo "Push request another branch:"
    echo "Executing: ms3 review -c -M -N -X -D -F --fail -i \"$i_flag\""
    if ! ms3 review -c -M -N -X -D -F --fail -i "$i_flag"; then
      pushing_files "[bot] ms3 review of modified scores (tests failed)"
      exit -1
    fi
    pushing_files "[bot] ms3 review of modified scores (tests passed)"
  else
    gen_regex_i_flag 
    handle_custom_cmd
  fi
}

#######################################
# This function will check if at least one mscx file has been added or modified
# if not it will exit the script. 
# Globals:
#   GITHUB_SHA: the last commit that triggered the action
#               this is the last commit of the branch by default
# Arguments:
#   None
abort_if_not_modified_file(){
  previous_commit=$(jq -r '.before' "$GITHUB_EVENT_PATH")
  diffres=$(git diff --diff-filter=AMR --name-status $previous_commit $GITHUB_SHA | grep -G "$INPUT_FILE")
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
# Clone repository under /home directory
# by default the repository where this action
# is triggered will be cloned, otherwise set
# CUSTOM_GITHUB_REPOSITORY to clone a different repository.
# Globals:
#   CUSTOM_GITHUB_REPOSITORY: String of format <organisation>/<repository_name> 
#                             if defined, it will overwrite the GITHUB_REPOSITORY.
#   GITHUB_REPOSITORY: String of format <organisation>/<repository_name> 
#                      the default repository that will be cloned. 
#   GITHUB_REF_NAME: Branch name reference, in the case of the push event 
#                    this the branch that triggered the action.
#   CUSTOM_REF_NAME: Custom branch name reference, if defined it will
#                    overwrite the GITHUB_REF_NAME
# Arguments:
#   None
#######################################
clone_repo(){
  if [[ -z "${CUSTOM_GITHUB_REPOSITORY}" ]]; then
    REPOSITORY="${GITHUB_REPOSITORY}"
  else
    REPOSITORY="${CUSTOM_GITHUB_REPOSITORY}"
  fi

  if [[ -z "${CUSTOM_REF_NAME}" ]]; then
    BR_NAME="${GITHUB_REF_NAME}"
  else
    BR_NAME="${CUSTOM_REF_NAME}"
  fi


  echo "cloning repository: ${REPOSITORY}"
  git -C /home clone https://github.com/${REPOSITORY}.git "${REPOSITORY#*/}"
  echo "switching to branch name: $BR_NAME"
  if git -C "/home/${REPOSITORY#*/}" show-ref --quiet "refs/remotes/origin/${BR_NAME}"; then
    echo "branch exists"
    git -C "/home/${REPOSITORY#*/}" switch "$BR_NAME"
  else 
    echo "error: branch ${BR_NAME} for repo ${REPOSITORY} does not exist"
    exit 1
  fi
  git config --global --add safe.directory "home/${REPOSITORY#*/}"
}


#######################################
# Read file /home/added_and_modified_files.txt and
# concatenate lines with | character
# Arguments:
#   None
# Outputs:
#   regex: variable containing the files added or modified
#######################################
generate_regex(){
  local regex=""
  while IFS= read -r line; do
    regex="$regex$line"
  done < /home/added_and_modified_files.txt
  echo "$regex"
}


#######################################
# Validate INPUT_ variable, exit with error if:
#   - INPUT_MS3_PARAMETERS string contains 
#     either of these flags "-i ", "--include", "-d", "--dir"
#   - INPUT_MS3_COMMAND contains special characters
#   - INPUT_MODIFIED does not have the value "false" or "true" 
# Arguments:
#   None
#######################################

validate_input(){
  if [[ ! "$INPUT_MS3_COMMAND" =~ ^[[:alnum:]]+$ ]]; then
    echo "The input ms3_command should not contain special characters"
    exit -1
  elif [[ "$INPUT_PARAMETERS" == *"-d"* ]] || [[ "$INPUT_PARAMETERS" == *"--dir"* ]]; then
    echo "Please do not specify -d flag in the input parameters: ${INPUT_PARAMETERS}"
    exit 1
  elif [[ "$INPUT_PARAMETERS" == *"-i"* ]] || [[ "$INPUT_PARAMETERS" == *"--include"* ]]; then
    echo "Please do not specify -i or --include flags in the input parameters: ${INPUT_PARAMETERS}"
    exit 1
  elif [[ ! "$INPUT_ONLY_MODIFIED" == "true" ]] && [[ ! "$INPUT_ONLY_MODIFIED" == "false"* ]]; then
    echo "Please specify a boolean in the input only_modified: ${INPUT_ONLY_MODIFIED}"
    exit 1
  fi
}

#######################################
# Change the pusher's to be GitHub Actions bot
# Arguments:
#   None
#######################################
set_up_GITHUB_pusher(){
  echo "---------------------------------------------------------------------------------------"
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
}

#######################################
# Helper function to create a regular expression for the -i flag 
# Arguments:
#   $1 if defined with "default" it will get the different files
#      compare with main branch of the cloned repository 
#      and filter by regular expression ".*\.mscx"
#      ignoring the values of the INPUT_ variables
# Globals:
#   INPUT_ONLY_MODIFIED: if false, i flag obtains the explicit value of $INPUT_INCLUDE
#                        if true, i flag gets a regular expression based on the
#                        $INPUT_INCLUDE
#   INPUT_INCLUDE: Regular expression to either filter /home/added_and_modified_files.txt
#                  or be passed to the -i flag
#   i_flag: Generated regular expression to be added to the flag -i flag
#######################################
gen_regex_i_flag(){
  if [[ "$1" == "default" ]]; then
      get_difference_between_commits "main" ".*\.mscx"
      i_flag=$(generate_regex) 
  elif [[ "$INPUT_ONLY_MODIFIED" == "false" ]]; then
    i_flag="$INPUT_INCLUDE"
  else 
    if [[ -z "$INPUT_INCLUDE" ]]; then 
      get_difference_between_commits "main" ".*\.mscx"
    else 
      get_difference_between_commits "main" "$INPUT_INCLUDE"
    fi
    i_flag=$(generate_regex)    
  fi
}


#######################################
# Executing  ms3 command.
# Based on the INPUT_ variables execute a custom command or 
# a default command for main branch push events
# Globals:
#   INPUT_MS3_COMMAND: the command that is passed to ms3,
#                      it includes (check|compare|extract|review|transform)
#   INPUT_ONLY_MODIFIED: this variable does not affect ms3 command, but if it is
#                        specified as true, it will not execute the default command
#   INPUT_INCLUDE: Regular expression to be added in the -i flag 
#   INPUT_PARAMETERS: Argument string appended to the ms3 command
# Arguments:
#   None
#######################################
on_main_branch_push(){
    if [[ "$INPUT_MS3_COMMAND" == "review" ]] &&\
       [[ "$INPUT_ONLY_MODIFIED" == "false" ]] &&\
       [[ -z "$INPUT_INCLUDE" ]] &&\
       [[ -z "$INPUT_PARAMETERS" ]]; then
      echo "Executing: ms3 review -c -M -N -X -D -F --fail"
      if ! ms3 review -c -M -N -X -D -F --fail; then
        pushing_files "[bot] Warnings when running ms3 review on all scores (tests failed)"
        exit -1
      fi
      echo "All checks passed, nothing to push."
    else

      if [[ "$INPUT_INCLUDE" == ".*\.mscx" ]]; then 
        i_flag=".*"
      else 
        i_flag="$INPUT_INCLUDE"
      fi
      handle_custom_cmd
    fi
}


#######################################
# Executing  ms3 custom command
# Based on the $INPUT_PARAMETERS and $i_flag
# Globals:
#   INPUT_MS3_COMMAND: the command that is passed to ms3,
#                      it includes (check|compare|extract|review|transform)
#   $i_flag: Regular expression that will be passed to the -i flag
#   INPUT_PARAMETERS: Argument string appended to the ms3 command
# Arguments:
#   None
#######################################
handle_custom_cmd(){
  if [[ -z "$INPUT_PARAMETERS" ]] &&\
     [[ -n "$i_flag" ]]; then 
    echo "Executing: ms3 $INPUT_MS3_COMMAND -i \"$i_flag\""
    ms3 "$INPUT_MS3_COMMAND" -i "$i_flag"
  elif [[ -n "$INPUT_PARAMETERS" ]] &&\
       [[ -z "$i_flag" ]]; then
    create_paremeters_arr_from_one_line
    echo "Executing: ms3 $INPUT_MS3_COMMAND ${parameters_arr[@]}"
    ms3 "$INPUT_MS3_COMMAND" "${parameters_arr[@]}"
  elif [[ -z "$INPUT_PARAMETERS" ]] &&\
       [[ -z "$i_flag" ]]; then
    echo "Executing: ms3 $INPUT_MS3_COMMAND"
    ms3 "$INPUT_MS3_COMMAND"
  elif [[ -n "$INPUT_PARAMETERS" ]] && [[ -n "$i_flag" ]]; then
    create_paremeters_arr_from_one_line
    echo "Executing: ms3 $INPUT_MS3_COMMAND ${parameters_arr[@]} -i \"$i_flag\""
    ms3 "$INPUT_MS3_COMMAND" "${parameters_arr[@]}" -i "$i_flag"
  fi
  pushing_files "[bot] ms3 ; comand: $INPUT_MS3_COMMAND, parameters: $INPUT_PARAMETERS, include: $i_flag"
}


#TO-DO: Decide which method for including the input is better for
#       the action
#------------------------------------------------------------------
#this function can create parameters array if 
#parameters input in yml files is defined as
#parameter: |-
# -X
# -M
# path for M flag
create_paremeters_arr_from_block_lines(){
  IFS=$'\n' read -ra paremeters_arr <<< "$INPUT_PARAMETERS"
}
# this function can create parameters arrays, 
# if parameters input in yml files is defined as
# parameter: "-X<separator>-M<separator>path for M flag"
create_paremeters_arr_from_one_line(){
  sep="___"
  input_param_to_read="${INPUT_PARAMETERS//"$sep"/$'\n'}"  # Replace "___" with newlines
  IFS=$'\n' read  -d $'\0' -ra  parameters_arr <<< "$input_param_to_read"  # Split by newline
}
#------------------------------------------------------------------

main(){
  validate_input
  if [[ -f "$GITHUB_EVENT_PATH" ]]; then
    head_commit=$(jq -r '.head_commit.message' "$GITHUB_EVENT_PATH")
  fi

  if [[ -z "$CUSTOM_EVENT_TRIGGERED_BY_BRANCH" ]]; then
    EVENT_TRIGGERED_BY_BRANCH="${GITHUB_REF_NAME}"
  else 
    EVENT_TRIGGERED_BY_BRANCH="${CUSTOM_EVENT_TRIGGERED_BY_BRANCH}"
  fi

  configure_git
  clone_repo
  echo "Changing CWD to /home/${REPOSITORY#*/}"
  cd "/home/${REPOSITORY#*/}"
  set_up_GITHUB_pusher

  if [[ "$head_commit" == "dcml_corpus_workflow"* ]]; then
    echo "Executing: ms3 review -c -M -N -X -D -F --fail"
    if ! ms3 review -c -M -N -X -D -F --fail; then
      pushing_files "[bot] ms3 review of all scores (tests failed)"
      exit -1
    fi
    pushing_files "[bot] ms3 review of all scores (tests passed)"

  elif [[ "$GITHUB_EVENT_NAME" == "push" ]] && \
       [[ "$EVENT_TRIGGERED_BY_BRANCH" == "main" ]]; then
    on_main_branch_push
    
  elif [[ "$GITHUB_EVENT_NAME" == "push" ]] && \
       [[ "$EVENT_TRIGGERED_BY_BRANCH" != "main" ]]; then
    on_non_main_branch_push
  fi
}

main 
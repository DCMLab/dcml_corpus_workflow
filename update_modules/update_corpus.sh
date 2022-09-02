#!/bin/bash
# Ref https://stackoverflow.com/questions/72178053/copy-git-submodules-from-one-repo-to-another

cd "${GITHUB_WORKSPACE}/main"
ls -a
submodules=( $(git config -f "${GITHUB_WORKSPACE}/main/.gitmodules" --name-only --get-regexp 'submodule\..*\.path' | cut -f2 -d.) )
for name in "${submodules[@]}"; do
  path="$(git config -f .gitmodules --get submodule."$name".path)"
  echo "$path" >> ignorefiles.txt
done



for name in "${submodules[@]}"; do
    path="$(git config -f .gitmodules --get submodule."$name".path)"
    url="$(git config -f .gitmodules --get submodule."$name".url)"

    echo "$url"
    echo "$path"

    cd "${GITHUB_WORKSPACE}/main"
    linemodified=$(echo "${url/'git@github.com:'/'https://'"$token"'@github.com/'}")

    echo "$url"
    echo "$path"
    git submodule add "$linemodified" "$path"
    cd "${GITHUB_WORKSPACE}/main/$path"

    git branch
    git push origin --delete testing_branch
    git checkout -b testing_branch
    git push --set-upstream origin testing_branch
    ls -a
    rm -rf "${GITHUB_WORKSPACE}/main/$path/.github/workflows"
    cd "${GITHUB_WORKSPACE}/main"
    ls -a
    cd "${GITHUB_WORKSPACE}/main/$path"
    cp -r "${GITHUB_WORKSPACE}/main/update_modules/testing_workflow_helper/.github/" "${GITHUB_WORKSPACE}/main/$path/"
    git add .
    git commit -m "trigger_whole_workflow"
    git push

    sleep 5s
    gh run list --workflow localpr.yml -L 3 -b testing_branch > res.txt

    echo "garbage" > idrunner.txt
    while IFS= read -r line
    do
      if [[ $line == *"test extract"* ]]; then
        echo $line
        stringarray=($line)
        if [[ "${stringarray[-1]}" == *"0m" ]]; then
          echo "${stringarray[-3]}" > idrunner.txt
          break
        fi
      fi
    done < res.txt

    idrunner=$(cat "idrunner.txt")
    echo $idrunner
    runnerdone=$(gh run view $idrunner --json status)

    if [[ ! $idrunner == "garbage" ]]; then
      #statements
      while [[ ! "$runnerdone" == *"completed"* ]]
      do
        sleep 10s # avoid limit
                  # api rate 80 calls per minute
        runnerdone=$(gh run view $idrunner --json status)
      done

      gh run view "${stringarray[-3]}" --log > res.txt
      if ! git grep --all-match --no-index -q -e "Executing: ms3 check" "res.txt"; then
        echo "Error: localpr was called but workflow was not called"
        exit 1
      fi
    else
      echo "Error: localpr was not triggered"
      exit 1
    fi
    
    git pull
    gh pr create --title "PR to check for errors" --body "This pull request allows reviewers to check for errors before merging to main branch" -B main
    break
done

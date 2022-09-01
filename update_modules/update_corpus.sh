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

    sleep 80s # avoid encountering limit

    git pull

    gh pr create --title "PR to check for errors" --body "This pull request allows reviewers to check for errors before merging to main branch" -B main
    break
done

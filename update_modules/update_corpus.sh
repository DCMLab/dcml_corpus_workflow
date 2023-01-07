#!/bin/bash


#Global var
urlToYML="https://github.com/DCMLab/annotation_workflow_template"
spreedSheetRepos="https://docs.google.com/spreadsheets/d/16UsEfawgln7l9rgG7fTkh_LwO2bg2poLor3SxzXFU0Y/export?exportFormat=csv"
branch="workflow_update"
verTemp=$(curl https://api.github.com/repos/DCMLab/dcml_corpus_workflow/releases/latest -s | grep "tag_name"| cut -c16-| head)
latestVersionDCMLWorkflow=$(echo "${verTemp::-2}")

#Cloning annotation_workflow yml files
git clone $urlToYML
cd annotation_workflow_template
git checkout $branch
cd ..
mkdir "${GITHUB_WORKSPACE}/main/update_modules/yml_to_send"

#get the corpora sheet
cp -r "annotation_workflow_template/.github" "${GITHUB_WORKSPACE}/main/update_modules/yml_to_send"
curl -L $spreedSheetRepos -o res.csv
#google sheet contains a  corpora where echa entry contains:
#the name of a repo, link to the repo and dcml version for the repo
#[ -n "$name" ] is an extra boolean condition as file does not contain EOF and
#thus it would not read the last line of this
while IFS=, read -r path url ver || [ -n "$path" ]
do
    cd "${GITHUB_WORKSPACE}/main"
    echo "$path|$url|$ver"
    if [[ "$path" == "Repo name" ]]; then
      # skip the header row
      continue
    fi
    versionSel=$ver
    if [[ "$ver" == "latest" ]]; then
      versionSel=$latestVersionDCMLWorkflow
    fi
    sed -i "s#uses: DCMLab/dcml_corpus_workflow@..*#uses: DCMLab/dcml_corpus_workflow@$versionSel#" "${GITHUB_WORKSPACE}/main/update_modules/yml_to_send/.github/workflows/main_branch.yml"
    sed -i "s#uses: DCMLab/dcml_corpus_workflow@..*#uses: DCMLab/dcml_corpus_workflow@$versionSel#" "${GITHUB_WORKSPACE}/main/update_modules/yml_to_send/.github/workflows/annotation_branch.yml"

    linemodified=$(echo "${url/'git@github.com:'/'https://'"$token"'@github.com/'}")
    git submodule add "$linemodified" "$path"
    rm -rf "${GITHUB_WORKSPACE}/main/$path/.github/workflows"
    cp -r "${GITHUB_WORKSPACE}/main/update_modules/yml_to_send/.github/" "${GITHUB_WORKSPACE}/main/$path/"

    cd "${GITHUB_WORKSPACE}/main/$path"

    git push origin --delete workflow_update
    git checkout -b workflow_update
    git push --set-upstream origin workflow_update
    git add .
    git commit -m "trigger_workflow"
    git push
done < res.csv

#  annotation_workflow_template

This repo holds the current version of the DCML annotation workflow which is pulled by all subcorpus repos upon push to their main branch.

Please note that the `meta_ corpora` branch should be used with collections of corpora.

The dcml docker action aims to provide an plug-in artefact to execute ms3 commands in other workflows

## Requirements
* Create a personal access token and add it to the repo or organization as a secret
* Default branch of the repository should be named “main” (by default this should be the case)
* Checkout your repo with checkout@v2 and use a fetch-depth of 0
* This action will push files to the repository, therefore it’s necessary to avoid retriggering the yml where this action is used, to do this add an if statement to block commits from token’s username account or github-actions[bot]

## Table 1 (options for parameters)


Parameter          | Option          | Description          |
| ------------- | ------------- | ------------- |
| ms3-command| "push_to_main"|As long one mscx file has been modified in main branch, ms3 workflow_run will run on all mscx files under MS3|
| ms3-command| "pull_request"|As long environment variable IsThereAPullRequestOpened is “OPEN” , mscx files between the first and last commit of a pull request will run with ms3 workflow_run |
| ms3-command| "push"|As long environment variable IsThereAPullRequestOpened is not “OPEN” and push comes from non-main branch,  all mscx files between last and recent commit of the push will be passed to ms3 workflow_run.|
| ms3-version| "old"|Docker will run ms3 version 0.4.11|
| ms3-version| "new"|Docker will run ms3 version 0.5.3|


## Usage
```yml
- name: Action_to_run_docker
  uses: DCMLab/dcml_corpus_workflow@[current_release] # Uses an action in the root directory
  id: act_docker
  with:
    # Command that will execute a list of ms3 commands, check table 1 in marketplace to see available commands
    ms3-command: ""

    # Allows to select between two version of ms3, check table 1 in marketplace to see available commands
    ms3-version: ""

  env:
    # Environment variable to configure git and allow files to be pushed
    Token: ""

    # Environment variable to allow either a PR or push coming from a no main branch get executed
    # Only necessary if user would like to have just one yml file to consider both trigger events
    IsThereAPullRequestOpened: ""

    # Environment variable that marks the starting commit to detect changes
    commitFrom: ""

    # Environment variable that marks the ending commit to detect changes
    commitTo: ""

    # Environment variable to store msg of commit
    # Only necessary if user would like to trigger workflow from a push
    # without the modification of any mscx files
    comment_msg: ""

    # Environment variable to store title of pr_title
    # Only necessary if user would like to trigger workflow from a PR
    # without the modification of any mscx files
    pr_title: ""

```

Usage of the published action can be seen in [local.yml](https://github.com/DCMLab/dcml_corpus_workflow/blob/main/update_modules/testing_workflow_helper/.github/workflows/localpr.yml) and [localpushmain](https://github.com/DCMLab/dcml_corpus_workflow/blob/main/update_modules/testing_workflow_helper/.github/workflows/localpushmain.yml)

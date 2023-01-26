#  annotation_workflow_template

The dcml docker action aims to provide an plug-in artefact to execute ms3 commands in other workflows

## Requirements
* Create a personal access token and add it to the repo or organization as a secret
* Default branch of the repository should be named “main” (by default this should be the case)
* Checkout your repo with checkout@v2 and use a fetch-depth of 0
* This action will push files to the repository, therefore it’s necessary to avoid retriggering the yml where this action is used, to do this add an if statement to block commits from token’s username account and github-actions[bot]

## Table 1 (options for parameters)


Parameter          | Option          | Description          |
| ------------- | ------------- | ------------- |
| ms3-command| "push_to_main"|ms3 workflow_run will run on all mscx files under MS3|
| ms3-command| "push"|When a push comes from a non-main branch,  all mscx files between last and recent commit of the push will be passed to ms3 workflow_run.|


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

    # Environment variable that marks the starting commit to detect changes
    commitFrom: "${{ github.event.before }}"

    # Environment variable to store msg of commit
    # Only necessary if user would like to trigger workflow with commit
    comment_msg: "${{ github.event.head_commit.message }}"

    # Environment variable to location of workspace
    directory: "${{ github.workspace }}"

    # Environment variable of repository event
    working_dir: "${{ github.event.repository.name }}"

```


Usage of the published action can be seen in [annotation_branch.ymll](https://github.com/DCMLab/annotation_workflow_template/blob/main/.github/workflows/annotation_branch.yml) and [main_branch.yml](https://github.com/DCMLab/annotation_workflow_template/blob/main/.github/workflows/main_branch.yml)

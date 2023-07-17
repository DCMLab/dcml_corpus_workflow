#  DCML docker action

The dcml docker action aims to provide a plug-in environment to execute ms3 commands for corpus repositories, and it is used with the workflows in [DCMLab/annotation_workflow_template](https://github.com/DCMLab/annotation_workflow_template). Based on the inputs and environment variable, the docker action will:
* Execute ```ms3 review -c -M -N -X -D -F --fail``` when pushing a commit that starts with dcml_corpus_workflow.
* Execute ```ms3 review --fail``` when pushing to a main branch.
* Execute ```! ms3 review -c -M -N -X -D -F --fail -i mscx_files``` when pushing to a non main branch.
* When executing ```ms3 review```, an extra push will assert a pass or fail in its commit message.
* Execute ```jupyter nbconvert``` to generate pages when pushing a commit that starts with update_website. 
* Execute custom ```ms3 commands``` by specifying inputs in action.

## How to integrate the docker action in a workflow
* Check the default branch of the repository is ```main``` (by default this should be the case).
* Create a workflow and add the action as specified in the [How to use section](#how-to-use).
* This action pushes files to the repository, so it is necessary to prevent retriggering the YAML where this action is used. To achieve this, add an [if statement](https://github.com/DCMLab/annotation_workflow_template/blob/main/.github/workflows/annotation_branch.yml#L11C1-L12) to block commits from the token's username account and github-actions[bot].
* Depending on user's needs, arguments will need to be passed as inputs or environment variables in the docker action defined in the [parameters table](#parameter-table).
* (Optional) The docker action can exit early by checking if any modifications have been made to the mscx files, this information is stored in the 'skipped' output of the step that runs the action. The user can utilize this information in another step, such as [canceling the workflow where the action was executed](https://github.com/DCMLab/annotation_workflow_template/blob/workflow_update/.github/workflows/annotation_branch.yml#L35-L41C52).

Please refer to [annotation_branch.yml](https://github.com/DCMLab/annotation_workflow_template/blob/main/.github/workflows/annotation_branch.yml) for the integration of the docker action on non-main branches, and [main_branch.yml](https://github.com/DCMLab/annotation_workflow_template/blob/main/.github/workflows/main_branch.yml) for the integration on the main branch.

## Parameter table


Parameter          | Description          | Type |
| ------------- | ------------- |---|
| ms3-command| - When the command is defined as "push_to_main", the ```ms3 review``` will be executed on all mscx files under MS3.<br>- When the command is defined as "push", the mscx files between the last commit in the current branch and the common ancestor commit, compared with the main branch, will be passed to the ```-i``` flag when executing ```ms3 review```. <br> - When the command is defined with any of the keywords "check, compare, extract, review, transform", the Docker action will execute the ```ms3 ``` command followed by the specified keyword.|Input|
| Token|Environment variable to push results of docker action to repository.|Environment variable|
| commitFrom|The last commit from the branch that triggered the workflow. To obtain this value, please use: <br>```"${{ github.event.before }}" ```|Environment variable|
| comment_msg|The last commit message from the branch that triggered the workflow. To obtain this value, please use: <br>```"${{ github.event.head_commit.message }}"```|Environment variable|
| directory|The location where the git corpus repository is located. By convention, cloned repositories should be located under this location:<br> ```"${{ github.workspace }}"```|Environment variable|
| working_dir|Name of git repository where corpus should be found, depending on the cloning process this name can vary. By convention it should be:<br>```"${{ github.event.repository.name }}"```|Environment variable|
| skipped|A variable that will return true if the docker action has exited early , or false if the docker has executed any of the actions defined in [DCML docker action](#dcml-docker-action).|Output|


## How to use
```yml
- name: Action_to_run_docker
  uses: DCMLab/dcml_corpus_workflow@[current_release] # Uses an action in the root directory
  id: act_docker
  with:
    # Command that will execute a list of ms3 commands, check table 1 in marketplace to see available commands
    ms3-command: ""

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

# How to contribute
To contribute to this project, please create a new branch based on the default branch (main) and open a Pull Request detailing the modifications. Currently, there are no well-defined tests due to the nature of the action that clones and pushes files to a corpus repository. As a result, The recommendation is to create a workflow on an isolated branch and call the action.yml file from this workflow to test it remotely.

The project is using [conventional commits](https://www.conventionalcommits.org/en/v1.0.0-beta.2/), and thus maintainers should align with these conventions when committing changes.


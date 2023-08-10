## How to run action locally
1. Open a console/terminal, clone this repository and move to dcml_corpus_workflow/
2. Install [nektos/act] (https://github.com/nektos/act) 
3. Install and start docker desktop according to your machine. [Windows](https://docs.docker.com/desktop/install/windows-install/), [Linux](https://docs.docker.com/desktop/install/linux-install/), [Mac](https://docs.docker.com/desktop/install/mac-install/)
5. Set up MS3_BOT_TOKEN in [secrets.env](env/secrets.env) with a Personal Access Token that has 'repo' scope and access to [DCMLab/ravel_piano](https://github.com/DCMLab/ravel_piano)
6. In a console/terminal pointing to dcml_corpus_workflow/ run: `act push -j docker_action -e .\run_locally\events\<event>.json --env-file .\run_locally\env\GITHUB.env --secret-file .\run_locally\env\secrets.env.`
6. If necessary, define environment variables in [test_act.yml](../.github/workflows/test_act.yml) under the 'test action' step. Use CUSTOM_REF_NAME to control the branch that will be checked out in DCMLab/ravel_piano, and use CUSTOM_EVENT_TRIGGERED_BY_BRANCH to specify the branch from which the action was triggered.
7. (Optional) At the root of this repository, a metadata file will be found ([action.yml](../action.yml)). Please specify the container image using the Dockerfile located under src to build an image with latest modification in entrypoint.sh. Once the action's result is expected, generate, push and use an image using the steps defined in [CREATING_DOCKER_IMAGE.md](../src/CREATING_DOCKER_IMAGE.md) by updating action.yml with the image's link in docker hub.

Notice: nektos/act allows the injection of payload events, environment variables, and secrets. When running this action locally and targeting a different repository, please update the .env, .json and test_act.yml files accordingly.



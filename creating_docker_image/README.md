# Image loaded in docker
## How to build
1. Open a console/terminal, clone this repo and move to dcml_corpus_workflow/creating_docker_image/ folder
2. Create a docker hub account in https://hub.docker.com/ and a new public repository
3. Install docker desktop according to your machine. [Windows](https://docs.docker.com/desktop/install/windows-install/), [Linux](https://docs.docker.com/desktop/install/linux-install/), [Mac](https://docs.docker.com/desktop/install/mac-install/)
4. Start , sign in docker destop and check in a console/terminal if it installed correctly with the command: `docker ps`
5. In a console/terminal pointing to dcml_corpus_workflow/creating_docker_image/ `run: docker build -t <hub-user>/<repo-name>:<tag> .` (notice the point at the end). 
6. Test your image running the command `docker run -ti <hub-user>/<repo-name>:<tag> sh`
7. Push to your repo by using command `docker push <hub-user>/<repo-name>:<tag>`

# Container image that runs your code
# FROM marcelmoran/dockerms3:customdocker
FROM marcelmoran/dockerms3:latest
# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

RUN apt-get -y update
RUN apt-get -y install git
# RUN --mount=type=secret,id=API_ENDPOINT
RUN chmod +x entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

# syntax=docker/dockerfile:1
FROM python:3.10-slim-bullseye
RUN apt-get -y update
RUN apt-get -y install git
RUN pip install git+https://github.com/johentsch/ms3.git@corpus_structure

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

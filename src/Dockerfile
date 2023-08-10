FROM python:3.10-slim-bullseye
RUN apt-get -y update
RUN apt-get -y install git
RUN apt-get install -y jq

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
RUN ipython kernel install --name "corpus_docs" --user


# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
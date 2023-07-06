FROM dcmlepfl/dcml_corpus_workflow:v2.7.2-ms3-1.2.10.post0.dev5-g054927a-dimcat-0.3.0
RUN apt-get -y update
RUN apt-get -y install git
RUN pip install git+https://github.com/johentsch/ms3.git@corpus_structure

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

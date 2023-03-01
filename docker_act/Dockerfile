FROM dcmlepfl/dcml_corpus_workflow:v2.6.3-ms3-1.2.4.post0.dev3-g5df6c9f-dimcat-0.3.0-data_reports-b5e79d0
RUN apt-get -y update
RUN apt-get -y install git
RUN pip install git+https://github.com/johentsch/ms3.git@corpus_structure

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]

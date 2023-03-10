FROM python:3.10-slim-bullseye
RUN apt-get -y update
RUN apt-get -y install git


RUN pip install git+https://github.com/johentsch/ms3.git@corpus_structure
RUN pip install jupyter

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
COPY dimcat /dimcat
RUN cd dimcat && git checkout notebooks && \
    pip install -e .

RUN ipython kernel install --name "dimcat" --user

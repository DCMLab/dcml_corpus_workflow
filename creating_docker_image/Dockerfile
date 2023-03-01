FROM python:3.10-slim-bullseye
RUN apt-get -y update
RUN apt-get -y install git


RUN pip install git+https://github.com/johentsch/ms3.git@corpus_structure
RUN pip install jupyter

COPY data_reports /data_reports
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

RUN ipython kernel install --name "dimcat" --user

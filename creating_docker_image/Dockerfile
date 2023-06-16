FROM python:3.10-slim-bullseye
RUN apt-get -y update
RUN apt-get -y install git

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
RUN ipython kernel install --name "dimcat" --user

# syntax=docker/dockerfile:1
# Container image parent
FROM python:3.10-slim-bullseye
RUN apt-get -y update
RUN apt-get -y install git
COPY requirements.txt ./

#Installing libraries
RUN pip install --no-cache-dir -r requirements.txt

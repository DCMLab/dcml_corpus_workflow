# syntax=docker/dockerfile:1
# Container image parent
FROM python:3.10-slim-bullseye
RUN apt-get -y update
RUN apt-get -y install git

#Creating environments
RUN python3 -m venv /opt/new
RUN python3 -m venv /opt/old

#installing corresponding version
RUN opt/new/bin/pip install ms3
RUN opt/old/bin/pip install ms3==0.4.11

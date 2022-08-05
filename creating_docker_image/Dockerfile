# syntax=docker/dockerfile:1
# Container image parent
FROM python:3.10-slim-bullseye

COPY requirements.txt ./

#Installing libraries
RUN pip install --no-cache-dir -r requirements.txt

#!/bin/bash
# Building Docker Image
docker build -t $DOCKER_REG/backend:latest .
# Pushing Image
docker push $DOCKER_REG/backend:latest
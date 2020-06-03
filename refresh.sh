#!/bin/bash
git pull
docker stack rm stack_backend
bash build.sh backend
bash deploy.sh backend


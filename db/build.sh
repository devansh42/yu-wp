#!/usr/bin/sh
docker build -t $DOCKER_REG/yu_wp_db:latest .
docker push $DOCKER_REG/yu_wp_db:latest

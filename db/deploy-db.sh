#!/usr/bin/bash
file="./docker-compose-db.yml"
#Compiling this file
sed "s/\$DOCKER_REG/$DOCKER_REG/" $file >$file

sed "s/\$DO_SECRET_KEY/$DO_SECRET_KEY/" env.env |
    sed "s/\$DO_ACCESS_KEY/$DO_ACCESS_KEY/" |
    sed "s/\$DO_BUCKET/$DO_BUCKET/" |
    sed "s/\$DO_BUCKET_NAME/$DO_BUCKET_NAME/"
>env.env

#Deploying to swarm
docker-compose -f $file up

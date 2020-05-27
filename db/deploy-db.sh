#!/bin/bash
file="docker-compose-db.yml"
cp $file .docker-compose-db.yml
#Compiling this file
sed "s/\$DOCKER_REG/$DOCKER_REG/" $file >/tmp/db_yml
cp /tmp/db_yml $file
t=/tmp/env_file
e=env.env
cp $e .env
sed "s/\$DO_SECRET_KEY/$DO_SECRET_KEY/" $e >$t
cp $t $e

sed "s/\$DO_ACCESS_KEY/$DO_ACCESS_KEY/" $e >$t
cp $t $e
sed "s/\$DO_BUCKET_NAME/$DO_BUCKET_NAME/" $e >$t
cp $t $e
sed "s/\$DO_BUCKET_HOST/$DO_BUCKET_HOST/" $e >$t
cp $t $e
sed "s/\$DO_BUCKET/$DO_BUCKET/" $e >$t
cp $t $e
#Deploying to swarm
docker stack up -c $file stack_db
#Cleanup
cp .env $e
cp .docker-compose-db.yml $file

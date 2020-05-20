#!/usr/bin/bash

#This script deploys the wordpress container on the given nodeid
#e.g. deploy.sh /var/wp/deploy/:orderid :plan
#plan is plan taken by user beg or adv

oid=$(basename $1)
currentdir=$(pwd)
cp $(pwd) $1/
cd $1 #Switching to newly copied folder
NODEID=$(awk -F "=" '$1 ~ /NODEID/{print $2}')
sed "s/\$nid/$NODEID/" docker-compose-sample.yml |
    sed "s/\$oid/$oid/" |
    sed "s/\$plan/$plan/"
>docker-compose.yml

# Deploying as a docker service
docker stack up -c docker-compose.yml
cd $currentdir
rm -rf $1 #Deleting

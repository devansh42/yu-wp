#!/bin/bash
# This script is triggered by worker script and grab info
# Usage, docker.sh :oid :plan :name :domains
cid=$(docker ps -q -f "label=oid=$1")
port=$(docker port $cid | awk -F : '{print $2}')
bindip=$(ip route get 8.8.8.8| awk 'NR==1{print $3}') #Getting default gateway ip addr
# Adding request for new site initialization
echo "$3;$bindip:$port;$4" >/var/wp/new/site$1
# Adding for backup if required
if [ $2 == "adv" ]; then
    echo $1 >>/var/wp/backup-sites

fi

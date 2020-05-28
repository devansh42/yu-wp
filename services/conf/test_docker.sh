#!/bin/bash

# This script tests docker.sh script

cleanup() {
    cat /var/wp/new/site$1
    rm /var/wp/new/site$1

}

oid=123456
# Launching a mock container
docker run -d -l "oid=$oid" --name demo_container -p 8000:8000 alpine sleep 1d
if [ ! -e /var/wp/new ]; then mkdir -p /var/wp/new; fi
# Test for Beginners package
bash docker.sh $oid beg domain.tld domain.tld "domain.tld www.domain.tld"
echo "Content of site$oid file"
cleanup

#Test for advance package
cp /var/wp/backup-sites /tmp/backupsites
bash docker.sh $oid adv domain.tld domain.tld "domain.tld www.domain.tld"
echo "Content of site$oid file"
cleanup
cp /tmp/backupsites /var/wp/backup-sites

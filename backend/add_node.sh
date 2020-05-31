#!/bin/bash
# Adding a new node to cluster
read -p 'Enter Node id ' nid
read -p 'Enter Hostname ' hostname
read -p 'Enter domain' domain
echo "$nid $hostname $domain" >>$NODEFILE
echo "Record Added Sucessfully!!"
cat $NODEFILE
#!/bin/bash
# Adding a new node to cluster
read -p "Enter Node id\t" nid
read -p "Enter Hostname\t" hostname
read -p "Enter domain\t" domain
echo "$nid $hostname $domain" >>$NODESFILE
echo "Record Added Sucessfully!!"
cat $NODESFILE

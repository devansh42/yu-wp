#!/bin/bash
# This script test ssl certificate generation

#Importing the script
source ssl.sh

ssldir=/tmp/newssl

mkdir -p $ssldir
cat >$ssldir/issue123 <<EOF
domain.tld
www.domain.tld
EOF

export TESTING=1

process_request_file $ssldir

#Let's read the logs
cat /var/log/wp/ssl/issue123
 
#Cleaning up 
rm -rf $ssldir /var/log/wp/ssl/issue123
unset TESTING


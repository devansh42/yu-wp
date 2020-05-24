#!/usr/bin/bash
# This script issues certiciates
# Below Script will consume /var/wp/ssl directory for certificate issuance

# issue , takes 2 argument
# Argument 1 - String containing domains i.e. String -d domain1 -d domain2
# Argument 2 - Filepath to be consumed
issue() {
    base=$(basename $2)
    certbot --nginx $1 >/var/log/wp/ssl/$base 2>&1
    rm $2
}

while [ true ]; do
    while [ $(ls /var/wp/ssl | wc -l) -eq 0 ];do sleep 5; done #Sleep if have no orders

    files=/var/wp/ssl/issue* # Files for certificate requests
    for file in $files; do
        domains=`awk 'BEGIN {i=0} $0 ~ /\w+/ {i++;ar[i]=$0} END {for (x in ar){printf " -d %s",ar[x]}}' $file`
        issue $domains $file
    done
done

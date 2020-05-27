#!/bin/bash
# This script issues certiciates
# Ideally Script will consume /var/wp/ssl directory for certificate issuance
# Below script consumes $1 script

# issue , takes 2 argument
# Argument 1 - String containing domains i.e. String -d domain1 -d domain2
# Argument 2 - Filepath to be consumed
issue() {
    base=$(basename $2)
    certbot $( if [ -z "$TESTING" ];then echo "--staging";fi )  --agree-tos -n -m devanshguptamrt@gmail.com --nginx $1 >/var/log/wp/ssl/$base 2>&1
    rm $2
}

process_request_file() {
    files=$1/issue* # Files for certificate requests
    for file in $files; do
        domains=$(awk 'BEGIN {i=0} $0 ~ /\w+/ {i++;ar[i]=$0} END {for (x in ar){printf " -d %s",ar[x]}}' $file)
        issue "$domains" $file
    done

}

main() {
    while [ true ]; do
        while [ $(ls $1/issue* | wc -l) -eq 0 ]; do sleep 5; done #Sleep if have no orders
        process_request_file $1
    done
}

case $1 in
"main")
    main $2
    ;;
esac

#!/bin/bash
# This script backups site data
# This script needs to situated in wp docker container

# Uasge, backup /var/www/html/site-folder www.mysite.com
#This scripts consume a file at $1 to read sites to backup
backup() {
    $c=$(pwd)
    cd /tmp
    tar -czf backup.tar.gz $1
    s3cmd --host=$DO_BUCKET_HOST --host-bucket=$DO_BUCKET --access_key=$DO_ACCESS_KEY --secret_key=$DO_SECRET_KEY backup.tar.gz s3://$DO_BUCKET_NAME/backup/wp/$2/backup-$(echo $(date +%d) % 5 | bc).tar.gz
    rm backup.tar.gz
    cd $c
}

while IFS= read -r line; do
    backup /var/www/$line/html $line
done <$1

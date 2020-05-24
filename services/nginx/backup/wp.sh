#!/usr/bin/bash
# This script backups site data
# This script needs to situated in wp docker container

alias s3md="s3cmd --host-bucket=$DO_BUCKET --access_key=$DO_ACCESS_KEY --secret_key=$DO_SECRET_KEY "

# Uasge, backup /var/www/html www.mysite.com
backup () {
    $c=$(pwd)
    cd /tmp
    tar -czf backup.tar.gz $1
    s3md backup.tar.gz s3://$DO_BUCKET_NAME/backup/wp/$2/backup-$(echo $(date +%d) % 5 | bc).tar.gz
    rm backup.tar.gz
    cd $c
}

while IFS= read -r line;do
backup /var/wp/html/$line $line
done < /var/wp/backup-sites
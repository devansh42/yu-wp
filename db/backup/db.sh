#!/bin/bash

#This script is for taking mysql's backup
#This file consumes /var/wp/db/names which have the database name
#Uploading files to do bucket
#Format of uploaded file will be databasename-dump-[0-4].tar.gz

#Dumping files
while IFS= read -r db_name; do
    if [ -z $db_name ]; then #Empty string
        continue
    fi

    mysqldump -u root -p$MYSQL_ROOT_PASSWORD --databases $db_name >dump.sql
    tar -czf $db_name-dump-$(echo $(date +%d) % 5 | bc).tar.gz dump.sql
done <$1

#Uploading backups
s3cmd --host=$DO_BUCKET_HOST --host-bucket=$DO_BUCKET --access_key=$DO_ACCESS_KEY --secret_key=$DO_SECRET_KEY \
    put *.tar.gz s3://$DO_BUCKET_NAME/backup/db/

#Deleting dump on local database for saving space
rm *.tar.gz dump.sql

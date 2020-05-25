#!/usr/bin/bash

echo "Waiting for mysqld to start"
sleep 30s
#Creating necessary database
mysql -u root -p$MYSQL_ROOT_PASSWORD <db.sql

if ! [ -e /var/wp/db/name ]; then #If backup name file doesn't exists
    echo "yu_wp_data" >/var/wp/db/name
fi

#Registering cron job for
if ! [ -e /etc/db-backup ]; then
    bash /backup/cron-db.sh
fi

#Making password file for backup purposes
if ! [ -e $PASSWD_FILE ]; then
    cat >$PASSWD_FILE <<EOF
[client]
password=$MYSQL_ROOT_PASSWORD
EOF

fi

#!/bin/bash


if ! [ -e /var/wp/db/names ]; then #If backup name file doesn't exists
    echo "yu_wp_data" >/var/wp/db/names
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



bash docker-entrypoint.sh mysqld # Executing the default entrypoint

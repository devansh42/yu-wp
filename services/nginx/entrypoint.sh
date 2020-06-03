#!/bin/bash


touch $BACKUP_SITE_FILE 
echo "Registering Backup Cron Job"
# Registering backup cron job
bash backup/cron-wp.sh

nginx -g "daemon off;" & # Starting up nginx
#echo "Started nginx"
# Running Worker 
if [ -e "/etc/nginx/sites-available" ];then
else
mkdir /etc/nginx/sites-available
fi

/worker/worker > /var/log/wp/log.log 2>&1

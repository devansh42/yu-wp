#!/bin/bash


touch $BACKUP_SITE_FILE 
echo "Registering Backup Cron Job"
# Registering backup cron job
bash backup/cron-wp.sh

nginx -g "daemon off;" >/var/log/nginx/nginx.log 2>&1  & # Starting up nginx
#echo "Started nginx"
# Running Worker 

/worker/worker > /var/log/wp/log.log 2>&1

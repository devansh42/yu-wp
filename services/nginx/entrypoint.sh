#!/bin/bash


touch $BACKUP_SITE_FILE 
echo "Registering Backup Cron Job"
# Registering backup cron job
bash backup/cron-wp.sh

nginx -g "daemon off;" # Starting up nginx
echo "Started nginx"
# Running Worker 
/worker/worker

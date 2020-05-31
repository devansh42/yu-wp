#!/bin/bash

#Making folder certificate requests
mkdir -p /var/wp/html /var/log/wp/site /var/log/wp/ssl
touch $BACKUP_SITE_FILE 
echo "Registering Backup Cron Job"
# Registering backup cron job
bash backup/cron-wp.sh

nginx -g "daemon off;" # Starting up nginx
echo "Started nginx"
# Worker Python Script
python worker.py
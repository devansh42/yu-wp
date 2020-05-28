#!/bin/bash
# This file adds content to the cron scheduler
cp /nginx/backup/wp.sh /etc/wp-backup
crontab -l > cron_dump
# Running cron job daily at 2 am
echo "0 2 * * * /bin/bash /etc/wp-backup /var/wp/backup-sites" >> cron_dump
crontab cron_dump
rm cron_dump

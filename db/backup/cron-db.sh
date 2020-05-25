#!/bin/bash
#This file adds content to the cron scheduler
set -x
cp /backup/db.sh /etc/db-backup

crontab -l && crontab -l > cron_dump
	

#Running cron job daily at 2 am
echo "0 2 * * * bash /etc/db-backup /var/wp/db/names" >> cron_dump
crontab cron_dump
rm cron_dump

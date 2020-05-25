#!/bin/bash
# This file adds content to the cron scheduler
cp wp.sh /etc/wp-backup
crontab -l > cron_dump
# Running cron job daily at 2 am
echo "0 2 * * * /etc/wp-backup" >> cron_dump
crontab cron_dump
rm cron_dump
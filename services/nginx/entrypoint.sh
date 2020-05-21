#!/usr/bin/bash

#Making folder certificate requests
mkdir -p  /var/wp/new   /var/wp/ssl /var/log/wp/ssl /etc/nginx/sites-available

# Registering backup cron job
./backup/cron-wp.sh

# Running ssl job in bg
./ssl/ssl.sh &

# Running server job in bg
./server/conf.sh &


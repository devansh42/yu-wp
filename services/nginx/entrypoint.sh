#!/bin/bash

#Making folder certificate requests
mkdir -p /var/wp/new /var/wp/ssl /var/log/wp/ssl /etc/nginx/sites-available

echo "Registering Backup Cron Job"
# Registering backup cron job
bash backup/cron-wp.sh

function setup_ssl() {
    exe=/var/wp/ssl/exe
    ln -s $(realpath ssl/ssl.sh) $exe
    chmod +x $exe ssl/service_ssl
    ln -s $(realpath ssl/service_ssl) /etc/init.d/service_ssl
    
    #/etc/init.d/service_ssl start # Starting the bg daemon
    rc-update add service_ssl default
	rc-service service_ssl start		
}

function setup_conf() {
    exe=/var/wp/new/exe
    ln -s $(realpath server/conf.sh) $exe
    chmod +x $exe server/service_conf
    ln -s $(realpath server/service_conf) /etc/init.d/service_conf
    ln -s $(realpath server/nginx.conf) /var/wp/new/nginx.conf # Copying sample config file
    #/etc/init.d/service_conf start # Starting the bg daemon

    rc-update add service_conf default
	rc-service service_conf start
}

# setup_conf # Setting up Daemon
# setup_ssl # Setting up Daemon
nginx -g "daemon off;" # Starting up nginx
echo "Started nginx"

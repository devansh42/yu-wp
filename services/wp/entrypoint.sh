#!/bin/bash
mkdir -p /var/www/$OID/html
chown -R www-data:www-data /var/www/$OID
cd /var/www/$OID/html
docker-entrypoint.sh php-fpm # Docker entrypoint 
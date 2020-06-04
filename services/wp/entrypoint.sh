#!/bin/bash
mkdir -p /var/www/$OID/html 
cd /var/www/$OID/html
docker-entrypoint.sh php-fpm # Docker entrypoint 
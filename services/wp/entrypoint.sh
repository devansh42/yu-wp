#!/bin/bash
ln -s /var/www/html /wp/link/$OID 
cd /var/www/html
docker-entrypoint.sh php-fpm # Docker entrypoint 
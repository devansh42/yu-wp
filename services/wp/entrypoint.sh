#!/bin/bash
ln -s /var/www/html /wp/link/$OID
docker-entrypoint.sh php-fpm # Docker entrypoint 
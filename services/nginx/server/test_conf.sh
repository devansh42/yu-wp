#!/bin/bash

# This tests ngixn configuration generator
source conf.sh
mkdir -p /tmp/newsites
cp nginx.conf /tmp/newsites/nginx.conf
cat >/tmp/newsites/site123 <<EOF
domain.tld; 127.0.0.1:9899; domain.tld www.domain.tld
EOF

# from conf.sh
process_file /tmp/newsites
reload_nginx
# Cleanup
name=domain.tld
rm /etc/nginx/sites-available/$name
rm /etc/nginx/conf.d/$name
rm -rf /tmp/newsites

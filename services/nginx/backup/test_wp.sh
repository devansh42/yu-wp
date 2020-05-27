#!/bin/bash

# This test wp backup service
mkdir -p /var/wp/html/domain.tld
echo "Some non sense data" >/var/wp/html/domain.tld/test
echo "domail.tld" >/tmp/domains
bash wp.sh /tmp/domains
rm -rf /var/wp/html/domain.tld /tmp/domains

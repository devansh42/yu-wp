#!/bin/bash

#This scripts makes default wp-config.php file
filename="wp-config-sample.php"

echo $(date) >sum
arr=(demo demo)
for x in $(seq 0 7); do
    arr[$x]=$(md5sum sum | awk '{print $1}')
    echo ${arr[$x]} >sum
done
rm sum
sed "s/database_name_here/$DB_NAME/" $filename |
    sed "s/username_here/$DB_USER/" |
    sed "s/password_here/$DB_PASSWD/" |
    sed "s/localhost/$DB_HOST/" >wp-config.php

awk -f token_replacer.awk wp-config.php >demofile
for x in $(seq 0 7); do
    sed "s/token_$x/${arr[$x]}/" demofile >wp-config.php
    cp wp-config.php demofile
done

rm demofile

# Making link for backup purpose
ln -s /var/www/html /wp/link/$OID

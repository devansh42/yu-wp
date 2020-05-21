#!/usr/bin/bash
# Following bash script generates configuration file
# Dir: /var/wp/new
# File: /var/wp/new/site*
# File content format
# domain.tld;   127.0.0.1:9899; domain1.tld domain2.tld



while [ true ]; do
    while [ $(ls /var/wp/new/site* | wc -l) -eq 0 ]; do sleep 5; done #While we don't have any request to process take napes
    files="/var/wp/new/site*"
    for file in "$files"; do
        name=$(awk -F ";" '{print $1}' $file)
        sed "s/\$bind_addr/$(awk -F ";" '{print $2}' $file)/" nginx.conf |
            sed "s/\$server_names/$(awk -F ";" '{print $3}' $file)/" >/etc/nginx/sites-available/$name
        ln -s /etc/nginx/conf.d/$name /etc/nginx/sites-available/$name
    done
    #Lets update nginx about following changes
    nginx -s reload
done

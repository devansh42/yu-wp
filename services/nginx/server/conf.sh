#!/usr/bin/bash
# Following bash script generates configuration file
# Ideally this consumes Dir: /var/wp/new
# Ideally this consumes Files: /var/wp/new/site*
# This consumes $1 dir and $1/site* files
# File content format
# domain.tld;   127.0.0.1:9899; domain1.tld domain2.tld

# Expects $1 the directory to look in
process_file() {
    files="$1/site*"

    for file in "$files"; do
        name=$(awk -F ";" '{print $1}' $file)
        sed "s/\$bind_addr/$(awk -F ";" '{print $2}' $file)/" $1/nginx.conf |
            sed "s/\$server_names/$(awk -F ";" '{print $3}' $file)/" >/etc/nginx/sites-available/$name
        ln -s  /etc/nginx/sites-available/$name /etc/nginx/conf.d/$name
    done

}

reload_nginx() {
    nginx -s reload
}

# Expects $1 the directory to look in
main() {

    while [ true ]; do
        while [ $(ls $1/site* | wc -l) -eq 0 ]; do sleep 5; done #While we don't have any request to process take napes
        # Lets update nginx about following changes
        process_file $1
        reload_nginx
    done
}

# Creating an entry point
# If script is called with 0 argument it is
case $1 in
"main")
    main $2
    ;;

esac

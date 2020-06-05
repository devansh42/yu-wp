#!/bin/bash

OID=

askoid() {
    read -p "Enter OID " OID
}

file() {

    cat >/tmp/data.json <<EOF
{
    "id":"$OID",
    "line_items":[
        {
            "id":"1",
            "meta_data":[
                {
                    "key":"domain",
                    "value":"bsnl.online"
                },
                {
                    "key":"domains",
                    "value":"api.bsnl.online www.bsnl.online bsnl.online"
                }
            ]
        }
    ]
}
EOF
}

case $1 in
"o")
    askoid
    file
    curl -v -d @"/tmp/data.json" -H "Content-Type:application/json" http://localhost/orders/new
    ;;
"s")
    askoid
    curl -v http://localhost/req/ssl?id=$OID
    ;;
"csite")
    askoid
    curl -v http://localhost/check/site?id=$OID
    ;;
"cssl")
    askoid
    curl -v http://localhost/check/ssl?id=$OID
    ;;
*)
    echo "Not a valid option, try 'o' and 's' "
    ;;

esac

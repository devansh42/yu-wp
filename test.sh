#!/bin/bash
cat > data.json <<EOF
{
    "id":786,
    "line_items":[
        {
            "id":1,
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


curl -X POST -d @data.json http://localhost/orders/new
#!/bin/bash
bash file.sh
curl -v -d @"/tmp/data.json" -H "Content-Type:application/json" http://localhost/orders/new

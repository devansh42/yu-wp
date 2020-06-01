#!/bin/bash
cat > data.txt <<EOF
id=786&
EOF
curl -X POST    http://localhost/orders/new
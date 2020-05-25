#!/bin/bash
# This scripts test the auto db backup service

function init() {
    mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
    create database if not exists test_demo_db;
    create table if not exists test_demo_db.test_table(si int);
EOF
}
function cleanup() {
    mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF

    drop database if exists test_demo_db;
EOF
}

init
echo "test_demo_db" >/var/wp/db/test_names
bash db.sh /var/wp/db/test_names
cleanup
